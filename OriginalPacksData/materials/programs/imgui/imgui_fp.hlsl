struct VS_OUTPUT
{
    float4 Position : SV_POSITION;
    float4 Color    : COLOR0;
    float2 TexCoord : TEXCOORD0;
};

Texture2D       tAlbedoTex;
SamplerState    sAlbedoTex;

float4 mainFP(VS_OUTPUT In) : SV_Target
{
    return In.Color * tAlbedoTex.Sample(sAlbedoTex, In.TexCoord);
};