cbuffer FPConstantBuffer : register(b0)
{
#if USE_UNIFORM
	float4  cUniformColor;
#endif
    float   cGlowAmount;
    float   cAlpha;
#if USE_TEXTURE
    float   cUniformAlpha;
#endif
#if USE_FOG
    float   cFogMaxDistance;
#endif
};

struct VS_OUTPUT
{
    float4  Position    : SV_POSITION;
    float4  TexCoord    : TEXCOORD0; // xy(uv), z(v-tiled), w(alpha)
    float3  WorldPos    : TEXCOORD1;
    float4  ProjPos     : TEXCOORD2;
};

struct PS_OUTPUT
{
    float4      Color       : SV_TARGET0;
};

#if USE_TEXTURE
Texture2D       tTex;
SamplerState    sTex;
#endif
#if USE_NOISE
Texture2D       tNoise;
SamplerState    sNoise;
#endif
#if USE_FOG
Texture3D       tLightScattering;
SamplerState    sLightScattering;
#endif

#include "materials/programs/utils.hlsl"
#include "materials/programs/utils_fog.hlsl"

PS_OUTPUT mainFP( VS_OUTPUT In ) 
{
    PS_OUTPUT Out;

#if USE_TEXTURE
    Out.Color = tTex.Sample( sTex, In.TexCoord );
#elif USE_UNIFORM
    Out.Color = cUniformColor;
#else
    Out.Color = float4( 1.0f, 1.0f, 1.0f, 1.0f );
#endif

    Out.Color.xyz *= cGlowAmount;
    Out.Color.w *= In.TexCoord.w * cAlpha;

#if USE_NOISE
    Out.Color *= min( 0.6f, tNoise.Sample( sNoise, In.TexCoord ).x );
#endif

#if USE_SOFT_EDGE
    Out.Color.xyzw *= sin( In.TexCoord.x * 3.14f );
#endif

#if USE_SOFT_TRIANGLE
    Out.Color.w *= In.TexCoord.x * In.TexCoord.z * In.TexCoord.z;
#endif

#if USE_FOG
    Out.Color.xyz = GetFog( Out.Color.xyz, In.ProjPos );
#endif

    return Out;
}
