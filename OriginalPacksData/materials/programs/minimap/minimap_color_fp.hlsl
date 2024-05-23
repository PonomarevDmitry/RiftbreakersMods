cbuffer PSConstantBuffer : register(b0)
{
    float4 cColor;
#if USE_WORLD_TEXTURE
    float       cTilingFactor;
    float3      cWorldCameraPos;
#endif
}

struct VS_OUTPUT
{
    float4      Position    : SV_POSITION;
    float2      TexCoord    : TEXCOORD0;
#if USE_WORLD_TEXTURE
    float4      WorldPos    : TEXCOORD1;
#endif
};

struct PS_OUTPUT
{
    float4      Color0      : SV_TARGET;
};

#if USE_WORLD_TEXTURE
Texture2D       tAlbedo1Tex;
SamplerState    sAlbedo1Tex;
#endif

PS_OUTPUT mainFP( VS_OUTPUT In ) 
{
    PS_OUTPUT Out;
#if USE_WORLD_TEXTURE
    float3 worldPos = In.WorldPos.xyz;// - cWorldCameraPos;
    Out.Color0 = tAlbedo1Tex.Sample(sAlbedo1Tex, float2( worldPos.z / cTilingFactor, -worldPos.x / cTilingFactor )) * cColor;
#else
    Out.Color0 = cColor;
#endif
    return Out;
}