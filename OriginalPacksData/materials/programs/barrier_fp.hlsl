#include "materials/programs/utils.hlsl"

cbuffer FPConstantBuffer : register(b0)
{
    float     cBarrier;
	float 	  cTime;
    float     cGlowAmount;
    float4    cEmissiveColor;
};

struct VS_OUTPUT
{
    float4 Position       : SV_POSITION;
    float2 TexCoord       : TEXCOORD0;
    float3 WorldNormal    : TEXCOORD1;
    float3 WorldEyeDir    : TEXCOORD2;
};

struct PS_OUTPUT
{
    float4      Color       : SV_TARGET0;
};

Texture2D       tEmissiveTex;	
SamplerState    sEmissiveTex;   

Texture2D       tGradientTex;	
SamplerState    sGradientTex;	

PS_OUTPUT mainFP( VS_OUTPUT In ) 
{
    PS_OUTPUT Out;
	
	float fresnelBias = 0.f;
	float fresnelScale = 1.0f;
	float fresnelPower = 5.f;
	float4 blendColor1 = float4(0.0, 0.5, 1.0, 0.1);
    float4 blendColor2 = float4(0.0, 0.6, 6.0, 4.0);
    float glowFactor = 1.f;
	
	float sCBarrier = saturate(cBarrier);
	blendColor1.xyzw *= sCBarrier;
	
	fresnelPower -= sCBarrier * 3.0;
    float3 normal = In.WorldNormal.xyz;

    float fresnel = calcFresnel( fresnelBias, fresnelScale, fresnelPower, In.WorldEyeDir, normal );
	
    Out.Color = lerp( blendColor1, blendColor2, saturate( fresnel ) );
    Out.Color.w = saturate( Out.Color.w );
	float emmisive =  tEmissiveTex.Sample( sEmissiveTex, In.TexCoord ).x;
	float gradient = tGradientTex.Sample( sGradientTex, In.TexCoord ).x;
    float emissivePower = emmisive * gradient * glowFactor;
	
	float3 emissiveColor = cEmissiveColor.rgb;
	emissiveColor += cEmissiveColor.a * emissivePower * emissivePower;
	emissiveColor *= emissivePower * cGlowAmount;
	Out.Color.xyz = lerp( Out.Color.xyz, emissiveColor, saturate(emissivePower) );
	
	Out.Color.xyzw *= cBarrier * 1.5f;
    Out.Color.w = saturate( Out.Color.w );
    return Out;
}


