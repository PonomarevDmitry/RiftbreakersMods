#if USE_BLEND_2_TEXTURE
cbuffer FPConstantBuffer : register(b0)
{
    float   cChange;
};
#endif

struct VS_OUTPUT
{
    float4  Position    : SV_POSITION;
    float4  Color       : COLOR;
#if USE_TEXTURE || USE_BLEND_2_TEXTURE
    float2  TexCoord    : TEXCOORD0;
#endif
};

struct PS_OUTPUT
{
    float4  Color       : SV_TARGET;
};

#if USE_TEXTURE
    Texture2D       tTex0       : register( t0 );
    SamplerState    sTex0       : register( s0 );
#elif USE_BLEND_2_TEXTURE
    Texture2D       tTex0       : register( t0 );
    SamplerState    sTex0       : register( s0 );
    Texture2D       tTex1       : register( t1 );
    SamplerState    sTex1       : register( s1 );
#endif


PS_OUTPUT mainFP( VS_OUTPUT In ) 
{
    PS_OUTPUT Out;

    Out.Color = tTex0.SampleLevel( sTex0, In.TexCoord, 0 ) * In.Color;
	Out.Color.rgb = 0.299 * Out.Color.r + 0.587 * Out.Color.g + 0.114 * Out.Color.b;
	Out.Color.a = Out.Color.a;
    return Out;
}
