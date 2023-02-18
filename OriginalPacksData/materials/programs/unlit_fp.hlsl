#include "materials/programs/utils.hlsl"

#if USE_ENVIRONMENT || USE_FOG || USE_2_TEXTURE
cbuffer FPConstantBuffer : register(b0)
{
#if USE_ENVIRONMENT
    float4  cWorldCameraPos;
#endif
#if USE_FOG
    float4  cFogParams;
    float4  cFogColour;
#endif
#if USE_2_TEXTURE
    float   cChange;
#endif
};
#endif

struct VS_OUTPUT
{
    float4  Position          : SV_POSITION;
#if USE_TEXTURE || USE_2_TEXTURE
    float2  TexCoord          : TEXCOORD0;
#endif
#if USE_COLOR || USE_UNIFORM
    float4  Color             : TEXCOORD1;
#endif
#if USE_ENVIRONMENT
    float3  WorldPos          : TEXCOORD2;
    float3  WorldNor          : TEXCOORD3;
#endif
#if USE_FOG
    float4  ProjPos           : TEXCOORD4;
#endif
};

struct PS_OUTPUT
{
    float4      Color         : SV_TARGET0;
#if USE_UPSCALE_MASK
    float       UpscaleMask   : SV_TARGET1;
#endif
};

#if USE_TEXTURE 
Texture2D       tTex          : register( t0 );
SamplerState    sTex          : register( s0 );
#elif USE_2_TEXTURE
Texture2D       tTex0         : register( t0 );
SamplerState    sTex0         : register( s0 );
Texture2D       tTex1         : register( t1 );
SamplerState    sTex1         : register( s1 );
#elif USE_ENVIRONMENT
TextureCube     tSkyBox       : register( t0 );
SamplerState    sSkyBox       : register( s0 );
#endif

PS_OUTPUT mainFP( VS_OUTPUT In ) 
{
    PS_OUTPUT Out;
#if USE_COLOR || USE_UNIFORM
    #if USE_TEXTURE
        Out.Color = texLinear2D( tTex, sTex, In.TexCoord ) * In.Color;
    #else
        Out.Color = In.Color;
    #endif
#elif USE_ENVIRONMENT
    float3 viewDir = normalize( In.WorldPos - cWorldCameraPos.xyz );
    float3 reflectedDir = refract( viewDir, In.WorldNor, 1.0f );
    Out.Color = tSkyBox.Sample( sSkyBox, reflectedDir );
#else
    #if USE_2_TEXTURE
        float4 color1 = texLinear2D( tTex0, sTex0, In.TexCoord );
        float4 color2 = texLinear2D( tTex1, sTex1, In.TexCoord );
        Out.Color = lerp( color2, color1, ( 1.0 + cChange ) / 2.0 );
    #elif USE_TEXTURE
        Out.Color = tTex.Sample( sTex, In.TexCoord );
    #else
        Out.Color = float4( 1.0f, 1.0f, 1.0f, 1.0 );
    #endif
#endif

#if USE_FOG
    addFog( Out.Color.xyz, cFogColour.xyz, In.ProjPos.w, cFogParams );
#endif

#if USE_SRGB
    Out.Color.xyz = SRGBToLinear( Out.Color.xyz );
#endif

#if USE_UPSCALE_MASK && USE_FOG
    Out.UpscaleMask = 0.5f * Out.Color.a;
#elif USE_UPSCALE_MASK
    Out.UpscaleMask = 0.5f * ( Out.Color.x + Out.Color.y + Out.Color.z ) / 3.0f;
#endif

    return Out;
}
