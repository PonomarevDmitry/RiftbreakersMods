#include "materials/programs/utils_light.hlsl"

#define TILED_DEFERRED_BLOCK_SIZE 16
#define TILED_DEFERRED_MAX_LIGHT_BUCKET_COUNT 32

inline uint LinearTileIndex( uint2 tileIndex, uint screenWidth )
{
    return ( tileIndex.y * ceil( ( float )screenWidth / TILED_DEFERRED_BLOCK_SIZE ) ) + tileIndex.x;
}

inline uint LinearTileIndex( float2 uv, uint2 screenSize )
{
    const uint2 pixel = uv * screenSize.xy;
    const uint2 tileIndex = uint2( floor( pixel / TILED_DEFERRED_BLOCK_SIZE ) );
    return tileIndex.x + tileIndex.y * ceil( ( float )screenSize.x / TILED_DEFERRED_BLOCK_SIZE );
}
