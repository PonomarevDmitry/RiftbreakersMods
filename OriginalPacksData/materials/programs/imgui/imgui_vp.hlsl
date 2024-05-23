cbuffer VPConstantBuffer
{
    float4x4 cProjMatrix;
};

struct VS_INPUT
{
    float2 Position : POSITION;
    float4 Color    : COLOR0;
    float2 TexCoord : TEXCOORD0;
};

struct VS_OUTPUT
{
    float4 Position : SV_POSITION;
    float4 Color    : COLOR0;
    float2 TexCoord : TEXCOORD0;
};

VS_OUTPUT mainVP(VS_INPUT In)
{
    VS_OUTPUT Out;
    Out.Position = mul( cProjMatrix, float4( In.Position.xy, -1.f, 1.f ) );
    Out.Color = In.Color;
    Out.TexCoord  = In.TexCoord;
    return Out;
};