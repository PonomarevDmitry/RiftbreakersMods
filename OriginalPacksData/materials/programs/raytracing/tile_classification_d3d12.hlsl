/**********************************************************************
Copyright (c) 2019 Advanced Micro Devices, Inc. All rights reserved.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
********************************************************************/

#include "denoiser_utils_d3d12.hlsl"

groupshared int g_false_count;
bool ThreadGroupAllTrue(bool val)
{
    const uint lane_count_in_thread_group = 64;
    if (WaveGetLaneCount() == lane_count_in_thread_group)
    {
        return WaveActiveAllTrue(val);
    }
    else
    {
        GroupMemoryBarrierWithGroupSync();
        g_false_count = 0;
        GroupMemoryBarrierWithGroupSync();
        if (!val) g_false_count++;
        GroupMemoryBarrierWithGroupSync();
        return g_false_count == 0;
    }
}

cbuffer PassData : register(b0)
{
    float4x4    ProjectionInverse;
#if DISOCCLUSION
    float4x4    ReprojectionMatrix;
    float4x4    ViewProjectionInverse;
    float3      Eye;
#endif
    int2        BufferDimensions;
    int         FrameIndex;
}

Texture2D<float>            DepthBuffer;
Texture2D<float2>           VelocityBuffer;
#if DISOCCLUSION
Texture2D<float3>           NormalBuffer;
#endif
Texture2D<float>            HistoryBuffer;
Texture2D<float3>           PreviousMomentsBuffer;
#if DISOCCLUSION
Texture2D<float>            PreviousDepthBuffer;
#endif
StructuredBuffer<uint>      RaytracerResult;

RWTexture2D<float3>         MomentsBuffer               : register(u0); // Result of the reprojection
RWTexture2D<float2>         ReprojectionResults         : register(u1); // Same target that the reprojection pass writes into
RWStructuredBuffer<uint>    TileMetaData                : register(u2);

SamplerState HistorySampler : register(s0);

uint GetRaytracerResult( uint index )
{
    return RaytracerResult[ clamp( index,  uint( 0 ), uint( ( BufferDimensions.x * BufferDimensions.y ) - 1 ) ) ];
}

void SearchSpatialRegion(uint2 gid, out bool all_in_light, out bool all_in_shadow)
{
    // The spatial passes can reach a total region of 1+2+4 = 7x7 around each block.
    // The masks are 8x4, so we need a larger vertical stride

    // Visualization - each x represents a 4x4 block, xx is one entire 8x4 mask as read from the raytracer result
    // Same for yy, these are the ones we are working on right now

    // xx xx xx
    // xx xx xx
    // xx yy xx <-- yy here is the base_tile below
    // xx yy xx
    // xx xx xx
    // xx xx xx

    // All of this should result in scalar ops
    uint2 base_tile = GetTileIndexFromPixelPosition(gid * int2(8, 8));

    // Load the entire region of masks in a scalar fashion
    uint combined_or_mask = 0;
    uint combined_and_mask = 0xFFFFFFFF;
    for (int j = -2; j <= 3; ++j)
    {
        for (int i = -1; i <= 1; ++i)
        {
            int2 tile_index = base_tile + int2(i, j);
            tile_index = clamp(tile_index, 0, int2(RoundedDivide(uint(BufferDimensions.x), 8), RoundedDivide(uint(BufferDimensions.y), 4)) - 1);
            const uint linear_tile_index = LinearTileIndex(tile_index, uint(BufferDimensions.x));
            const uint shadow_mask = GetRaytracerResult(linear_tile_index);

            combined_or_mask = combined_or_mask | shadow_mask;
            combined_and_mask = combined_and_mask & shadow_mask;
        }
    }

    all_in_light = combined_and_mask == 0xFFFFFFFFu;
    all_in_shadow = combined_or_mask == 0u;
}

float GetLinearDepth(in uint2 did, in float depth)
{
    const float2 uv = (did + 0.5f) * (1.0f / float2(BufferDimensions.xy));
    const float2 ndc = 2.0f * float2(uv.x, 1.0f - uv.y) - 1.0f;

    float4 projected = mul(ProjectionInverse, float4(ndc, depth, 1));
    return abs(projected.z / projected.w);
}

#if DISOCCLUSION
bool IsDisoccluded(uint2 did, float depth, float2 velocity)
{
    const int2 dims = BufferDimensions.xy;
    const float2 texel_size = 1.0f / float2(dims.xy);
    const float2 uv = (did + 0.5f) * texel_size;
    const float2 ndc = (2.0f * uv - 1.0f) * float2(1.0f, -1.0f);
    const float2 previous_uv = uv - velocity;

    bool is_disoccluded = true;
    if (all(previous_uv > 0.0) && all(previous_uv < 1.0))
    {
        // Read the center values
        float3 normal = NormalBuffer.Load(int3(did, 0)).xyz;
        normal = normalize(2.0f * normal - 1.0f);   // recover world-space normal

        float4 clip_space = mul(ReprojectionMatrix, float4(ndc, depth, 1.0f));
        clip_space /= clip_space.w; // perspective divide

        // How aligned with the view vector? (the more Z aligned, the higher the depth errors)
        const float4 homogeneous = mul(ViewProjectionInverse, float4(ndc, depth, 1.0f));
        const float3 world_position = homogeneous.xyz / homogeneous.w;  // perspective divide
        const float3 view_direction = normalize(Eye.xyz - world_position);
        float z_alignment = 1.0f - dot(view_direction, normal);
        z_alignment = pow(z_alignment, 8);

        // Calculate the depth difference
        float linear_depth = GetLinearDepth(did, clip_space.z);   // get linear depth

        int2 idx = previous_uv * dims;
        const float previous_depth = GetLinearDepth(idx, PreviousDepthBuffer.Load(int3(idx, 0)).x);
        const float depth_difference = abs(previous_depth - linear_depth) / linear_depth;

        // Resolve into the disocclusion mask
        const float depth_tolerance = lerp(1e-2f, 1e-1f, z_alignment);
        is_disoccluded = depth_difference >= depth_tolerance;
    }

    return is_disoccluded;
}
#endif

float2 GetClosestVelocity(int2 did, float depth)
{
    float2 closest_velocity = VelocityBuffer.Load(int3(did, 0));
    float closest_depth = depth;

    float new_depth = QuadReadAcrossX(closest_depth);
    float2 new_velocity = QuadReadAcrossX(closest_velocity);
#ifdef INVERTED_DEPTH_RANGE
    if (new_depth > closest_depth)
#else
    if (new_depth < closest_depth)
#endif
    {
        closest_depth = new_depth;
        closest_velocity = new_velocity;
    }

    new_depth = QuadReadAcrossY(closest_depth);
    new_velocity = QuadReadAcrossY(closest_velocity);
#ifdef INVERTED_DEPTH_RANGE
    if (new_depth > closest_depth)
#else
    if (new_depth < closest_depth)
#endif
    {
        closest_depth = new_depth;
        closest_velocity = new_velocity;
    }

    return closest_velocity * float2(0.5f, -0.5f);  // from ndc to uv
}

float SampleHistory(float2 pos, float2 uv, float2 texel_size)
{
    return HistoryBuffer.SampleLevel(HistorySampler, uv, 0.0f);
}

#define KERNEL_RADIUS 8
float KernelWeight(float i)
{
#define KERNEL_WEIGHT(i) (exp(-3.0 * float(i * i) / ((KERNEL_RADIUS + 1.0) * (KERNEL_RADIUS + 1.0))))

    // Statically initialize kernel_weights_sum
    float kernel_weights_sum = 0;
    kernel_weights_sum += KERNEL_WEIGHT(0);
    for (int c = 1; c <= KERNEL_RADIUS; ++c)
    {
        kernel_weights_sum += 2 * KERNEL_WEIGHT(c); // Add other half of the kernel to the sum
    }
    float inv_kernel_weights_sum = rcp(kernel_weights_sum);

    // The only runtime code in this function
    return KERNEL_WEIGHT(i) * inv_kernel_weights_sum;
}

void AccumulateMoments(float value, float weight, inout float moments)
{
    // We get value from the horizontal neighborhood calculations. Thus, it's both mean and variance due to using one sample per pixel
    moments += value * weight;
}

// The horizontal part of a 17x17 local neighborhood kernel
float HorizontalNeighborhood(int2 did)
{
    const int2 base_did = WaveReadLaneFirst(did);
    // Prevent vertical out of bounds access
    if ((base_did.y < 0) || (base_did.y >= BufferDimensions.y)) return 0;

    const uint2 tile_index = GetTileIndexFromPixelPosition(base_did);
    const uint linear_tile_index = LinearTileIndex(tile_index, uint(BufferDimensions.x));

    const int left_tile_index = int(linear_tile_index) - 1;
    const int center_tile_index = int(linear_tile_index);
    const int right_tile_index = int(linear_tile_index) + 1;

    bool is_first_tile_in_row = (tile_index.x == 0);
    bool is_last_tile_in_row = (tile_index.x == (RoundedDivide(uint(BufferDimensions.x), 8) - 1));

    uint left_tile = 0;
    if(!is_first_tile_in_row) left_tile  = GetRaytracerResult(left_tile_index);
    uint center_tile = GetRaytracerResult(center_tile_index);
    uint right_tile = 0;
    if(!is_last_tile_in_row) right_tile = GetRaytracerResult(right_tile_index);

    // Construct a single uint with the lowest 17bits containing the horizontal part of the local neighborhood.

    // First extract the 8 bits of our row in each of the neighboring tiles
    const uint row_base_index = (did.y % 4) * 8;
    const uint left = (left_tile >> row_base_index) & 0xFF;
    const uint center = (center_tile >> row_base_index) & 0xFF;
    const uint right = (right_tile >> row_base_index) & 0xFF;

    // Combine them into a single mask containting [left, center, right] from least significant to most significant bit
    uint neighborhood = left | (center << 8) | (right << 16);

    // Make sure our pixel is at bit position 9 to get the highest contribution from the filter kernel
    const uint bit_index_in_row = (did.x % 8);
    neighborhood = neighborhood >> bit_index_in_row; // Shift out bits to the right, so the center bit ends up at bit 9.

    float moment = 0.0; // For one sample per pixel this is both, mean and variance

    // First 8 bits up to the center pixel
    uint mask;
    int i;
    for (i = 0; i < 8; ++i)
    {
        mask = 1u << i;
        moment += (mask & neighborhood) ? KernelWeight(8 - i) : 0;
    }

    // Center pixel
    mask = 1u << 8;
    moment += (mask & neighborhood) ? KernelWeight(0) : 0;

    // Last 8 bits
    for (i = 1; i <= 8; ++i)
    {
        mask = 1u << (8 + i);
        moment += (mask & neighborhood) ? KernelWeight(i) : 0;
    }

    return moment;
}

groupshared float g_neighborhood[8][24];

float ComputeLocalNeighborhood(int2 did, int2 gtid)
{
    float local_neighborhood = 0;

    float upper = HorizontalNeighborhood(int2(did.x, did.y - 8));
    float center = HorizontalNeighborhood(int2(did.x, did.y));
    float lower = HorizontalNeighborhood(int2(did.x, did.y + 8));

    g_neighborhood[gtid.x][gtid.y] = upper;
    g_neighborhood[gtid.x][gtid.y + 8] = center;
    g_neighborhood[gtid.x][gtid.y + 16] = lower;

    GroupMemoryBarrierWithGroupSync();

    // First combine the own values.
    // KERNEL_RADIUS pixels up is own upper and KERNEL_RADIUS pixels down is own lower value
    AccumulateMoments(center, KernelWeight(0), local_neighborhood);
    AccumulateMoments(upper, KernelWeight(KERNEL_RADIUS), local_neighborhood);
    AccumulateMoments(lower, KernelWeight(KERNEL_RADIUS), local_neighborhood);

    // Then read the neighboring values.
    for (int i = 1; i < KERNEL_RADIUS; ++i)
    {
        float upper_value = g_neighborhood[gtid.x][8 + gtid.y - i];
        float lower_value = g_neighborhood[gtid.x][8 + gtid.y + i];
        float weight = KernelWeight(i);
        AccumulateMoments(upper_value, weight, local_neighborhood);
        AccumulateMoments(lower_value, weight, local_neighborhood);
    }

    return local_neighborhood;
}

void WriteTileMetaData(uint2 gid, uint2 gtid, bool is_cleared, bool all_in_light)
{
    if (all(gtid == 0))
    {
        uint light_mask = all_in_light ? TILE_META_DATA_LIGHT_MASK : 0;
        uint clear_mask = is_cleared ? TILE_META_DATA_CLEAR_MASK : 0;
        uint mask = light_mask | clear_mask;
        TileMetaData[gid.y * RoundedDivide(uint(BufferDimensions.x), 8) + gid.x] = mask;
    }
}

void ClearTargets(uint2 did, uint2 gtid, uint2 gid, float shadow_value, bool is_shadow_receiver, bool all_in_light)
{
    WriteTileMetaData(gid, gtid, true, all_in_light);
    ReprojectionResults[did] = float2(shadow_value, 0); // mean, variance

    float temporal_sample_count = is_shadow_receiver ? 1 : 0;
    MomentsBuffer[did] = float3(shadow_value, 0, temporal_sample_count); // mean, variance, temporal sample count
}

[numthreads(8, 8, 1)]
void main(uint group_index : SV_GroupIndex, uint2 gid : SV_GroupID)
{
    uint2 gtid = RemapLane8x8(group_index); // Make sure we can use the QuadReadAcross intrinsics to access a 2x2 region.
    uint2 did = gid * 8 + gtid;

    bool is_valid = all(did.xy < uint2(BufferDimensions.xy));
    if (!is_valid)
    {
        return;
    }

    float depth = DepthBuffer.Load(int3(did, 0));
    bool is_shadow_receiver = (depth > 0.0f) && (depth < 1.0f);

    bool skip_sky = ThreadGroupAllTrue(!is_shadow_receiver);
    if (skip_sky)
    {
        // We have to set all resources of the tile we skipped to sensible values as neighboring active denoiser tiles might want to read them.
        ClearTargets(did, gtid, gid, 0, is_shadow_receiver, false);
        return;
    }

    bool all_in_light = false;
    bool all_in_shadow = false;
    SearchSpatialRegion(gid, all_in_light, all_in_shadow);
    float shadow_value = all_in_light ? 1 : 0; // Either all_in_light or all_in_shadow must be true, otherwise we would not skip the tile.

    bool can_skip = all_in_light || all_in_shadow;
    // We have to append the entire tile if there is a single lane that we can't skip
    bool skip_tile = ThreadGroupAllTrue(can_skip);
    if (skip_tile)
    {
        // We have to set all resources of the tile we skipped to sensible values as neighboring active denoiser tiles might want to read them.
        ClearTargets(did, gtid, gid, shadow_value, is_shadow_receiver, all_in_light);
        return;
    }

    WriteTileMetaData(gid, gtid, false, false);

    const float2 velocity = GetClosestVelocity(did.xy, depth); // Must happen before we deactivate lanes
    const float local_neighborhood = ComputeLocalNeighborhood(did, gtid);

    const float2 texel_size = 1.0f / float2(BufferDimensions.xy);
    const float2 uv = (did.xy + 0.5f) * texel_size;
    const float2 history_uv = uv - velocity;
    const int2 history_pos = history_uv * BufferDimensions.xy;

    const uint2 tile_index = GetTileIndexFromPixelPosition(did);
    const uint linear_tile_index = LinearTileIndex(tile_index, uint(BufferDimensions.x));
    const uint shadow_tile = GetRaytracerResult(WaveReadLaneFirst(linear_tile_index));

    float3 moments_current = 0;
    float variance = 0;
    float shadow_clamped = 0;
    if (is_shadow_receiver) // do not process sky pixels
    {
        bool hit_light = shadow_tile & GetBitMaskFromPixelPosition(did);
        const float shadow_current = hit_light ? 1.0 : 0.0;

        // Perform moments and variance calculations
        {
#if DISOCCLUSION
            bool is_disoccluded = IsDisoccluded(did, depth, velocity);
            const float3 previous_moments = is_disoccluded ? float3(0.0f, 0.0f, 0.0f) // Can't trust previous moments on disocclusion
                : PreviousMomentsBuffer.Load(int3(history_pos, 0));
#else
            const float3 previous_moments = PreviousMomentsBuffer.Load(int3(history_pos, 0));
#endif
            const float old_m = previous_moments.x;
            const float old_s = previous_moments.y;
            const float sample_count = previous_moments.z + 1.0f;
            const float new_m = old_m + (shadow_current - old_m) / sample_count;
            const float new_s = old_s + (shadow_current - old_m) * (shadow_current - new_m);

            variance = (sample_count > 1.0f ? new_s / (sample_count - 1.0f) : 1.0f);
            moments_current = float3(new_m, new_s, sample_count);
        }

        // Retrieve local neighborhood and reproject
        {
            float mean = local_neighborhood;
            float spatial_variance = local_neighborhood;

            spatial_variance = max(spatial_variance - mean * mean, 0.0f);

            // Compute the clamping bounding box
            const float std_deviation = sqrt(spatial_variance);
            const float nmin = mean - 0.5f * std_deviation;
            const float nmax = mean + 0.5f * std_deviation;

            // Clamp reprojected sample to local neighborhood
            float shadow_previous = shadow_current;
            if (FrameIndex != 0)
            {
                shadow_previous = SampleHistory(history_pos, history_uv, texel_size);
            }

            shadow_clamped = clamp(shadow_previous, nmin, nmax);

            // Boost variance on first frames
            if (moments_current.z < 16.0f)
            {
                const float variance_boost = max(16.0f - moments_current.z, 1.0f);
                variance = max(variance, spatial_variance);
                variance *= variance_boost;
            }
        }

        // Perform the temporal blend
        const float history_weight = sqrt(max(8.0f - moments_current.z, 0.0f) / 8.0f);
        shadow_clamped = lerp(shadow_clamped, shadow_current, lerp(0.05f, 1.0f, history_weight));
    }

    // Output the results of the temporal pass
    ReprojectionResults[did.xy] = float2(shadow_clamped, variance);
    MomentsBuffer[did.xy] = moments_current;
}
