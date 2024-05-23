#define MAX_BONE_MATRICES 48

cbuffer VPConstantBuffer : register(b0)
{
    float4  cQuadData;
};

struct VS_INPUT
{
    float3  Position        : POSITION;
    float2  TexCoord        : TEXCOORD0;
};

struct VS_OUTPUT
{
    float4  Position        : SV_POSITION;
    float2  TexCoord        : TEXCOORD0;
    float4  ProjPos         : TEXCOORD1;
};

VS_OUTPUT mainVP( VS_INPUT In )
{
    VS_OUTPUT Out;
    float4 projPos = float4( ( 2.0 * float2( cQuadData.x, 1.0f - cQuadData.y ) ) - 1.0, 0.0, 1.0 );
    projPos.xy += In.Position.xz;
    projPos.y += 0.10f;
    Out.ProjPos = projPos;
    Out.Position = projPos;
    Out.TexCoord = In.TexCoord;
    return Out;
}