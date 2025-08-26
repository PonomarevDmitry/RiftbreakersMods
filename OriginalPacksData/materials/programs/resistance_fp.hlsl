#include "materials/programs/utils.hlsl"

cbuffer FPConstantBuffer : register(b0)
{
    float4    cResistanceInnerColor;
    float4    cResistanceOuterColor;
    float     cResistanceFresnelBias;
    float     cResistanceFresnelScale;
    float     cResistanceFresnelPower;
#if USE_FLARE
    float     cTime;     
    float     cFlarePower;
    float     cFlareSpeed;
#endif
#if USE_PROGRESS
    float     cProgress;
#endif 
};

struct VS_OUTPUT
{
    float4 Position       : SV_POSITION;
    float2 TexCoord       : TEXCOORD0;
    float3 WorldNormal    : TEXCOORD1;
    float3 WorldEyeDir    : TEXCOORD2;
    float4 ProjPos        : TEXCOORD5;
};

struct PS_OUTPUT
{
    float4      Color       : SV_TARGET0;
};

#if USE_ALPHA_TEST
Texture2D       tAlbedoTex;
SamplerState    sAlbedoTex;
#endif

PS_OUTPUT mainFP( VS_OUTPUT In ) 
{
    PS_OUTPUT Out;

#if USE_ALPHA_TEST
    float alpha = tAlbedoTex.Sample( sAlbedoTex, In.TexCoord ).w;
    clip( alpha > 0.25 ? 1 : -1 );
#endif

    float3 normal = In.WorldNormal.xyz;

#if USE_FLARE && USE_PROGRESS
    float resistanceFresnelPower = cResistanceFresnelPower + sin( cTime * cFlareSpeed * cProgress ) * cFlarePower;
#elif USE_FLARE
    float resistanceFresnelPower = cResistanceFresnelPower + sin( cTime * cFlareSpeed ) * cFlarePower;
#else
    float resistanceFresnelPower = cResistanceFresnelPower;
#endif

    float fresnel = calcFresnel( cResistanceFresnelBias, cResistanceFresnelScale, resistanceFresnelPower, In.WorldEyeDir, normal );
    Out.Color = lerp( cResistanceInnerColor, cResistanceOuterColor, saturate( fresnel ) );
    Out.Color.w = saturate( Out.Color.w );

    return Out;
}


