#include "materials/programs/utils.hlsl"

struct VS_OUTPUT
{
    float4      Position    : SV_POSITION;
    float2      TexCoord    : TEXCOORD0;
};

struct PS_OUTPUT
{
    float4      Color0      : SV_TARGET;
};

Texture2D       tTex0       : register( t0 );
SamplerState    sTex0       : register( s0 );

#if VELOCITY

//
// Motion vector visualization inspired by: https://www.shadertoy.com/view/3dlGDM
//

#define BLOCK_SIZE             16.0f
#define LINE_THICKNESS         0.5f
#define EPSILON                1e-4
#define MIN_VELOCITY_EPSILON   1e-5
#define MAX_VELOCITY_EPSILON   0.1f
#define POINT_SIZE             0.75f
#define BLEND_ALPHA            0.75f

float distanceToLineSegment( float2 p, float2 start, float2 end )
{
    float len = length( start - end );
    float lensq = len * len;
    if ( lensq < EPSILON )
        return length( p - start );
    float t = clamp( dot( p - start, end - start ) / lensq, 0.0f, 1.0f );
    float2 projection = start + t * ( end - start );
    return length( p - projection );
}

float4 drawMotionVectors( float2 pos, float2 uv )
{
    float2 dims;
    tTex0.GetDimensions( dims.x, dims.y );

    float2 blockCenterPos = floor( pos / BLOCK_SIZE ) * BLOCK_SIZE + ( BLOCK_SIZE * 0.5f );

    // Draw a red center dot
    if ( distance( blockCenterPos, pos ) < POINT_SIZE )
    {
        return float4( 0.25f, 0.0f, 0.0f, BLEND_ALPHA );
    }

    float2 blockUvDelta = ( BLOCK_SIZE / dims ) * 0.25f;
    float2 blockCenterUvs = blockCenterPos / dims;

    // Accumulate 5 samples with a sample 5-dice pattern
    float2 mv = tTex0.Sample( sTex0, blockCenterUvs ).xy;
    mv += tTex0.Sample( sTex0, blockCenterUvs - blockUvDelta ).xy;
    mv += tTex0.Sample( sTex0, blockCenterUvs + blockUvDelta ).xy;
    mv += tTex0.Sample( sTex0, float2( blockCenterUvs.x - blockUvDelta.x, blockCenterUvs.y + blockUvDelta.y ) ).xy;
    mv += tTex0.Sample( sTex0, float2( blockCenterUvs.x + blockUvDelta.x, blockCenterUvs.y - blockUvDelta.y ) ).xy;
    mv.y = -mv.y; // adjust for y direction
    mv *= 0.2f;

    // Fetch motion vector
    float2 posmv = tTex0.Sample( sTex0, uv ).xy;

    // Colorize motion vector; max normal motion seems to be in the abs(0.02) region, rescale to 1.0 and add some boost
    float2 posmvcol = abs( posmv * 60.0f );

    // Sanity range check
    float vel = length( mv );
    if ( vel < MIN_VELOCITY_EPSILON )
    {
        return float4( posmvcol.x, posmvcol.y, 0.0f, BLEND_ALPHA );
    }
    else if ( vel > MAX_VELOCITY_EPSILON )
    {
        return float4( posmvcol.x, posmvcol.y, 1.0f, BLEND_ALPHA );
    }

    // Calculate previous
    float2 previousCenterPos = blockCenterPos - mv * dims * 12.0f;
    float lineDistance = distanceToLineSegment( pos, blockCenterPos, previousCenterPos );

    // fake line AA
    float t = lineDistance - LINE_THICKNESS;
    t = smoothstep( -LINE_THICKNESS, LINE_THICKNESS, t );
    float3 finalCol = ( 1.0f - t ) * float3( 1.0f, 1.0f, 1.0f ) + t * float3( posmvcol.x, posmvcol.y, 0.0f );
    return float4( finalCol, BLEND_ALPHA );
}
#endif


PS_OUTPUT mainFP( VS_OUTPUT In )
{
    PS_OUTPUT Out;
#if CHANNEL_X
    Out.Color0 = float4( tTex0.Sample( sTex0, In.TexCoord ).xxx, 1.0f );
#elif CHANNEL_Y
    Out.Color0 = float4( tTex0.Sample( sTex0, In.TexCoord ).yyy, 1.0f );
#elif CHANNEL_Z
    Out.Color0 = float4( tTex0.Sample( sTex0, In.TexCoord ).zzz, 1.0f );
#elif CHANNEL_W
    Out.Color0 = float4( tTex0.Sample( sTex0, In.TexCoord ).www, 1.0f );
#elif GRAYSCALE
    Out.Color0 = float4( dot( tTex0.Sample( sTex0, In.TexCoord ).xyz, float3( 0.21f, 0.72f, 0.07f ) ).xxx, 1.0f );
#elif VELOCITY
    Out.Color0 = drawMotionVectors( In.Position.xy, In.TexCoord );
#elif SRGB
    Out.Color0 = float4( LinearToSRGB( tTex0.Sample( sTex0, In.TexCoord ).xyz ), 1.0f );
#else
    Out.Color0 = tTex0.Sample( sTex0, In.TexCoord );
#endif
    return Out;
}
