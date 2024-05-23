#include "materials/programs/utils_vegetation.hlsl"

cbuffer CSConstantBuffer : register(b0)
{
#ifndef __PSSL__
    uint4         cVertexStrideInfo;
#endif
#if USE_VEGETATION
    float4        cBendingInfo;
#endif
#if USE_HW_SKINNING
    float3x4      cWorld3x4Array[ MAX_BONE_MATRICES ];
#else
    matrix        cWorld;
#endif
};

#ifdef __PSSL__
Buffer<float3>              InputPosition 			 : register(t0);
#else
ByteAddressBuffer           InputPosition            : register(t0);
#endif

#if USE_HW_SKINNING
#ifdef __PSSL__
Buffer<float4>              InputBlendWeights        : register(t1);
Buffer<ushort4>             InputBlendIndices        : register(t2);
#else
ByteAddressBuffer           InputBlendWeights        : register(t1);
ByteAddressBuffer           InputBlendIndices        : register(t2);
#endif
#endif

RWStructuredBuffer<float3>  OutputBuffer             : register(u0);

[ numthreads( 64, 1, 1 ) ]
void main(uint3 dtID : SV_DispatchThreadID)
{
    uint i = dtID.x;
#ifdef __PSSL__
    uint vertexCount;
    InputPosition.GetDimensions( vertexCount );
#else
    uint vertexCount = cVertexStrideInfo.w;
#endif
    if ( i >= vertexCount )
        return;

#ifdef __PSSL__
    float4 position = float4( InputPosition[ i ].xyz, 1.0f );
#else
    float4 position = float4( asfloat( InputPosition.Load3( cVertexStrideInfo.x * i ) ), 1.0f );
#endif

#if USE_VEGETATION
    VertexBending( position, cBendingInfo );
#endif 

#if USE_HW_SKINNING
#   ifdef __PSSL__
    float4 blendWeights = InputBlendWeights[ i ];
    ushort4 blendIndices = InputBlendIndices[ i ];
#   else
    float4 blendWeights = asfloat( InputBlendWeights.Load4( cVertexStrideInfo.y * i ) );
    uint2 blendIndicesRaw = InputBlendIndices.Load2( cVertexStrideInfo.z * i );
    uint4 blendIndices = uint4( blendIndicesRaw.x & 0xffff, blendIndicesRaw.x >> 16, blendIndicesRaw.y & 0xffff, blendIndicesRaw.y >> 16 );
#   endif
    float3x4 cWorld = blendWeights.x * cWorld3x4Array[ blendIndices.x ];
    cWorld += blendWeights.y * cWorld3x4Array[ blendIndices.y ];
    cWorld += blendWeights.z * cWorld3x4Array[ blendIndices.z ];
    cWorld += blendWeights.w * cWorld3x4Array[ blendIndices.w ];
#endif

    float3 worldPos =  mul( cWorld, position );
    OutputBuffer[ i ] = float4( worldPos, 1.0f );
}
