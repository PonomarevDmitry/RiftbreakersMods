cbuffer FPConstantBuffer : register(b0)
{
    float4    cEmissiveColor1;
    float4    cEmissiveColor2;
    float     cGlowAmount;
    float     cGlowFactor;
    float     cTime;
#if USE_FOG
    float4    cFogParams;
    float4    cFogColor;
#endif
};

struct VS_OUTPUT
{
    float4    Position         : SV_POSITION;
    float2    TexCoord         : TEXCOORD0;
#if USE_FOG
    float4    ProjPos          : TEXCOORD4;
#endif
};

struct PS_OUTPUT
{
    float4    Color            : SV_TARGET0;
#if USE_UPSCALE_MASK
    float     UpscaleMask      : SV_TARGET1;
#endif
};

Texture2D     tSlashTex;
SamplerState  sSlashTex;
Texture2D     tNoiseTex;
SamplerState  sNoiseTex;
Texture2D     tGradientTex;
SamplerState  sGradientTex;
#if USE_FOG
Texture3D     tLightScattering;
SamplerState  sLightScattering;
#endif

#include "materials/programs/utils.hlsl"
#include "materials/programs/utils_fog.hlsl"

PS_OUTPUT mainFP( VS_OUTPUT In ) 
{
    PS_OUTPUT Out;

    float2 texCoord = float2( In.TexCoord.x, 1.0f + In.TexCoord.y );
    float2 uv = texCoord + float2( 0, 0.7 ) - float2( 0, 1.5 ) * cTime;

    float slash = tSlashTex.Sample( sSlashTex, uv ).x;
    float3 color = lerp( cEmissiveColor1.xyz, cEmissiveColor2.xyz, slash ) * cGlowAmount * cGlowFactor; 

    color *= max( saturate( texCoord.y * 0.0f ), tNoiseTex.Sample( sNoiseTex, uv ).x * tGradientTex.Sample( sGradientTex, uv ).x);
    slash *= max( saturate( texCoord.y * 2.0f ), tNoiseTex.Sample( sNoiseTex, uv ).x * tGradientTex.Sample( sGradientTex, uv ).x);
    slash *= ( 1.0f - pow( length( ( texCoord.x * 2.0 ) - 1.0 ), 10.0f ) );
    slash *= ( texCoord.y < 0.1 ) ? texCoord.y / 0.1 : 1.0f;

    Out.Color = float4( color.xyz, slash );

#if USE_FOG
    Out.Color.xyz = GetFog( Out.Color.xyz, In.ProjPos );
#endif

#if USE_UPSCALE_MASK
    Out.UpscaleMask = 0.5f * Out.Color.a;
#endif

    return Out;
}


