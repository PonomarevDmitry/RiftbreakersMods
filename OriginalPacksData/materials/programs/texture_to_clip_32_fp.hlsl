struct VS_OUTPUT
{
    float4      Position    : SV_POSITION;
    float2      TexCoord    : TEXCOORD0;
};

#if __PSSL__
#pragma PSSL_target_output_format(target 0 FMT_32_ABGR)
#endif

struct PS_OUTPUT
{
    float4      Color0      : SV_TARGET;
};

Texture2D       tTex0       : register( t0 );
SamplerState    sTex0       : register( s0 );

PS_OUTPUT mainFP( VS_OUTPUT In )
{
    PS_OUTPUT Out;
    Out.Color0 = tTex0.Sample( sTex0, In.TexCoord );
    return Out;
}
