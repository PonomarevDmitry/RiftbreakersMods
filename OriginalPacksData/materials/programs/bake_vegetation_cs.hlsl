#include "materials/programs/utils_vegetation.hlsl"

cbuffer CSConstantBuffer : register(b0)
{
#ifndef __PSSL__
    uint4         cVertexStrideInfo;
#endif
    float4        cBendingInfo;
    matrix        cWorld;
};

#ifdef __PSSL__
Buffer<float3>              InputPosition     : register(t0);
#else
ByteAddressBuffer           InputPosition     : register(t0);
#endif
RWStructuredBuffer<float3>  OutputBuffer      : register(u0);

[ numthreads( 64, 1, 1 ) ]
void main(uint3 dtID : SV_DispatchThreadID)
{
    uint i = dtID.x;
#ifdef __PSSL__
    uint vertexCount;
    InputPosition.GetDimensions( vertexCount );
    if ( i >= vertexCount )
        return;

    float4 vPos = float4( InputPosition[ i ].xyz, 1.0f );
#else
    if ( i >= cVertexStrideInfo.w )
        return;

    float4 vPos = float4( asfloat( InputPosition.Load3( cVertexStrideInfo.x * i ) ), 1.0f );
#endif

    MainBending( vPos, cBendingInfo.xy );
    OutputBuffer[ i ] = mul( cWorld, vPos );
}