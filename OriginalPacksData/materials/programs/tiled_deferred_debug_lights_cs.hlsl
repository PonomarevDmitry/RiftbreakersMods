cbuffer CSConstantBuffer : register( b0 )
{
    int2        			cViewportSize;
    int         			cNumLights;
};

StructuredBuffer<uint>   	LightIndexList;
RWTexture2D<float4> 		OutputTexture : register( u0 );

#include "materials/programs/tiled_deferred_light_internal.hlsl"

[numthreads( TILED_DEFERRED_BLOCK_SIZE, TILED_DEFERRED_BLOCK_SIZE, 1 )]
void main( uint3 groupID : SV_GroupID, uint3 dispatchThreadID  : SV_DispatchThreadID )
{    
    const int3 did = int3( dispatchThreadID.xy, 0 );
    if ( any( did.xy >= cViewportSize.xy ) )
        return;
        
    uint lightCount = 0;

    const uint linearTileIndex = LinearTileIndex( groupID.xy, cViewportSize.x );
    const uint lightIndexListAddress = linearTileIndex * TILED_DEFERRED_MAX_LIGHT_BUCKET_COUNT;
	const uint lastMaxLightIndex = cNumLights - 1;
	const uint lastLightBucket = min( lastMaxLightIndex / 32u, max( 0u, ( uint ) TILED_DEFERRED_MAX_LIGHT_BUCKET_COUNT - 1 ) );
	[loop]
	for ( uint lightBucket = 0; lightBucket <= lastLightBucket; ++lightBucket )
	{    
		uint lightBits = LightIndexList[ lightIndexListAddress + lightBucket ];
		[loop]
		while (lightBits != 0)
		{
			const uint lightBitIndex = firstbitlow( lightBits );
			const uint lightIndex = lightBucket * 32 + lightBitIndex;
			lightBits ^= 1u << lightBitIndex;
            lightCount++; 
		}
	}

    if ( did.x % TILED_DEFERRED_BLOCK_SIZE == 0 || did.y % TILED_DEFERRED_BLOCK_SIZE == 0 )
        OutputTexture[ did.xy ] = float4( 0.25, 0.25, 0.25, 1.0f );
    else if ( lightCount < 8 )
        OutputTexture[ did.xy ] += lerp( float4( 0.0, 0.0, 0.0, 0.0 ), float4( 0.0, 0.0, 1.0, 0.0 ), saturate( lightCount / 8.0f ) );
    else if ( lightCount < 16 )
        OutputTexture[ did.xy ] += lerp( float4( 0.0, 0.0, 1.0, 0.0 ), float4( 0.0, 1.0, 0.0, 0.0 ), saturate( lightCount / 16.0f ) );
    else
        OutputTexture[ did.xy ] += lerp( float4( 0.0, 1.0, 0.0, 0.0 ), float4( 1.0, 0.0, 0.0, 0.0 ), saturate( lightCount / 32.0f ) );
}