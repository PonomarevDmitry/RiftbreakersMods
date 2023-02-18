cbuffer VPConstantBuffer : register(b0)
{
    matrix  cWorldViewProj;
    matrix  cWorld;
};

struct VS_INPUT
{
    float3  Position        : POSITION;    
    float3  TexCoord        : TEXCOORD0;
    float3  IconTexCoord    : TEXCOORD1;

};

struct VS_OUTPUT
{
    float4  Position        : SV_POSITION;
    float3  TexCoord        : TEXCOORD0;
    float3  IconTexCoord    : TEXCOORD1;
    float4  WorldPos        : TEXCOORD2;
};

VS_OUTPUT mainVP( VS_INPUT In )
{
    VS_OUTPUT Out;
    Out.Position = mul( cWorldViewProj, float4( In.Position, 1.0 ) );
    Out.WorldPos = mul( cWorld, float4( In.Position, 1.0 ) );
    Out.TexCoord = In.TexCoord;
    Out.IconTexCoord = In.IconTexCoord;
    return Out;
}
