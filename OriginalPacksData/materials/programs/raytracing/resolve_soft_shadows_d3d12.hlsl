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

struct RayPayload
{
    bool hit_light;
    uint ray_info;
};

RWTexture2D<uint>               OutputBuffer         : register(u0);
Texture2D                       DepthBuffer          : register(t0);
Texture2D                       NormalBuffer         : register(t1);
Texture2D                       ScatteringBuffer     : register(t2);
StructuredBuffer<uint>          SobolBuffer          : register(t3);
StructuredBuffer<uint>          ScramblingTileBuffer : register(t4);
RaytracingAccelerationStructure SceneBuffer          : register(t5);

Texture2D                       AlbedoBuffer         : register(t0, space1);
Texture2D                       DissolveBuffer       : register(t1, space1);
SamplerState                    AlbedoSampler        : register(s0, space1);
ByteAddressBuffer               VertexBuffer         : register(t2, space1);
ByteAddressBuffer               IndexBuffer          : register(t3, space1);

#include "raytracing_utils_d3d12.hlsl"

cbuffer PassData : register(b0)
{
    int      FrameIndex;
    int      InstanceInclusionMask;
    float    RayPushoffAmount;
#if Z_LIGHT_TYPE == LIGHT_TYPE_DIRECTIONAL
    float    LightSize;
    float4   LightDirection;
#elif Z_LIGHT_TYPE == LIGHT_TYPE_POINT
    float    LightSize;
    float    LightRadius;
    float4   LightPosition;
#elif Z_LIGHT_TYPE == LIGHT_TYPE_SPOTLIGHT
    float    LightSize;
    float    LightRange;
    float    LightAngle;
    float4   LightPosition;
    float4   LightDirection;
#endif
    float4   BufferDimensions;
    float4   GBufferDimensions;
    float4x4 ViewProjectionInverse;
}

cbuffer AnyHitData : register(b0, space1)
{
    float4 cAlphaTest;
    uint   cIndexStride;
    uint   cVertexStride;
};

float Sample(in uint pixel_i, in uint pixel_j, in uint sample_index, in uint sample_dimension)
{
    // Wrap arguments
    pixel_i = pixel_i & 127u;
    pixel_j = pixel_j & 127u;
    sample_index = sample_index & 255u;
    sample_dimension = sample_dimension & 255u;

    // xor index based on optimized ranking
    const uint ranked_sample_index = sample_index ^ 0;

    // Fetch value in sequence
    uint value = SobolBuffer[sample_dimension + ranked_sample_index * 256u];

    // If the dimension is optimized, xor sequence value based on optimized scrambling
    value = value ^ ScramblingTileBuffer[(sample_dimension % 8u) + (pixel_i + pixel_j * 128u) * 8u];

    // Convert to float and return
    return (value + 0.5f) / 256.0f;
}

[shader("raygeneration")]
void raygeneration()
{
    // Retrieve the iterated texel
    const float scale = BufferDimensions.x / GBufferDimensions.x;
    const uint3 did = DispatchRaysIndex();
    uint2 gbuffer_id = did.xy / scale;
    const float2 uv = (did.xy + 0.5f) * BufferDimensions.zw;   // normalized texture coordinates
    const float2 ndc = 2.0f * float2(uv.x, 1.0f - uv.y) - 1.0f;     // to clip space
    const float depth = DepthBuffer.Load(int3(gbuffer_id.xy, 0)).x;   // non-linear depth

    // Do not raytrace the sky pixels
    bool is_valid = all(did.xy < uint2(BufferDimensions.xy)) && (depth > 0.0f && depth < 1.0f);

    // Recover the world-space position
    const float4 homogeneous = mul(ViewProjectionInverse, float4(ndc, depth, 1.0f));
    const float3 world_position = homogeneous.xyz / homogeneous.w;  // perspective divide

#if Z_LIGHT_TYPE == LIGHT_TYPE_DIRECTIONAL
    const float distance_to_light = 1e9f;
#elif Z_LIGHT_TYPE == LIGHT_TYPE_POINT
    const float3 light_direction = LightPosition - world_position;
    const float distance_to_light = length(light_direction);

    is_valid = is_valid && !(distance_to_light > LightRadius);

#elif Z_LIGHT_TYPE == LIGHT_TYPE_SPOTLIGHT
    const float3 light_direction = LightPosition - world_position;
    const float distance_to_light = length(light_direction);
    const float angle_to_light = acos( dot( normalize( light_direction ), -LightDirection ) );

    is_valid = is_valid && !(distance_to_light > LightRange || angle_to_light > LightAngle );

#endif

    const float3 normal = normalize(2.0f * NormalBuffer.Load(int3(gbuffer_id.xy, 0)).xyz - 1.0f);
    const float scatter = ScatteringBuffer.Load(int3(gbuffer_id.xy, 0)).x;

    uint result = 0u;

    RayPayload ray_payload;
    ray_payload.hit_light = false;
    ray_payload.ray_info = 0;

    // Use golden ratio to animate the noise over time:
    // https://blog.demofox.org/2017/10/31/animating-noise-for-integration-over-time/
    const float2 s = float2(
        fmod(Sample(did.x, did.y, 0u, 0u) + (FrameIndex & 0xFFu) * GOLDEN_RATIO, 1.0f),
        fmod(Sample(did.x, did.y, 0u, 1u) + (FrameIndex & 0xFFu) * GOLDEN_RATIO, 1.0f));

#if Z_LIGHT_TYPE == LIGHT_TYPE_DIRECTIONAL
    const float3 ray_direction = normalize(MapToCone(s, -LightDirection, LightDirection, LightSize));
#elif Z_LIGHT_TYPE == LIGHT_TYPE_POINT
    const float3 ray_direction = normalize(MapToCone(s, LightPosition, normalize(light_direction), LightSize) - world_position);
#elif Z_LIGHT_TYPE == LIGHT_TYPE_SPOTLIGHT
    const float3 ray_direction = normalize(MapToCone(s, LightPosition, normalize(light_direction), LightSize) - world_position);
#endif

    // Populate the shadow ray
    RayDesc ray_desc;
    ray_desc.Origin = world_position;
    ray_desc.Direction = ray_direction;
    ray_desc.TMin = RayPushoffAmount;
    ray_desc.TMax = distance_to_light;

    // We only need to traverse the scene if the ray falls within the oriented hemisphere
    if ( dot( ray_desc.Direction, normal ) <= 0.0f )
    {
        is_valid = is_valid && ( scatter > 0 ) ? true : false;
    }

    if ( is_valid )
    {
        TraceRay(SceneBuffer,
                 RAY_FLAG_SKIP_CLOSEST_HIT_SHADER | RAY_FLAG_ACCEPT_FIRST_HIT_AND_END_SEARCH,
                 InstanceInclusionMask,
                 0u,
                 0u,
                 0u,
                 ray_desc,
                 ray_payload);
    }

    OutputBuffer[did.xy] = ray_payload.hit_light ? 1 : 0;
}

[shader("anyhit")]
void anyhitAlphaTest(inout RayPayload ray_payload, in BuiltInTriangleIntersectionAttributes attribs)
{   
    uint triangleIndex = PrimitiveIndex() * 3;
    uint3 indexData;
    if ( cIndexStride == 2 )
    {     
        uint indexAddress = triangleIndex * cIndexStride;
        indexData = Load3x16BitIndices( indexAddress );
    }
    else if ( cIndexStride == 4 )
    {         
        uint indexAddress = triangleIndex * cIndexStride;
        indexData = asuint( IndexBuffer.Load< uint3 >( indexAddress ) );
    }
    else
    {
        uint vertexAddress = triangleIndex;
        indexData = uint3( vertexAddress, vertexAddress + 1, vertexAddress + 2 );
    }

    float2 uv1 = VertexBuffer.Load< float2 >( ( indexData.x * cVertexStride ) );
    float2 uv2 = VertexBuffer.Load< float2 >( ( indexData.y * cVertexStride ) );
    float2 uv3 = VertexBuffer.Load< float2 >( ( indexData.z * cVertexStride ) );

    float3 barycentrics = float3( 1 - attribs.barycentrics.x - attribs.barycentrics.y, attribs.barycentrics.x, attribs.barycentrics.y );
    float2 uv = ( uv1 * barycentrics.x ) + ( uv2 * barycentrics.y ) + ( uv3 * barycentrics.z );

    float alfa = AlbedoBuffer.SampleLevel( AlbedoSampler, uv, 0 ).w;

    // increment ray depth counter
    ray_payload.ray_info += 1;

    const bool bNotBurningOrDissolving = (cAlphaTest.w + cAlphaTest.z) == 0.0f;

    // the object counts as opaque and is not burning and not dissolving
    if (alfa >= cAlphaTest.x && bNotBurningOrDissolving)
    {
        AcceptHitAndEndSearch();
    }

    // the object is transparent and is not burning and not dissolving
    if ( alfa < cAlphaTest.x && bNotBurningOrDissolving )
    {
        if (ray_payload.ray_info > 6)
        {
            ray_payload.hit_light = false;   // the light is not visible
            AcceptHitAndEndSearch();
        }
        else
        {
			IgnoreHit();
        }
    }

    const bool bAlphaBelowBurningThreshold = alfa < cAlphaTest.y;

    float mask = 1.0f;
    // only sample the mask texture if the object is burning or dissolving
    if ( cAlphaTest.z > 0.0f || ( cAlphaTest.w > 0.0f && bAlphaBelowBurningThreshold ))
    {
        mask = DissolveBuffer.SampleLevel(AlbedoSampler, uv, 0).r;
    }

    if ( alfa < cAlphaTest.x || mask < cAlphaTest.z || ( mask < cAlphaTest.w && bAlphaBelowBurningThreshold ))
    {
        if ( ray_payload.ray_info > 15 )
        {
            ray_payload.hit_light = false;   // the light is not visible
            AcceptHitAndEndSearch();
        }
		else
        {
            IgnoreHit();
        }
    }
    else
    {
        AcceptHitAndEndSearch();
	}
}

[shader("miss")]
void miss(inout RayPayload ray_payload)
{
    ray_payload.hit_light = true;   // the light is visible
}
