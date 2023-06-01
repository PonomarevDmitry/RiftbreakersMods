#include "materials/programs/utils.hlsl"

cbuffer FPConstantBuffer : register(b0)
{  
    float4    cEmissiveColor;
    float4    cFresnelColor;
    float     cFresnelBias;
    float     cFresnelScale;
    float     cFresnelPower;
    float     cGlowAmount;
    float     cShield;
    float     cAlpha;
};

struct VS_OUTPUT
{
    float4 Position       : SV_POSITION;
    float2 TexCoord       : TEXCOORD0;
    float3 WorldNormal    : TEXCOORD1;
    float3 WorldEyeDir    : TEXCOORD2;
};

Texture2D       tColorTex;
SamplerState    sColorTex;
Texture2D       tEmissiveTex; 
SamplerState    sEmissiveTex; 
Texture2D       tGradientTex;
SamplerState    sGradientTex;
Texture2D       tDamageTex;
SamplerState    sDamageTex;

float4 mainFP( VS_OUTPUT In ) : SV_TARGET
{
    float shield = max( 0.7, cShield );
    float4 color = texLinear2D( tColorTex, sColorTex, In.TexCoord );

    float dotProduct = dot( In.WorldEyeDir, In.WorldNormal );
    float fresnel = cFresnelBias + cFresnelScale * pow( 1 + dotProduct, cFresnelPower );
    color.xyz = lerp( color.xyz, cFresnelColor.xyz, saturate( fresnel ) );
    color.a *= shield;
    
    float emissivePower = lerp( tEmissiveTex.Sample( sEmissiveTex, In.TexCoord ).x * max( 0.5, tGradientTex.Sample( sGradientTex, In.TexCoord ).x ), tDamageTex.Sample( sDamageTex, In.TexCoord ).x, saturate( cShield ) );
    float3 emissiveColor = cEmissiveColor.rgb;
    emissiveColor += cEmissiveColor.a * emissivePower * emissivePower;
    emissiveColor *= cGlowAmount * emissivePower;
    color.xyz = lerp( color.xyz, emissiveColor, emissivePower );
    
    color.a *= cAlpha;

    return color;
}


