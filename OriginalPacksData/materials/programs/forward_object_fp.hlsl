#if USE_FOG || USE_PARTICLE_EMISSIVE || USE_FRESNEL
cbuffer FPConstantBuffer : register(b0)
{
#if USE_FRESNEL
    float4    cFresnelParams;  // x - power, y - scale, z - bias
    float4    cFresnelColor;
#endif
#if USE_PARTICLE_EMISSIVE
    float     cGlowAmount;
    float     cGlowFactor;
#endif
#if USE_FOG
    float     cFogMaxDistance;
#endif
};
#endif

struct VS_OUTPUT
{
    float4    Position         : SV_POSITION;
#if USE_TEXTURE 
    float2    TexCoord         : TEXCOORD0;
#endif
#if USE_COLOR || USE_PARTICLE || USE_PARTICLE_EMISSIVE
    float4    Color            : TEXCOORD1;
#endif
#if USE_FRESNEL
    float3    WorldNormal      : TEXCOORD2;
    float3    WorldEyeDir      : TEXCOORD3;
#endif
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

#if USE_TEXTURE 
Texture2D     tColorTex;
SamplerState  sColorTex;
#endif
#if USE_PARTICLE_EMISSIVE
Texture2D     tEmissiveTex;
SamplerState  sEmissiveTex;
#endif
#if USE_FOG
Texture3D     tLightScattering;
SamplerState  sLightScattering;
#endif

#include "materials/programs/utils.hlsl"
#include "materials/programs/utils_fog.hlsl"

PS_OUTPUT mainFP( VS_OUTPUT In ) 
{
    PS_OUTPUT Out;

#if USE_TEXTURE
    Out.Color = texLinear2D( tColorTex, sColorTex, In.TexCoord );
#elif USE_FRESNEL
    float dotProduct = dot( In.WorldEyeDir, In.WorldNormal );
    float fresnel = cFresnelParams.z + cFresnelParams.y * pow( 1 + dotProduct, cFresnelParams.x );
    Out.Color = lerp( float4( 0.0f, 0.0f, 0.0f, 0.0f ), cFresnelColor, abs( ( cFresnelParams.w * 1.0f ) - saturate( fresnel ) ) );
    Out.Color.w = saturate( Out.Color.w );
#else
    Out.Color = float4( 1.0f, 1.0f, 1.0f, 1.0f );
#endif

#if USE_PARTICLE_EMISSIVE
    float emissiveMask = tEmissiveTex.Sample( sEmissiveTex, In.TexCoord ).x * In.Color.x;
    float3 emissiveColor = Out.Color.xyz * ( cGlowAmount * cGlowFactor * emissiveMask * In.Color.a );
    Out.Color.xyz = lerp( Out.Color.xyz, emissiveColor, emissiveMask );
    Out.Color.w *= In.Color.a;
#elif USE_PARTICLE
    Out.Color *= In.Color;
#elif USE_COLOR
    Out.Color *= In.Color;
#endif

#if USE_FOG
    Out.Color.xyz = GetFog( Out.Color.xyz, In.ProjPos );
#endif

#if USE_UPSCALE_MASK && USE_FOG
    Out.UpscaleMask = 0.5f * Out.Color.a;
#elif USE_UPSCALE_MASK
    Out.UpscaleMask = 0.5f * ( Out.Color.x + Out.Color.y + Out.Color.z ) / 3.0f;
#endif

    return Out;
}
