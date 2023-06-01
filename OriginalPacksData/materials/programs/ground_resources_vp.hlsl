cbuffer VPConstantBuffer : register(b0)
{
    matrix      cViewProj;
#if USE_VELOCITY
    matrix      cPrevViewProj;
#endif
    matrix      cWorld;
#if USE_VELOCITY
    matrix      cPrevWorld;
#endif
    float       cTilingFactor;
};

struct VS_INPUT
{
    float3  Position        : POSITION;
    float   Alpha           : BLENDWEIGHT;
};

struct VS_OUTPUT
{
    float4      Position      : SV_POSITION;
    float2      UV0           : TEXCOORD0;
    float3      Normal        : TEXCOORD1;
    float3      Tangent       : TEXCOORD2;
    float3      BiNormal      : TEXCOORD3;
    float3      WorldPos      : TEXCOORD4;
#if USE_VELOCITY
    float4      CurrPos       : TEXCOORD5;
    float4      PrevPos       : TEXCOORD6;
#endif
    float       Alpha         : TEXCOORD7;
};

VS_OUTPUT mainVP( VS_INPUT In )
{
    VS_OUTPUT Out;

    float4 worldPosition = mul( cWorld, float4( In.Position, 1.0 ) );

    Out.Position = mul( cViewProj, worldPosition );
#if USE_VELOCITY
    Out.CurrPos = Out.Position;
    float4 prevWorldPos = float4( mul( cPrevWorld, float4( In.Position, 1.0 ) ).xyz, 1.0f );
    Out.PrevPos = mul( cPrevViewProj, prevWorldPos );
#endif
    Out.Normal = normalize( mul( cWorld, float4( 0.0, 1.0, 0.0, 0.0 ) ).xyz );
    Out.Tangent = float3(1.0,0.0,0.0);
    Out.BiNormal = cross( Out.Tangent.xyz, Out.Normal ) * 1.0;
    Out.Alpha = In.Alpha;
    Out.WorldPos = worldPosition;
    Out.UV0 = float2( worldPosition.z / cTilingFactor, -worldPosition.x / cTilingFactor );

    return Out;
}