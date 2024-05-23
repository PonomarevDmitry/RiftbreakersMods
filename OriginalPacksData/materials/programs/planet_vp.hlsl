#define MAX_BONE_MATRICES 3

cbuffer VPConstantBuffer : register(b0)
{
#if USE_HW_SKINNING
    float3x4 cWorld3x4Array[ MAX_BONE_MATRICES ];
#else
    matrix   cWorld;
#endif
    matrix   cViewProj;
    matrix   cView;
};

struct VS_INPUT
{
    float4 Position         : POSITION;
    float3 Normal           : NORMAL;
    float2 TexCoord         : TEXCOORD0;
#if USE_HW_SKINNING
    float4 BlendWeights     : BLENDWEIGHT;
    int4   BlendIndices     : BLENDINDICES;
#endif
};

struct VS_OUTPUT
{
    float4 Position         : SV_POSITION;
    float2 TexCoord         : TEXCOORD0;
    float3 Normal           : TEXCOORD1;
    float4 ViewPos          : TEXCOORD2;
};

VS_OUTPUT mainVP( VS_INPUT In )
{
    VS_OUTPUT Output;

#if USE_HW_SKINNING
    float3x4 cWorld = In.BlendWeights.x * cWorld3x4Array[ In.BlendIndices.x ];
    cWorld += In.BlendWeights.y * cWorld3x4Array[ In.BlendIndices.y ];
    cWorld += In.BlendWeights.z * cWorld3x4Array[ In.BlendIndices.z ];
    cWorld += In.BlendWeights.w * cWorld3x4Array[ In.BlendIndices.w ];
#endif

    float3 worldNormal = mul( cWorld, float4( In.Normal, 0.0f ) ).xyz;
    float4 worldPos = float4( mul( cWorld, In.Position ).xyz, 1.0f );

    Output.Position = mul( cViewProj, worldPos );
    Output.Normal = normalize( mul( cView, float4( worldNormal, 0.0 ) ).xyz );
    Output.ViewPos = mul( cView, worldPos ); 
    Output.TexCoord = In.TexCoord;

    return Output;
}
