
cbuffer CSConstantBuffer : register(b0)
{
#ifndef __PSSL__
    uint4         cVertexStrideInfo;
#endif
    float3x4      cWorld3x4Array[ MAX_BONE_MATRICES ];
};

#ifdef __PSSL__
Buffer<float3>              InputPosition 			 : register(t0);
Buffer<float4>              InputBlendWeights 		 : register(t1);
Buffer<ushort4>             InputBlendIndices        : register(t2);
#else
ByteAddressBuffer           InputPosition            : register(t0);
ByteAddressBuffer           InputBlendWeights        : register(t1);
ByteAddressBuffer           InputBlendIndices        : register(t2);
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
    float4 blendWeights = InputBlendWeights[ i ];
    ushort4 blendIndices = InputBlendIndices[ i ];
    float3 position = InputPosition[ i ];
#else
    float3 position = asfloat( InputPosition.Load3( cVertexStrideInfo.x * i ) );
    float4 blendWeights = asfloat( InputBlendWeights.Load4( cVertexStrideInfo.y * i ) );
    uint2 blendIndicesRaw = InputBlendIndices.Load2( cVertexStrideInfo.z * i );
    uint4 blendIndices = uint4( blendIndicesRaw.x & 0xffff, blendIndicesRaw.x >> 16, blendIndicesRaw.y & 0xffff, blendIndicesRaw.y >> 16 );
#endif

    float last = 1.0f;
    float3x4 world = float3x4( 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0 );
    for (int j = 0; j < 4; ++j)
    {        
        uint idx = blendIndices[ j ];
        float weight = ( j == 3 ) ? last : blendWeights[ j ];
        world += cWorld3x4Array[ idx ] * weight;
        last -= weight;
    }

    OutputBuffer[ i ] = mul( world, float4( position, 1.0f ) );
}
