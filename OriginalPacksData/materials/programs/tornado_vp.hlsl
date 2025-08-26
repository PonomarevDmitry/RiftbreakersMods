cbuffer VPConstantBuffer : register(b0)
{
    matrix cWorld;
    matrix cWorldViewProj;
    float  cTime;
    float  cBump;
    float  cConstBump;
    float  cFadePower;
    float  cUVScale;
};

struct VS_INPUT
{
    float4 Position       : POSITION;
    float3 Normal         : NORMAL;
    float2 TexCoord       : TEXCOORD0;
};

struct VS_OUTPUT
{
    float4 Position         : SV_POSITION;
    float4 TexCoord         : TEXCOORD0; 
    float3 Normal           : TEXCOORD1;
    float  Alpha            : TEXCOORD2;
    float3 WorldPos         : TEXCOORD3;
    float4 ProjPos          : TEXCOORD4;
};

void VertexBump( inout float4 vPos, float3 vNormal, float strength )
{
    float3 n = normalize( float3( vNormal.x, 0.0f, vNormal.z ) );

    vPos.xz += n.xz * strength;
    vPos.xz += n.xz * strength;
    vPos.xz += n.xz * strength;
}

VS_OUTPUT mainVP( VS_INPUT In )
{
    VS_OUTPUT Output;

    const float modelHeight = 26.0f;
    const float halfModelHeight = 13.0f;

    float4 pos = In.Position;
    VertexBump( pos, In.Normal, cConstBump + ( cBump * sin( cTime ) ) );
    pos = lerp( In.Position, pos, distance( In.Position.y / modelHeight, ( ( 1.0f + sin( cTime ) ) / 2.0 ) ) );

    Output.Normal = normalize( mul( cWorld, float4( In.Normal, 0.0f ) ).xyz );
    Output.Position = mul( cWorldViewProj, pos );
    Output.ProjPos = Output.Position;
    Output.WorldPos = mul( cWorld, float4( In.Position.xyz, 1.0 ) );
    Output.Alpha = saturate( 1.0f - pow( distance( In.Position.y, halfModelHeight ) / halfModelHeight, cFadePower ) );
    Output.TexCoord.xyzw = In.TexCoord.xyxy * cUVScale;
    Output.TexCoord.y += cTime;

    return Output;
}
