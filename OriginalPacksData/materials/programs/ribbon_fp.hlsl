#include "materials/programs/utils.hlsl"

cbuffer FPConstantBuffer : register(b0)
{
    float4  cFogParams;
    float4  cFogColour;
#if USE_UNIFORM
	float4  cUniformColor;
#endif
#if USE_TEXTURE
    float   cUniformAlpha;
#endif
    float   cGlowAmount;
    float   cAlpha;
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

    addFog( Out.Color.xyz, cFogColour.xyz, In.ProjPos.w, cFogParams );
    return Out;
}
