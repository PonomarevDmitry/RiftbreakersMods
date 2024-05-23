cbuffer CSConstantBuffer : register(b0)
{
    matrix          cInvProjMatrix;
    uint2           cViewportSize;
    uint            cNumLights;
}

struct LightCullingData
{
    uint            Type;
    float3          ViewPos;
    //float3          ViewDir;
    //float           SpotlightAngle;
    float           Range;
    float3          Padding;
};

struct Plane
{
    float3          n;   // Normal
    float           d;   // Distance
};

struct Frustum
{
    Plane           planes[4];
};

struct Sphere
{
    float3          c;   // Center point
    float           r;   // Radius
};

struct Cone
{
    float3          t;   // Cone tip
    float           h;   // Height
    float3          d;   // Direction 
    float           r;   // Bottom radius
};

struct AABB
{
    float3          c;   // Center
    float3          e;   // Half extents
};

void AABBfromMinMax( inout AABB aabb, float3 _min, float3 _max )
{
    aabb.c = ( _min + _max ) * 0.5f;
    aabb.e = abs( _max - aabb.c );
}

#include "materials/programs/tiled_deferred_light_internal.hlsl"

Texture2D                               DepthTexture                    : register( t0 );
StructuredBuffer< Frustum >             Frustums                        : register( t1 );
StructuredBuffer< LightCullingData >    Lights                          : register( t2 );

RWStructuredBuffer<uint>                OpaqueLightIndexList            : register( u0 );
RWStructuredBuffer<uint>                TransparentLightIndexList       : register( u1 );

groupshared uint                        MinDepth;
groupshared uint                        MaxDepth;
groupshared uint                        OpaqueLightList[ TILED_DEFERRED_MAX_LIGHT_BUCKET_COUNT ];
groupshared uint                        TransparentLightList[ TILED_DEFERRED_MAX_LIGHT_BUCKET_COUNT ];

bool IsSphereInsidePlane( in Sphere sphere, in Plane plane )
{
    return dot( plane.n, sphere.c ) - plane.d < -sphere.r;
}

bool PointInsidePlane( in float3 p, in Plane plane )
{
    return dot( plane.n, p ) - plane.d < 0;
}

bool IsConeInsidePlane( in Cone cone, in Plane plane )
{
    float3 m = cross( cross( plane.n, cone.d ), cone.d );
    float3 Q = cone.t + cone.d * cone.h - m * cone.r;
    return PointInsidePlane( cone.t, plane ) && PointInsidePlane( Q, plane );
}

bool IsSphereInsideFrustum( in Sphere sphere, in Frustum frustum, in float zNear, in float zFar )
{
    bool result = true;
    result = ( ( sphere.c.z - sphere.r > zNear || sphere.c.z + sphere.r < zFar ) ? false : result );
    result = ( ( IsSphereInsidePlane( sphere, frustum.planes[ 0 ] ) ) ? false : result );
    result = ( ( IsSphereInsidePlane( sphere, frustum.planes[ 1 ] ) ) ? false : result );
    result = ( ( IsSphereInsidePlane( sphere, frustum.planes[ 2 ] ) ) ? false : result );
    result = ( ( IsSphereInsidePlane( sphere, frustum.planes[ 3 ] ) ) ? false : result );
    return result;
}

bool IsSphereIntersectsAABB( in Sphere sphere, in AABB aabb )
{
    float3 delta = max( 0, abs( aabb.c - sphere.c ) - aabb.e );
    float distSq = dot( delta, delta );
    return distSq <= sphere.r * sphere.r;
}

bool IsConeInsideFrustum( in Cone cone, in Frustum frustum, in float zNear, in float zFar )
{
    Plane nearPlane = { float3( 0, 0, -1 ), -zNear };
    Plane farPlane = { float3( 0, 0, 1 ), zFar };

    bool result = true;
    if ( IsConeInsidePlane( cone, nearPlane ) || IsConeInsidePlane( cone, farPlane ) )
    {
        result = false;
    }

    for ( int i = 0; i < 4 && result; i++ )
    {
        if ( IsConeInsidePlane( cone, frustum.planes[i] ) )
        {
            result = false;
        }
    }

    return result;
}

void AppendLightOpaque( uint lightIndex )
{
    const uint bucketIndex = lightIndex / 32;
    const uint bucketPlace = lightIndex % 32;
    InterlockedOr( OpaqueLightList[ bucketIndex ], 1u << bucketPlace );
}

void AppendLightTransparent( uint lightIndex )
{   
    const uint bucketIndex = lightIndex / 32;
    const uint bucketPlace = lightIndex % 32;
    InterlockedOr( TransparentLightList[ bucketIndex ], 1u << bucketPlace );
}

float4 ClipToView( float4 clip )
{
    float4 view = mul( cInvProjMatrix, clip );
    view = view / view.w;
    return view;
}

float4 ScreenToView( float4 screen )
{
    float2 texCoord = screen.xy / cViewportSize.xy;
    float4 clip = float4( float2( texCoord.x, 1.0f - texCoord.y ) * 2.0f - 1.0f, screen.z, screen.w );
    return ClipToView( clip );
}

[numthreads( TILED_DEFERRED_BLOCK_SIZE, TILED_DEFERRED_BLOCK_SIZE, 1 )]
void main( uint3 groupID : SV_GroupID, uint3 groupThreadID : SV_GroupThreadID, uint groupIndex : SV_GroupIndex, uint3 dispatchThreadID  : SV_DispatchThreadID )
{
    uint uDepth = asuint( DepthTexture.Load( int3( dispatchThreadID.xy, 0 ) ).r );

    uint i = 0;
    for ( i = groupIndex; i < TILED_DEFERRED_MAX_LIGHT_BUCKET_COUNT; i += TILED_DEFERRED_BLOCK_SIZE * TILED_DEFERRED_BLOCK_SIZE )
    {
        OpaqueLightList[ i ] = 0;
        TransparentLightList[ i ] = 0;
    }

    if ( groupIndex == 0 )
    {
        MinDepth = 0xffffffff;
        MaxDepth = 0;
    }

    const uint linearTileIndex = LinearTileIndex( groupID.xy, cViewportSize.x );
    const uint lightIndexListAddress = linearTileIndex * TILED_DEFERRED_MAX_LIGHT_BUCKET_COUNT;
    Frustum GroupFrustum = Frustums[ linearTileIndex ];

    GroupMemoryBarrierWithGroupSync();

    InterlockedMin( MinDepth, uDepth );
    InterlockedMax( MaxDepth, uDepth );

    GroupMemoryBarrierWithGroupSync();

#ifdef INVERTED_DEPTH_RANGE
    float fMinDepth = asfloat( MaxDepth );
    float fMaxDepth = asfloat( MinDepth );
#else
    float fMinDepth = asfloat( MinDepth );
    float fMaxDepth = asfloat( MaxDepth );
#endif

    AABB GroupAABB;
#if SHADER_MODEL_5 != 1
    if( WaveIsFirstLane() )
    {
#endif
        float3 viewSpace[ 8 ];
        viewSpace[ 0 ] = ScreenToView( float4( groupID.xy                             * TILED_DEFERRED_BLOCK_SIZE, fMinDepth, 1.0f ) ).xyz;
        viewSpace[ 1 ] = ScreenToView( float4( float2( groupID.x + 1, groupID.y     ) * TILED_DEFERRED_BLOCK_SIZE, fMinDepth, 1.0f ) ).xyz;
        viewSpace[ 2 ] = ScreenToView( float4( float2( groupID.x,     groupID.y + 1 ) * TILED_DEFERRED_BLOCK_SIZE, fMinDepth, 1.0f ) ).xyz;
        viewSpace[ 3 ] = ScreenToView( float4( float2( groupID.x + 1, groupID.y + 1 ) * TILED_DEFERRED_BLOCK_SIZE, fMinDepth, 1.0f ) ).xyz;
        viewSpace[ 4 ] = ScreenToView( float4( groupID.xy                             * TILED_DEFERRED_BLOCK_SIZE, fMaxDepth, 1.0f ) ).xyz;
        viewSpace[ 5 ] = ScreenToView( float4( float2( groupID.x + 1, groupID.y     ) * TILED_DEFERRED_BLOCK_SIZE, fMaxDepth, 1.0f ) ).xyz;
        viewSpace[ 6 ] = ScreenToView( float4( float2( groupID.x,     groupID.y + 1 ) * TILED_DEFERRED_BLOCK_SIZE, fMaxDepth, 1.0f ) ).xyz;
        viewSpace[ 7 ] = ScreenToView( float4( float2( groupID.x + 1, groupID.y + 1 ) * TILED_DEFERRED_BLOCK_SIZE, fMaxDepth, 1.0f ) ).xyz;

        float3 minAABB = 10000000;
        float3 maxAABB = -10000000;
        [unroll]
        for ( i = 0; i < 8; ++i )
        {
            minAABB = min( minAABB, viewSpace[ i ] );
            maxAABB = max( maxAABB, viewSpace[ i ] );
        }

        AABBfromMinMax( GroupAABB, minAABB, maxAABB );
#if SHADER_MODEL_5 != 1
    }

    GroupAABB.c = WaveReadLaneFirst( GroupAABB.c );
    GroupAABB.e = WaveReadLaneFirst( GroupAABB.e );
#endif

    float minDepthVS = ScreenToView( float4( 0, 0, fMinDepth, 1 ) ).z;
    float maxDepthVS = ScreenToView( float4( 0, 0, fMaxDepth, 1 ) ).z;
#ifdef INVERTED_DEPTH_RANGE
    float nearClipVS = ScreenToView( float4( 0, 0, 1, 1 ) ).z;
#else
    float nearClipVS = ScreenToView( float4( 0, 0, 0, 1 ) ).z;
#endif

    Plane minPlane = { float3( 0, 0, -1 ), -minDepthVS };

    for ( i = groupIndex; i < cNumLights; i += TILED_DEFERRED_BLOCK_SIZE * TILED_DEFERRED_BLOCK_SIZE )
    {
        LightCullingData light = Lights[ i ];
        switch ( light.Type )
        {
            case POINT_LIGHT:
            case SPOT_LIGHT:
            {
                Sphere sphere = { light.ViewPos.xyz, light.Range };
                if ( IsSphereInsideFrustum( sphere, GroupFrustum, nearClipVS, maxDepthVS ) )
                {
                    AppendLightTransparent( i );
                    if ( IsSphereIntersectsAABB( sphere, GroupAABB ) )
                    {
                        AppendLightOpaque( i );
                    }
                }
            }
            break;
            case DIRECTIONAL_LIGHT:
            {
                AppendLightTransparent( i );     
                AppendLightOpaque( i );
            }
            break;
        }
    }

    GroupMemoryBarrierWithGroupSync();

    for ( i = groupIndex; i < TILED_DEFERRED_MAX_LIGHT_BUCKET_COUNT; i += TILED_DEFERRED_BLOCK_SIZE * TILED_DEFERRED_BLOCK_SIZE )
    {
        uint idx = lightIndexListAddress + i;
        OpaqueLightIndexList[ idx ] = OpaqueLightList[ i ];
        TransparentLightIndexList[ idx ] = TransparentLightList[ i ];
    }
}