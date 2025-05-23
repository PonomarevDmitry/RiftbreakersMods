#include "materials/programs/utils.hlsl"

cbuffer FPConstantBuffer : register(b0)
{
#if USE_GRADIENT_MAP
    float4    cEmissiveColor;
#endif
#if USE_FRESNEL
    float4    cFresnelColor;
    float     cFresnelBias;
    float     cFresnelScale;
    float     cFresnelPower;
#endif
    float     cGlowAmount;
    float     cGlowFactor;
};

struct VS_OUTPUT
{
    float4    Position         : SV_POSITION;
    float2    TexCoord         : TEXCOORD0;
#if USE_FRESNEL
    float3    WorldNormal      : TEXCOORD2;
    float3    WorldEyeDir      : TEXCOORD3;
#endif
};

struct PS_OUTPUT
{
    float4    Color            : SV_TARGET0;
#if USE_UPSCALE_MASK
    float     UpscaleMask      : SV_TARGET1;
#endif
};

Texture2D     tColorTex;
SamplerState  sColorTex;
#if USE_EMISSIVE_MAP
Texture2D     tEmissiveTex;
SamplerState  sEmissiveTex;
#endif
#if USE_GRADIENT_MAP
Texture2D     tGradientTex;
SamplerState  sGradientTex;
#endif
#if USE_ALPHA_MAP
Texture2D     tAlphaTex;
SamplerState  sAlphaTex;
#endif

PS_OUTPUT mainFP( VS_OUTPUT In ) 
{
    PS_OUTPUT Out;

    float4 color = texLinear2D( tColorTex, sColorTex, In.TexCoord );

#if USE_FRESNEL
    float fresnel = cFresnelBias + cFresnelScale * pow( 1 + dot( In.WorldEyeDir.xyz, In.WorldNormal ), cFresnelPower );
    #if USE_FRESNEL_INVERT
        color.xyz = lerp( color.xyz, cFresnelColor.xyz, saturate( fresnel ) );
    #else
        color.xyz = lerp( cFresnelColor.xyz, color.xyz, saturate( fresnel ) );
    #endif
#endif

#if USE_EMISSIVE_MAP && USE_GRADIENT_MAP
    float emissivePower = tEmissiveTex.Sample( sEmissiveTex, In.TexCoord ).x * tGradientTex.Sample( sGradientTex, In.TexCoord ).x;
    float3 emissiveColor = cEmissiveColor.rgb;
    emissiveColor += cEmissiveColor.a * emissivePower * emissivePower;
    emissiveColor *= cGlowAmount * cGlowFactor * emissivePower;
    color.xyz = lerp( color.xyz, emissiveColor, emissivePower );
#elif USE_EMISSIVE_MAP
    float emissivePower = tEmissiveTex.Sample( sEmissiveTex, In.TexCoord ).x;
    float3 emissiveColor = color.xyz * ( cGlowAmount * cGlowFactor * emissivePower );
    color.xyz = lerp( color.xyz, emissiveColor, emissivePower );
#endif

#if USE_ALPHA_MAP
    color.a *= tAlphaTex.Sample( sAlphaTex, In.TexCoord ).x;
#endif
    Out.Color = color;

#if USE_UPSCALE_MASK
    Out.UpscaleMask = 0.5f * Out.Color.a;
#endif

    return Out;
}


