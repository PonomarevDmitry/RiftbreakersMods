cbuffer VPConstantBuffer : register(b0)
{
    matrix  cWorld;
    matrix  cWorldViewProj;
};

struct VS_INPUT
{
    float3  Position      : POSITION;
    float4  TexCoord      : TEXCOORD0;
};

struct VS_OUTPUT
{
    float4  Position    : SV_POSITION;
    float4  TexCoord    : TEXCOORD0;
    float3  WorldPos    : TEXCOORD1;
    float4  ProjPos     : TEXCOORD2;
};

VS_OUTPUT mainVP( VS_INPUT In )
{
    VS_OUTPUT Out;

    float4 position = float4( In.Position, 1.0 );
    Out.Position = mul( cWorldViewProj, position );
    Out.WorldPos = mul( cWorld, position ).xyz;
    Out.ProjPos = Out.Position;
    Out.TexCoord = In.TexCoord;

    return Out;
}