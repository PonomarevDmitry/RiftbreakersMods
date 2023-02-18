#include "materials/programs/utils.hlsl"
#include "materials/programs/pack_ops.hlsl"

struct VS_OUTPUT
{
    float4  Position                : SV_POSITION;
    float2  TexCoord                : TEXCOORD0;
};

struct PS_OUTPUT
{
    float4  Color0                  : SV_TARGET0;
};

cbuffer FPConstantBuffer : register(b0)
{
    float4    cOutlineColor;
    float4    cCameraWorldPos;
    matrix    cInvView;
    matrix    cInvProj;
#if USE_FRESNEL
    float     cFresnelBias;
    float     cFresnelScale;
    float     cFresnelPower;
#endif
};

Texture2D       tDepthTex           : register( t0 );
SamplerState    sDepthTex           : register( s0 );
Texture2D       tNormalTex          : register( t1 );
SamplerState    sNormalTex          : register( s1 );
Texture2D       tNoise              : register( t2 );
SamplerState    sNoise              : register( s2 );

inline float4 getViewPosFromDepth( float2 screenPos )
{
    float x = screenPos.x * 2.0f - 1.0f;
    float y = (1.0f - screenPos.y) * 2.0f - 1.0f;
    float z = tDepthTex.SampleLevel( sDepthTex, screenPos.xy, 0 ).r;

    float4 projPos = float4( x, y, z, 1.0f );
    float4 viewPos = mul( cInvProj, projPos );
    viewPos = viewPos.xyzw / viewPos.w;
    return viewPos;
}

inline float4 getWorldPosFromDepth( float2 screenPos )
{
    float4 viewPos = getViewPosFromDepth( screenPos );
    return mul( cInvView, viewPos );
}

inline float3 getNormal( Texture2D t, SamplerState s, float2 uv )
{
    return decodeNormal( t.Sample(s, uv).xyz );
}

PS_OUTPUT mainFP( VS_OUTPUT In ) 
{
    PS_OUTPUT output;

#if USE_FRESNEL
    float3 worldPos = getWorldPosFromDepth( In.TexCoord ).xyz;
    float3 worldNormal = getNormal( tNormalTex, sNormalTex, In.TexCoord );
    float3 worldEyeDir = normalize( cCameraWorldPos - worldPos.xyz );
    float fresnel = saturate( cFresnelBias + cFresnelScale * pow( 1.0f + dot( worldEyeDir, worldNormal ), cFresnelPower ) );
    float4 outlinColor = float4( lerp( cOutlineColor.xyz / 5.0f, cOutlineColor.xyz, fresnel ), max( fresnel, 0.6f ) );  
#else
    float4 outlinColor = float4( cOutlineColor.xyz, 0.5f );
#endif

    float4 noise = tNoise.Sample( sNoise, In.TexCoord * 7 );
    outlinColor += ( noise * 0.5 );
    output.Color0 = outlinColor; 
    return output;
}