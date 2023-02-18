struct VS_OUTPUT
{
    float4  Position    : SV_POSITION;
    float2  TexCoord    : TEXCOORD0;
};

struct PS_OUTPUT
{
    float4  Color0      : SV_TARGET0;
};

Texture2D       tOcclusion         : register( t0 );
SamplerState    sOcclusion         : register( s0 );

PS_OUTPUT mainFP( VS_OUTPUT In ) 
{
    PS_OUTPUT output;
    output.Color0.xyz = saturate( ( tOcclusion.Sample( sOcclusion, In.TexCoord ).x ) );
    return output;
}
