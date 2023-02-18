cbuffer PSConstantBuffer : register(b0)
{
    float cAlpha;
}

struct GS_OUTPUT
{
    float4 Position    : SV_POSITION;
    float4 WorldPos    : TEXCOORD1;
};

struct PS_OUTPUT
{
    float4 Color        : SV_TARGET;
};

Texture2D       tTex          : register( t0 );
SamplerState    sTex          : register( s0 );

PS_OUTPUT mainFP( GS_OUTPUT In ) 
{
	PS_OUTPUT Out;

    float4 color = tTex.Sample( sTex, In.WorldPos.xz / 70 );
    Out.Color = float4( color.xyz * color.a, 1.0 );
    return Out;
}
