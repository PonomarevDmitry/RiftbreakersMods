#include "materials/programs/utils.hlsl"

cbuffer FPConstantBuffer : register(b0)
{  
    float4    cEmissiveColor;
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

Texture2D       tColorTex           : register( t0 );
SamplerState    sColorTex           : register( s0 );
Texture2D       tEmissiveTex        : register( t1 );
SamplerState    sEmissiveTex        : register( s1 );
Texture2D       tGradientTex        : register( t2 );
SamplerState    sGradientTex        : register( s2 );
Texture2D       tDamageTex          : register( t3 );
SamplerState    sDamageTex          : register( s3 );

float4 mainFP( VS_OUTPUT In ) : SV_TARGET
{
    float shield = max( 0.7, cShield );
    float4 color = texLinear2D( tColorTex, sColorTex, In.TexCoord );

    float dotProduct = dot( In.WorldEyeDir, In.WorldNormal );
    color.a *= shield;
    
    float emissivePower = lerp( tEmissiveTex.Sample( sEmissiveTex, In.TexCoord ).x * max( 0.5, tGradientTex.Sample( sGradientTex, In.TexCoord ).x ), tDamageTex.Sample( sDamageTex, In.TexCoord ).x, saturate( cShield ) );
    float3 emissiveColor = cEmissiveColor.rgb;
    emissiveColor += cEmissiveColor.a * emissivePower * emissivePower;
    emissiveColor *= cGlowAmount * emissivePower;
    color.xyz = lerp( color.xyz, emissiveColor, emissivePower );

    float fresnel = saturate( cFresnelBias + cFresnelScale * pow( 1 + dotProduct, cFresnelPower ) );
    color *= fresnel;
    
    color.a *= cAlpha;

    return color;
}


