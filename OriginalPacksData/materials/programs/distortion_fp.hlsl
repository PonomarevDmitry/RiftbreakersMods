#include "materials/programs/utils.hlsl"

cbuffer FPConstantBuffer : register(b0)
{       
	float  	cDistortionPower;
	float 	cViewportWidth;
	float 	cViewportHeight;
#if USE_TIMER
    float   cTimer;
    float2  cNoiseParams;
#endif
#if USE_FRESNEL
    float   cFresnelBias;
    float   cFresnelScale;
    float   cFresnelPower;
#endif
#if USE_DISSOLVE || USE_INVERTED_DISSOLVE
    float   cDissolveAmount;
#endif
};

struct VS_OUTPUT
{
    float4  Position    : SV_POSITION;
    float2  TexCoord    : TEXCOORD0;
#if USE_COLOR
    float4  Color       : TEXCOORD1;
#endif
#if USE_FRESNEL
    float3 WorldEyeDir  : TEXCOORD2;
    float3 WorldNormal  : TEXCOORD3;
#endif
};

struct PS_OUTPUT
{
    float4  Color       : SV_TARGET;
};

Texture2D       tDistortion  : register( t0 );
SamplerState    sDistortion  : register( s0 );

PS_OUTPUT mainFP( VS_OUTPUT In ) 
{
    PS_OUTPUT Out;

#if USE_FRESNEL
    float fresnel = calcFresnel( cFresnelBias, cFresnelScale, cFresnelPower, In.WorldEyeDir, In.WorldNormal );
#endif

#if USE_TIMER
    float2 distortion = tDistortion.Sample( sDistortion, In.TexCoord + cTimer * cNoiseParams ).xy;
#else
    float2 distortion = tDistortion.Sample( sDistortion, In.TexCoord ).xy;
#endif

    distortion.xy = ( distortion.xy - 0.5 ) * 2.0;
    distortion.xy *= cDistortionPower;
    distortion.x *= cViewportHeight / cViewportWidth;
#if USE_FRESNEL
    distortion.xy *= fresnel;
#endif
#if USE_INVERTED_DISSOLVE
    distortion.xy *= saturate( cDissolveAmount );
#elif USE_DISSOLVE
    distortion.xy *= saturate( 1.0f - cDissolveAmount );
#endif

#if USE_COLOR
	Out.Color = float4( distortion * In.Color.w, 0, In.Color.w );
#else
	Out.Color = float4( distortion, 0, 1 );
#endif
 
    return Out;
}