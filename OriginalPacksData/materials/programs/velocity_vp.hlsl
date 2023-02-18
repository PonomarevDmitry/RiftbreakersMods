#include "materials/programs/utils_vegetation.hlsl"

#define MAX_BONE_MATRICES 48

cbuffer VPConstantBuffer : register(b0)
{
    matrix                  cViewProj;
    matrix                  cPrevViewProj;
#if USE_HW_SKINNING 
    float3x4                cWorld3x4Array[ MAX_BONE_MATRICES ];
    float3x4                cPrevWorld3x4Array[ MAX_BONE_MATRICES ];
#else   
    matrix                  cWorld;
    matrix                  cPrevWorld;
#endif  
#if USE_VEGETATION_TREE 
    float4                  cTreeInfo;
    float4                  cPrevTreeInfo;
#endif  
#if USE_VEGETATION  
    float4                  cBendingInfo;
    float4                  cPrevBendingInfo;
#endif
};

struct VS_INPUT
{
    float4  Position        : POSITION;
#if USE_TEXCOORD
    float2  TexCoord        : TEXCOORD0;
#endif
#if USE_HW_SKINNING
    float4  BlendWeights    : BLENDWEIGHT;
    int4    BlendIndices    : BLENDINDICES;
#endif
};

struct VS_OUTPUT
{
    float4  Position        : SV_POSITION;
    float4  CurrPosition    : TEXCOORD0;
    float4  PrevPosition    : TEXCOORD1;
#if USE_TEXCOORD
    float2  TexCoord        : TEXCOORD2;
#endif
};

VS_OUTPUT mainVP( VS_INPUT In )
{
    VS_OUTPUT Out;

#if USE_HW_SKINNING
    float last = 1.0f;
    float3x4 world = float3x4( 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0 );
    float3x4 prevWorld = float3x4( 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0 );
    for (int i = 0; i < 4; ++i)
    {
        float weight = ( i == 3 ) ? last : In.BlendWeights[ i ];
        world += cWorld3x4Array[ In.BlendIndices[i] ] * weight;
        prevWorld += cPrevWorld3x4Array[ In.BlendIndices[i] ] * weight;
        last -= In.BlendWeights[ i ];
    }
#else
    matrix world = cWorld;
    matrix prevWorld = cPrevWorld;
#endif

    float4 prevPos = float4( In.Position.xyz, 1.0f );
#if USE_VEGETATION_TREE
    ApplyTrunkBend( prevPos, cPrevTreeInfo );
#elif USE_VEGETATION
    MainBending( prevPos, cPrevBendingInfo.xy );
#endif

    float3 prevWorldPos = mul( prevWorld, prevPos ).xyz;
    Out.PrevPosition = mul( cPrevViewProj, float4( prevWorldPos, 1.0f ) );

    float4 pos = float4( In.Position.xyz, 1.0f );
#if USE_VEGETATION_TREE
    ApplyTrunkBend( pos, cTreeInfo );
#elif USE_VEGETATION
    MainBending( pos, cBendingInfo.xy );
#endif

    float3 worldPos = mul( world, pos ).xyz;
    Out.Position = mul( cViewProj, float4( worldPos, 1.0f ) );
    Out.CurrPosition = Out.Position;

#if USE_TEXCOORD
    Out.TexCoord = In.TexCoord;
#endif

    return Out;
}
