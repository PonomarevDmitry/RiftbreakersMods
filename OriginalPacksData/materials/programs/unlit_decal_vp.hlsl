cbuffer VPConstantBuffer : register(b0)
{
    matrix  cWorldViewProj;
};

struct VS_INPUT
{
    float4  Position    : POSITION;
    float2  TexCoord    : TEXCOORD0;
};

struct VS_OUTPUT
{
    float4  Position    : SV_POSITION;
    float4  ProjPos     : TEXCOORD0;
    float2  TexCoord    : TEXCOORD1;
};

VS_OUTPUT mainVP( VS_INPUT In )
{
    VS_OUTPUT Out;

    Out.Position = mul( cWorldViewProj, In.Position );
    Out.ProjPos = Out.Position;
    Out.TexCoord = In.TexCoord;
    
    return Out;
}