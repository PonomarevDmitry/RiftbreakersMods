#include "raytracing_utils_d3d12.hlsl"

cbuffer PassData : register(b0)
{    
    int                               FrameIndex;
    int                               InstanceInclusionMask;
    float                             RayPushoffAmount;
    float                             AORadius;
    float4                            BufferDimensions;
    float4                            GBufferDimensions;
    float4x4                          ViewProjectionInverse;
}

RW_Texture2D<uint>                    OutputBuffer          : register(u0);
Texture2D                             DepthBuffer           : register(t0);
Texture2D                             NormalBuffer          : register(t1);
RegularBuffer<uint>                   SobolBuffer           : register(t2);
RegularBuffer<uint>                   ScramblingTileBuffer  : register(t3);

struct AnyHitSrt
{
    float4                            cAlphaTest;
    uint                              cIndexStride;
    SamplerState                      Sampler;
    Texture2D                         AlbedoBuffer;
    Texture2D                         DissolveBuffer;
    DataBuffer<float2>                VertexBuffer;
    DataBuffer<ushort>                IndexBuffer;
};

struct TraceRaySrt
{
    sce::Psr::TopLevelBvhDescriptor   SceneBuffer;
    RegularBuffer<AnyHitSrt>          AnyHitData;
};

float Sample(in uint pixel_i, in uint pixel_j, in uint sample_index, in uint sample_dimension )
{
    pixel_i = pixel_i & 127u;
    pixel_j = pixel_j & 127u;
    sample_index = sample_index & 255u;
    sample_dimension = sample_dimension & 255u;

    const uint ranked_sample_index = sample_index ^ 0;
    uint value = SobolBuffer[sample_dimension + ranked_sample_index * 256u];
    value = value ^ ScramblingTileBuffer[(sample_dimension % 8u) + (pixel_i + pixel_j * 128u) * 8u];
    return (value + 0.5f) / 256.0f;
}

[NUM_THREADS(8,8,1)]
void main( int2 did : S_DISPATCH_THREAD_ID, TraceRaySrt srt : S_SRT_DATA0 )
{
    const float scale = BufferDimensions.x / GBufferDimensions.x;
    int2 gbuffer_id = int2(did.xy / scale);
    const float2 uv = (did.xy + 0.5f) * BufferDimensions.zw;   // normalized texture coordinates
    const float2 ndc = 2.0f * float2(uv.x, 1.0f - uv.y) - 1.0f;     // to clip space
    const float depth = DepthBuffer.Load(int3(gbuffer_id.xy, 0)).x;   // non-linear depth

    const float4 homogeneous = mul(ViewProjectionInverse, float4(ndc, depth, 1.0f));
    const float3 world_position = homogeneous.xyz / homogeneous.w;  // perspective divide
    const float3 normal = normalize(2.0f * NormalBuffer.Load(int3(gbuffer_id.xy, 0)).xyz - 1.0f);
    const float2 s = float2( fmod(Sample(did.x, did.y, 0u, 0u) + (FrameIndex & 0xFFu) * GOLDEN_RATIO, 1.0f), fmod(Sample(did.x, did.y, 0u, 1u) + (FrameIndex & 0xFFu) * GOLDEN_RATIO, 1.0f));
    const float3 ray_direction = normalize( MapToHemisphere( s, normal ) );

    float weight = dot( ray_direction, normal );

    bool occluded = true;
    if ( all( did.xy < uint2( BufferDimensions.xy ) ) && ( depth > 0.0f && depth < 1.0f ) && ( weight > 0.0f ) )
    {
        sce::Psr::Ray const rayDesc = 
        {
            .m_org = world_position,
            .m_dir = ray_direction,
            .m_tmin = RayPushoffAmount,
            .m_tmax = AORadius
        };

        auto const alphaTestLambda = [ srt ] ( float3 /* org */, float3 /* dir */, sce::Psr::Hit h ) 
        {
            uint const cIndexStride = srt.AnyHitData[ h.m_instanceID ].cIndexStride;

            uint3 tri;
            if ( cIndexStride == 2 )
            {
                uint indexAddress = h.m_primitiveIndex * 3;
                tri.x = srt.AnyHitData[ h.m_instanceID ].IndexBuffer[ indexAddress ];
                tri.y = srt.AnyHitData[ h.m_instanceID ].IndexBuffer[ indexAddress + 1 ];
                tri.z = srt.AnyHitData[ h.m_instanceID ].IndexBuffer[ indexAddress + 2 ];
            }
            else if ( cIndexStride == 4 )
            {
                uint indexAddress = h.m_primitiveIndex * 3;
                tri.x = ( srt.AnyHitData[ h.m_instanceID ].IndexBuffer[ indexAddress ] << 16 )     + srt.AnyHitData[ h.m_instanceID ].IndexBuffer[ indexAddress + 1 ];
                tri.y = ( srt.AnyHitData[ h.m_instanceID ].IndexBuffer[ indexAddress + 2 ] << 16 ) + srt.AnyHitData[ h.m_instanceID ].IndexBuffer[ indexAddress + 3 ];
                tri.z = ( srt.AnyHitData[ h.m_instanceID ].IndexBuffer[ indexAddress + 4 ] << 16 ) + srt.AnyHitData[ h.m_instanceID ].IndexBuffer[ indexAddress + 5 ];
            }
            else
            {
                uint indexAddress = h.m_primitiveIndex * 3;
                tri = uint3( indexAddress, indexAddress + 1, indexAddress + 2 );
            }

            float2 const uv1 = srt.AnyHitData[ h.m_instanceID ].VertexBuffer[ tri[ 0 ] ];
            float2 const uv2 = srt.AnyHitData[ h.m_instanceID ].VertexBuffer[ tri[ 1 ] ];
            float2 const uv3 = srt.AnyHitData[ h.m_instanceID ].VertexBuffer[ tri[ 2 ] ];

            float const u = h.m_u;
            float const v = h.m_v;
            float const w = 1.0 - u - v;
            
            float2 const uv = u * uv2 + v * uv3 + w * uv1;

            float const alfa = srt.AnyHitData[ h.m_instanceID ].AlbedoBuffer.SampleLOD( srt.AnyHitData[ h.m_instanceID ].Sampler, uv, 0).w;

            float4 const cAlphaTest = srt.AnyHitData[ h.m_instanceID ].cAlphaTest;
            const bool bNotBurningOrDissolving = ( cAlphaTest.w + cAlphaTest.z ) == 0.0f;

            if ( alfa >= cAlphaTest.x && bNotBurningOrDissolving )
            {
                return true;
            }

            if ( alfa < cAlphaTest.x && bNotBurningOrDissolving )
            {
                return false;
            }

            const bool bAlphaBelowBurningThreshold = alfa < cAlphaTest.y;

            float mask = 1.0f;
            if ( cAlphaTest.z > 0.0f || ( cAlphaTest.w > 0.0f && bAlphaBelowBurningThreshold ) )
            {
                mask = srt.AnyHitData[ h.m_instanceID ].DissolveBuffer.SampleLOD( srt.AnyHitData[ h.m_instanceID ].Sampler, uv, 0).r;
            }

            if ( alfa < cAlphaTest.x || mask < cAlphaTest.z || ( mask < cAlphaTest.w && bAlphaBelowBurningThreshold ))
            {
                return false;
            }
            else
            {
                return true;
            }
        };

        auto const noIntersection = sce::Psr::NoIntersection{};
        auto const noAABBInstance = sce::Psr::NoAABBInstance { srt.SceneBuffer };

        occluded = sce::Psr::Occluded< sce::Psr::TraversalFlags::kUseSharedStack >(
            srt.SceneBuffer,
            sce::Psr::RayFlags::kNone,
            InstanceInclusionMask,
            rayDesc,
            alphaTestLambda,
            noIntersection,
            noAABBInstance ).isHit();
    }

    OutputBuffer[did.xy] = occluded ? 0 : 1;
}
