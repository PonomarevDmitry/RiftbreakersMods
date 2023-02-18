cbuffer VPConstantBuffer : register(b0)
{
    matrix  cWorld;
    matrix  cWorldViewProj;
};

struct VS_INPUT
{
    float3  Position    : POSITION;
    float3  Normal      : NORMAL;
    float2  TexCoord    : TEXCOORD0;
};

struct VS_OUTPUT
{
    float4  Position    : SV_POSITION;
    float2  TexCoord    : TEXCOORD0;
    float3  WorldPos    : TEXCOORD2;
    float3  WorldNor    : TEXCOORD3;
};

VS_OUTPUT mainVP( VS_INPUT In )
{
    VS_OUTPUT Out;

    float4 position = float4( In.Position, 1.0 );

    Out.Position = mul( cWorldViewProj, position );
    Out.WorldPos = mul( cWorld, position ).xyz;
    Out.WorldNor = mul( cWorld, float4( In.Normal, 0.0f ) ).xyz;
    Out.WorldNor = normalize( Out.WorldNor );
    Out.TexCoord = In.TexCoord;

    return Out;
}