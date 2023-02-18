cbuffer VPConstantBuffer : register(b0)
{
    matrix      cWorld;
    matrix      cViewProj;
    float       cTilingFactor;
};

struct VS_INPUT
{
    float3      Position      : POSITION;
    float3      Normal        : NORMAL;
    float3      BlendWeight   : BLENDWEIGHT;
    float4      Tangent       : TANGENT;
};

struct VS_OUTPUT
{
    float4      Position      : SV_POSITION;
    float2      UV0           : TEXCOORD0;
    float3      Normal        : TEXCOORD1;
    float3      Tangent       : TEXCOORD2;
    float3      BiNormal      : TEXCOORD3;
    float3      BlendWeight   : TEXCOORD4;
};

VS_OUTPUT mainVP( VS_INPUT In )
{
    VS_OUTPUT Out;

    float4 worldPosition = mul( cWorld, float4( In.Position, 1.0 ) );

    Out.Position = mul( cViewProj, worldPosition );
    Out.Normal = normalize( mul( cWorld, float4( In.Normal, 0.0 ) ).xyz );
    Out.Tangent = In.Tangent.xyz;
    Out.BiNormal = cross( Out.Tangent.xyz, Out.Normal ) * In.Tangent.w;
    Out.UV0 = float2( worldPosition.z / cTilingFactor, -worldPosition.x / cTilingFactor );
    Out.BlendWeight = In.BlendWeight;

    return Out;
}