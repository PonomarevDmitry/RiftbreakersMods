cbuffer VPConstantBuffer : register(b0)
{
    matrix      cWorld;
    matrix      cViewProj;
    float       cTilingFactor;
};

struct VS_INPUT
{
    float3  Position        : POSITION;
    //float   Alpha           : BLENDWEIGHT;
};

struct VS_OUTPUT
{
    float4      Position      : SV_POSITION;
    float2      UV0           : TEXCOORD0;
    float3      Normal        : TEXCOORD1;
    float3      Tangent       : TEXCOORD2;
    float3      BiNormal      : TEXCOORD3;
    float3      WorldPos      : TEXCOORD4;
    float       Alpha         : TEXCOORD5;
};

VS_OUTPUT mainVP( VS_INPUT In )
{
    VS_OUTPUT Out;

    float4 worldPosition = mul( cWorld, float4( In.Position, 1.0 ) );

    Out.Position = mul(cViewProj, worldPosition);
    Out.Normal = normalize( mul( cWorld, float4( 0.0, 1.0, 0.0, 0.0 ) ).xyz );
    Out.Tangent = float3(1.0,0.0,0.0);
    Out.BiNormal = cross( Out.Tangent.xyz, Out.Normal ) * 1.0;
    Out.Alpha = 1.0;
    Out.WorldPos = worldPosition;
    Out.UV0 = float2( worldPosition.z / cTilingFactor, -worldPosition.x / cTilingFactor );

    return Out;
}