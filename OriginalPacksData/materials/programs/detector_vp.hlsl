#define MAX_BONE_MATRICES 48

cbuffer VPConstantBuffer : register(b0)
{
    matrix   cWorld;
    matrix   cWorldViewProj;
};

struct VS_INPUT
{
    float4 Position         : POSITION;
    float2 TexCoord         : TEXCOORD0;
};

struct VS_OUTPUT
{
    float4 Position         : SV_POSITION;
    float2 TexCoord         : TEXCOORD0;
    float4 ObjectPos        : TEXCOORD1;
    float4 WorldPos         : TEXCOORD2;
    float4 ProjPos          : TEXCOORD3;
};

VS_OUTPUT mainVP( VS_INPUT In )
{
    VS_OUTPUT Output;
    Output.ObjectPos = In.Position;
    Output.Position = mul( cWorldViewProj, In.Position );
    Output.WorldPos = mul( cWorld, In.Position );
    Output.ProjPos = Output.Position;
    Output.TexCoord = In.TexCoord;
    return Output;
}