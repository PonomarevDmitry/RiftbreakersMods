cbuffer FPConstantBuffer : register(b0)
{
    float4    cEmissiveColor;
    float4    cFogParams;
    float4    cFogColor;
    float4    cFresnelColor;
    float     cFresnelBias;
    float     cFresnelScale;
    float     cFresnelPower;
    float     cGlowAmount;
    float     cGlowFactor;
    float     cTime;
};

struct VS_OUTPUT
{
    float4 Position         : SV_POSITION;
    float2 TexCoord         : TEXCOORD0;
    float3 WorldNormal      : TEXCOORD2;
    float3 WorldEyeDir      : TEXCOORD3;
    float4 ProjPos          : TEXCOORD4;
    float3 WorldPos         : TEXCOORD5;
};

struct PS_OUTPUT
{
    float4      Color       : SV_TARGET0;
};

Texture2D       tColorTex;
SamplerState    sColorTex;
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

    float4 color = texLinear2D( tColorTex, sColorTex, In.TexCoord );
    
    float fresnel = cFresnelBias + cFresnelScale * pow( 1 + dot( In.WorldEyeDir, In.WorldNormal ), cFresnelPower );
#if USE_FRESNEL_INVERT
    color.xyz = lerp( color.xyz, cFresnelColor.xyz, saturate( fresnel ) );
#else
    color.xyz = lerp( cFresnelColor.xyz, color.xyz, saturate( fresnel ) );
#endif   

    float2 gradientUV = In.TexCoord.xy;
    gradientUV.y += In.WorldPos.x + In.WorldPos.z;
    gradientUV.y += cTime * 0.25f;
    gradientUV /= 4.0f;
    float gradient = tGradientTex.Sample( sGradientTex, gradientUV ).x;
    gradient = max( 0.2, min( 0.8f, gradient ) );
    float alphaGradient = tGradientTex.Sample( sGradientTex, In.TexCoord ).x;

    float emissivePower = tEmissiveTex.Sample( sEmissiveTex, In.TexCoord ).x * gradient;
    float3 emissiveColor = cEmissiveColor.rgb;
    emissiveColor += cEmissiveColor.a * emissivePower * emissivePower;
    emissiveColor *= cGlowAmount * cGlowFactor * emissivePower;
    color.xyz = lerp( color.xyz, emissiveColor, emissivePower );

    Out.Color = color;
    Out.Color.a = max( 0.0f, Out.Color.a - 0.5f * Out.Color.a * alphaGradient );

#if USE_FOG
    Out.Color.xyz = GetFog( Out.Color.xyz, In.ProjPos );
#endif

    return Out;
}


