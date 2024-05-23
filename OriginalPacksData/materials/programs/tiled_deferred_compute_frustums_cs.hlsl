cbuffer CSConstantBuffer : register(b0)
{
    matrix      cInvProjMatrix;
    int2        cViewportSize;
};

struct Plane
{
    float3 		normal;
    float  		d;
};

struct Frustum
{
    Plane 		planes[4];
};

#include "materials/programs/tiled_deferred_light_internal.hlsl"

RWStructuredBuffer< Frustum > OutputFrustums : register(u0);

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

Plane ComputePlane( float3 p0, float3 p1, float3 p2 )
{
    Plane plane;
    float3 edge1 = p1 - p0;
    float3 edge2 = p2 - p0;
    plane.normal = normalize( cross( edge1, edge2 ) );
    plane.d = dot( plane.normal, p0 );
    return plane;
}

[numthreads( TILED_DEFERRED_BLOCK_SIZE, TILED_DEFERRED_BLOCK_SIZE, 1 )]
void main( uint3 dispatchThreadID : SV_DispatchThreadID )
{    
    const int2 did = dispatchThreadID.xy;
    const int2 tileCount = ceil( ( float ) cViewportSize.xy / TILED_DEFERRED_BLOCK_SIZE );
    if ( any( did.xy >= tileCount.xy ) )
        return;

    float3 viewSpace[4];
    viewSpace[0] = ScreenToView( float4( float2( did.x    , did.y     ) * TILED_DEFERRED_BLOCK_SIZE, -1.0f, 1.0f ) ).xyz;
    viewSpace[1] = ScreenToView( float4( float2( did.x + 1, did.y     ) * TILED_DEFERRED_BLOCK_SIZE, -1.0f, 1.0f ) ).xyz;
    viewSpace[2] = ScreenToView( float4( float2( did.x,     did.y + 1 ) * TILED_DEFERRED_BLOCK_SIZE, -1.0f, 1.0f ) ).xyz;
    viewSpace[3] = ScreenToView( float4( float2( did.x + 1, did.y + 1 ) * TILED_DEFERRED_BLOCK_SIZE, -1.0f, 1.0f ) ).xyz;

    const float3 eyePos = float3( 0, 0, 0 );

    Frustum frustum;
    frustum.planes[0] = ComputePlane( eyePos, viewSpace[2], viewSpace[0] );
    frustum.planes[1] = ComputePlane( eyePos, viewSpace[1], viewSpace[3] );
    frustum.planes[2] = ComputePlane( eyePos, viewSpace[0], viewSpace[1] );
    frustum.planes[3] = ComputePlane( eyePos, viewSpace[3], viewSpace[2] );

    uint index = dispatchThreadID.x + ( dispatchThreadID.y * tileCount.x );
    OutputFrustums[index] = frustum;
}