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

cbuffer PassData : register(b0)
{    
    int2     BufferDimensions;
    int      OutputChannel;
    float4x4 ProjectionInverse;
}

Texture2D DepthBuffer  : register(t0);
Texture2D NormalBuffer : register(t1);

#if PASS_INDEX == 0
Texture2D InputBuffer  : register(t2);
StructuredBuffer<uint>  TileMetaData : register(t3);

RWTexture2D<float> HistoryBuffer : register(u0);
RWTexture2D<float> IntermediateFilterResult : register(u1);

min16float2 ReadInput(int2 p)
{
    return (min16float2)InputBuffer.Load(int3(p, 0)).xy;
}

void StoreOutput(int2 p, float mean, float variance)
{
    HistoryBuffer[p] = mean;
    IntermediateFilterResult[p] = variance;
}
#endif


#if PASS_INDEX == 1
Texture2D HistoryBuffer             : register(t2);
Texture2D IntermediateFilterResult  : register(t3);
StructuredBuffer<uint> TileMetaData : register(t4);

RWTexture2D<float2> OutputBuffer : register(u0);

min16float2 ReadInput(int2 p)
{
    return min16float2(
        HistoryBuffer.Load(int3(p, 0)).x,
        IntermediateFilterResult.Load(int3(p, 0)).x
        );
}

void StoreOutput(int2 p, float mean, float variance)
{
    OutputBuffer[p] = float2(mean, variance);
}
#endif


#if PASS_INDEX == 2
Texture2D InputBuffer  : register(t2);
StructuredBuffer<uint> TileMetaData : register(t3);
RWTexture2D<float4>   OutputBuffer : register(u0);
//RWTexture2D<float>   PreviousDepthBuffer    : register(u1);

min16float2 ReadInput(int2 p)
{
    return (min16float2)InputBuffer.Load(int3(p, 0)).xy;
}

void StoreOutput(int2 p, float mean, float variance)
{
    // Recover some of the contrast lost during denoising
    const float shadow_remap = max(1.2f - mean * mean, 1.0f);
    mean = pow(abs(mean), shadow_remap);

    OutputBuffer[p][OutputChannel] = mean;
}
#endif

groupshared uint g_shared_input[16][16];
groupshared float g_shared_depth[16][16];
groupshared uint g_shared_normals_xy[16][16];
groupshared uint g_shared_normals_zw[16][16];

uint PackFloat16(min16float2 v)
{
    uint2 p = f32tof16(float2(v));
    return p.x | (p.y << 16);
}

min16float2 UnpackFloat16(uint a)
{
    float2 tmp = f16tof32(
        uint2(a & 0xFFFF, a >> 16));
    return min16float2(tmp);
}

min16float2 LoadInputFromGroupSharedMemory(int2 idx)
{
    return UnpackFloat16(g_shared_input[idx.y][idx.x]);
}

float LoadDepthFromGroupSharedMemory(int2 idx)
{
    return g_shared_depth[idx.y][idx.x];
}

min16float3 LoadNormalsFromGroupSharedMemory(int2 idx)
{
    min16float3 normals;
    normals.xy = UnpackFloat16(g_shared_normals_xy[idx.y][idx.x]);
    normals.z = UnpackFloat16(g_shared_normals_zw[idx.y][idx.x]).x;
    return normals;
}

void StoreInGroupSharedMemory(int2 idx, min16float3 normals, min16float2 input, float depth)
{
    g_shared_input[idx.y][idx.x] = PackFloat16(input);
    g_shared_depth[idx.y][idx.x] = depth;
    g_shared_normals_xy[idx.y][idx.x] = PackFloat16(normals.xy);
    g_shared_normals_zw[idx.y][idx.x] = PackFloat16(min16float2(normals.z, 0));
}

void LoadWithOffset(int2 did, int2 offset, out min16float3 normals, out min16float2 input, out float depth)
{
    did += offset;

    did = clamp(did, int2(0, 0), BufferDimensions.xy - 1);

    normals = (min16float3)NormalBuffer.Load(int3(did, 0)).xyz;
    input = ReadInput(did);
    depth = DepthBuffer.Load(int3(did, 0)).x;
}

void StoreWithOffset(int2 gtid, int2 offset, min16float3 normals, min16float2 input, float depth)
{
    gtid += offset;
    StoreInGroupSharedMemory(gtid, normals, input, depth);
}

void InitializeGroupSharedMemory(int2 did, int2 gtid)
{
    int2 offset_0 = 0;
    int2 offset_1 = int2(8, 0);
    int2 offset_2 = int2(0, 8);
    int2 offset_3 = int2(8, 8);

    min16float3 normals_0;
    min16float2 input_0;
    float depth_0;

    min16float3 normals_1;
    min16float2 input_1;
    float depth_1;

    min16float3 normals_2;
    min16float2 input_2;
    float depth_2;

    min16float3 normals_3;
    min16float2 input_3;
    float depth_3;

    /// XA
    /// BC

    did -= 4;
    LoadWithOffset(did, offset_0, normals_0, input_0, depth_0); // X
    LoadWithOffset(did, offset_1, normals_1, input_1, depth_1); // A
    LoadWithOffset(did, offset_2, normals_2, input_2, depth_2); // B
    LoadWithOffset(did, offset_3, normals_3, input_3, depth_3); // C

    normals_0 = normalize(2.0 * normals_0 - 1.0);
    normals_1 = normalize(2.0 * normals_1 - 1.0);
    normals_2 = normalize(2.0 * normals_2 - 1.0);
    normals_3 = normalize(2.0 * normals_3 - 1.0);

    StoreWithOffset(gtid, offset_0, normals_0, input_0, depth_0); // X
    StoreWithOffset(gtid, offset_1, normals_1, input_1, depth_1); // A
    StoreWithOffset(gtid, offset_2, normals_2, input_2, depth_2); // B
    StoreWithOffset(gtid, offset_3, normals_3, input_3, depth_3); // C
}

float GetShadowSimilarity(in float x1, in float x2, in float sigma)
{
    return exp(-abs(x1 - x2) / sigma);
}

float GetDepthSimilarity(in float x1, in float x2, in float sigma)
{
    return exp(-abs(x1 - x2) / sigma);
}

float GetNormalSimilarity(in float3 x1, in float3 x2)
{
    return pow(saturate(dot(x1, x2)), 32.0f);
}

float GetLinearDepth(in uint2 did, in float depth)
{
    const float2 uv = (did + 0.5f) * (1.0f / float2( BufferDimensions.xy ));
    const float2 ndc = 2.0f * float2(uv.x, 1.0f - uv.y) - 1.0f;

    float4 projected = mul(ProjectionInverse, float4(ndc, depth, 1));
    return abs(projected.z / projected.w);
}

float FetchFilteredVarianceFromGroupSharedMemory(in int2 pos)
{
    const int k = 1;
    float variance = 0.0f;
    const float kernel[2][2] =
    {
        { 1.0f / 4.0f, 1.0f / 8.0f  },
        { 1.0f / 8.0f, 1.0f / 16.0f }
    };
    for (int y = -k; y <= k; ++y)
    {
        for (int x = -k; x <= k; ++x)
        {
            const float w = kernel[abs(x)][abs(y)];
            variance += w * LoadInputFromGroupSharedMemory(pos + int2(x, y)).y;
        }
    }
    return variance;
}


void DenoiseFromGroupSharedMemory(uint2 did, uint2 gtid, inout float weight_sum, inout float2 shadow_sum, float depth)
{
    // Load our center sample
    const float2 shadow_center = LoadInputFromGroupSharedMemory(gtid);
    const float3 normal_center = LoadNormalsFromGroupSharedMemory(gtid);

    weight_sum = 1.0f;
    shadow_sum = shadow_center;

    const float variance = FetchFilteredVarianceFromGroupSharedMemory(gtid);
    const float std_deviation = sqrt(max(variance + 1e-9f, 0.0f));
    const float depth_center = GetLinearDepth(did, depth);    // linearize the depth value

    // Iterate filter kernel
    const int k = 1;
    const float kernel[3] = { 1.0f, 2.0f / 3.0f, 1.0f / 6.0f };

    for (int y = -k; y <= k; ++y)
    {
        for (int x = -k; x <= k; ++x)
        {
            // Should we process this sample?
            const int2 step = int2(x, y) * STEP_SIZE;
            const int2 gtid_idx = gtid + step;
            const int2 did_idx = did + step;

            float depth_neigh = LoadDepthFromGroupSharedMemory(gtid_idx);
            float3 normal_neigh = LoadNormalsFromGroupSharedMemory(gtid_idx);
            float2 shadow_neigh = LoadInputFromGroupSharedMemory(gtid_idx);

            float sky_pixel_multiplier = ((x == 0 && y == 0) || depth_neigh >= 1.0f || depth_neigh <= 0.0f) ? 0 : 1; // Zero weight for sky pixels

            // Fetch our filtering values
            depth_neigh = GetLinearDepth(did_idx, depth_neigh);

            // Evaluate the edge-stopping function
            float w = kernel[abs(x)] * kernel[abs(y)];  // kernel weight
            w *= GetShadowSimilarity(shadow_center.x, shadow_neigh.x, std_deviation);
            w *= GetDepthSimilarity(depth_center, depth_neigh, 1.0f);
            w *= GetNormalSimilarity(normal_center, normal_neigh);
            w *= sky_pixel_multiplier;

            // Accumulate the filtered sample
            shadow_sum += float2(w, w * w) * shadow_neigh;
            weight_sum += w;
        }
    }
}

void ApplyFilterWithPrecache(uint2 did, uint2 gtid)
{
    float weight_sum = 1.0;
    float2 shadow_sum = 0.0;

    float depth = DepthBuffer.Load(int3(did, 0)).x;
    InitializeGroupSharedMemory(did, gtid);
    bool needs_denoiser = depth > 0.0f && depth < 1.0f;
    GroupMemoryBarrierWithGroupSync();

    if (needs_denoiser)
    {
        gtid += 4; // Center threads in groupshared memory
        DenoiseFromGroupSharedMemory(did, gtid, weight_sum, shadow_sum, depth);
    }
//#if PASS_INDEX == 2
//    PreviousDepthBuffer[did] = depth;
//#endif
    float mean = shadow_sum.x / weight_sum;
    float variance = shadow_sum.y / (weight_sum * weight_sum);
    StoreOutput(did, mean, variance);
}
void ReadTileMetaData(uint2 gid, out bool is_cleared, out bool all_in_light)
{
    uint meta_data = TileMetaData[gid.y * RoundedDivide(BufferDimensions.x, 8) + gid.x];
    is_cleared = meta_data & TILE_META_DATA_CLEAR_MASK;
    all_in_light = meta_data & TILE_META_DATA_LIGHT_MASK;
}

[numthreads(8, 8, 1)]
void main(uint2 gid : SV_GroupID, uint2 gtid : SV_GroupThreadID, uint2 did : SV_DispatchThreadID)
{
    bool is_cleared;
    bool all_in_light;
    ReadTileMetaData(gid, is_cleared, all_in_light);

    [branch]
    if (is_cleared)
    {
#if PASS_INDEX != 1 // We reuse the same target as the reprojection in the second filter pass (PASS_INDEX == 1), which is already cleared.
        float mean = all_in_light ? 1.0 : 0.0;
        float variance = 0.0;
        StoreOutput(did, mean, variance);
#endif

//#if PASS_INDEX == 2
//        PreviousDepthBuffer[did] = DepthBuffer.Load(int3(did, 0)).x;
//#endif
    }
    else
    {
        ApplyFilterWithPrecache(did, gtid);
    }
}
