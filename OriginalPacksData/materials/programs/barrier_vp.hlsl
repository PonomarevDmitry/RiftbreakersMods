#define MAX_BONE_MATRICES 48

cbuffer VPConstantBuffer : register(b0)
{
    float3   cWorldEyePosition;
#if USE_HW_SKINNING
    matrix   cViewProj;
    float3x4 cWorld3x4Array[ MAX_BONE_MATRICES ];
#else
    matrix   cWorld;
    matrix   cWorldViewProj;
#endif
};

struct VS_INPUT
{
    float4 Position       : POSITION;
    float3 Normal         : NORMAL;
    float2 TexCoord       : TEXCOORD0;
#if USE_NORMAL_MAP
    float4 Tangent        : TANGENT0;
#endif
#if USE_HW_SKINNING
    float4 BlendWeights   : BLENDWEIGHT;
    uint4  BlendIndices   : BLENDINDICES;
#endif
};

struct VS_OUTPUT
{
    float4 Position       : SV_POSITION;
    float2 TexCoord       : TEXCOORD0;
    float3 WorldNormal    : TEXCOORD1;
    float3 WorldEyeDir    : TEXCOORD2;
#if USE_NORMAL_MAP
    float3 WorldTangent   : TEXCOORD3;
    float3 WorldBiNormal  : TEXCOORD4;
#endif
};

VS_OUTPUT mainVP( VS_INPUT In )
{
    VS_OUTPUT Output;

#if USE_HW_SKINNING
    float3x4 cWorld = In.BlendWeights.x * cWorld3x4Array[ In.BlendIndices.x ];
    cWorld += In.BlendWeights.y * cWorld3x4Array[ In.BlendIndices.y ];
    cWorld += In.BlendWeights.z * cWorld3x4Array[ In.BlendIndices.z ];
    cWorld += In.BlendWeights.w * cWorld3x4Array[ In.BlendIndices.w ];
    
    float4 worldPos = float4( mul( cWorld, In.Position ), 1.0f );
    float3 worldNormal = mul( cWorld, float4( In.Normal, 0.0f ) );
#   if USE_NORMAL_MAP
    float4 worldTangent = float4( mul( cWorld, float4( In.Tangent.xyz, 0.0f ) ), 0.0f );
#   endif
    Output.Position = mul( cViewProj, worldPos );
#else
    Output.Position = mul( cWorldViewProj, In.Position );
    float3 worldPos = mul( cWorld, In.Position ).xyz;
    float3 worldNormal = normalize( mul( cWorld, float4( In.Normal, 0 ) ).xyz );
#   if USE_NORMAL_MAP
    float3 worldTangent = mul( cWorld, float4( In.Tangent.xyz, 0.0f ) ).xyz;
#   endif
#endif

    Output.WorldEyeDir = normalize( worldPos.xyz - cWorldEyePosition);
    Output.WorldNormal = normalize( worldNormal );
    Output.TexCoord = In.TexCoord;

#if USE_NORMAL_MAP
    Output.WorldTangent = worldTangent;
    Output.WorldBiNormal = cross( Output.WorldTangent, Output.WorldNormal ) * In.Tangent.w;
#endif

    return Output;
}
