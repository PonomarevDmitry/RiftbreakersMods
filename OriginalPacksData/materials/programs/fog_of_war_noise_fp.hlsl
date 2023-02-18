struct VS_OUTPUT
{
    float4      Position    : SV_POSITION;
    float2      TexCoord    : TEXCOORD0;
};

struct PS_OUTPUT
{
    float4      Color0      : SV_TARGET;
};

Texture2D       tTex0       : register( t0 );
SamplerState    sTex0       : register( s0 );

cbuffer FPConstantBuffer : register(b0)
{
    float4    	cViewportSize;
    float4 	  	cTextureSize;
}

PS_OUTPUT mainFP( VS_OUTPUT In ) 
{
    PS_OUTPUT Out;
    Out.Color0 = tTex0.Sample( sTex0, In.TexCoord * ( cViewportSize.xy / cTextureSize.xy ) * 2.0f );
    return Out;
}
