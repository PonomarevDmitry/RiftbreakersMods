cbuffer FPConstantBuffer : register(b0)
{
    float     	cGlowAmount;
    float4    	cEmissiveColor;
    float3      cBaseColor;
    float 	  	cDiscardThreshold;
    float 		cAlpha;
    float 		cDissolveAmount;
    float       cFresnelScale;
    float       cFresnelPower;
    float4      cFresnelColor;
    float3      cWorldCameraPos;
#if USE_FOG
    float     cFogMaxDistance;
#endif
};

struct VS_OUTPUT
{
    float4 Position         : SV_POSITION;
    float4 TexCoord         : TEXCOORD0; 
    float3 Normal           : TEXCOORD1;
    float  Alpha 			: TEXCOORD2;
    float3 WorldPos         : TEXCOORD3;
    float4 ProjPos          : TEXCOORD4;
};

struct PS_OUTPUT
{
    float4      Color       : SV_TARGET0;
#if USE_UPSCALE_MASK
    float       UpscaleMask : SV_TARGET1;
#endif
};

Texture2D       tEmissiveTex;	
SamplerState    sEmissiveTex;   

Texture2D       tGradientTex;	
SamplerState    sGradientTex;	

#if USE_FOG
Texture3D       tLightScattering;
SamplerState    sLightScattering;
#endif

#include "materials/programs/utils.hlsl"
#include "materials/programs/utils_fog.hlsl"

PS_OUTPUT mainFP( VS_OUTPUT In ) 
{
    PS_OUTPUT Out;
	
    float fresnel = calcFresnel( 0.0f, cFresnelScale, cFresnelPower, normalize( In.WorldPos - cWorldCameraPos ), In.Normal );

    float alpha = cAlpha * saturate( In.Alpha ) * saturate( 1.0 - cDissolveAmount );
	float emmisive =  tEmissiveTex.Sample( sEmissiveTex, In.TexCoord.xy ).x;

	float gradient = tGradientTex.Sample( sGradientTex, In.TexCoord.zw / 4.0 ).x;
    float emissivePower = emmisive * gradient * alpha;
	float3 emissiveColor = cEmissiveColor.rgb;
	emissiveColor += cEmissiveColor.a * emissivePower * emissivePower;
	emissiveColor *= emissivePower * cGlowAmount;
	Out.Color.xyz = lerp( cBaseColor, emissiveColor, saturate( emissivePower ) );

    Out.Color.xyz = lerp( Out.Color.xyz, cFresnelColor.xyz, fresnel );
    Out.Color.w = saturate( alpha * saturate( 1.0f - gradient ) );

	clip ( emmisive > cDiscardThreshold ? 1:-1 );

#if USE_FOG
    Out.Color.xyz = GetFog( Out.Color.xyz, In.ProjPos );
#endif

#if USE_UPSCALE_MASK
    Out.UpscaleMask = 0.0f;
#endif

    return Out;
}


