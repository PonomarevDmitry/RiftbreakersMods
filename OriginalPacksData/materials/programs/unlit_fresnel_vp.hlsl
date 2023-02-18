#include "materials/programs/utils_vegetation.hlsl"

#define MAX_BONE_MATRICES 48

cbuffer VPConstantBuffer : register(b0)
{
    float3   cWorldEyePosition;
#if USE_VEGETATION
    float4   cBendingInfo;
#endif
#if USE_VEGETATION_TREE
    float4   cTreeInfo;
#endif
#if USE_HW_SKINNING
    matrix   cViewProj;
    float3x4 cWorld3x4Array[ MAX_BONE_MATRICES ];
#else
    matrix   cWorld;
    matrix   cWorldViewProj;
#endif
#if USE_DEFORM
    float2   cDeform;
    float    cTime;
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
#if USE_DEFORM
    float4 Color          : COLOR;
#endif
#if USE_HW_SKINNING
    float4 BlendWeights   : BLENDWEIGHT;
    int4   BlendIndices   : BLENDINDICES;
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
    float4 ProjPos        : TEXCOORD5;
};

VS_OUTPUT mainVP( VS_INPUT In )
{
    VS_OUTPUT Output;

#if USE_HW_SKINNING
    float last = 1.0f;
    float3x4 world = float3x4( 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0 );

    for (int i = 0; i < 4; ++i)
    {
        float weight = ( i == 3 ) ? last : In.BlendWeights[ i ];
        world += cWorld3x4Array[ In.BlendIndices[i] ] * weight;
        last -= In.BlendWeights[ i ];
    }

    float4 worldPos = float4( mul( world, In.Position ), 1.0f );
    float3 worldNormal = mul( world, float4( In.Normal, 0.0f ) );
#   if USE_NORMAL_MAP
    float4 worldTangent = float4( mul( world, float4( In.Tangent.xyz, 0.0f ) ), 0.0f );
#   endif
    Output.Position = mul( cViewProj, worldPos );
#else
    float4 pos = In.Position;
#   if USE_VEGETATION
    MainBending( pos, cBendingInfo.xy );
#       if USE_DEFORM
    VertexDeform( pos, In.Normal, In.Color.xyz, cDeform.x, cDeform.y, cTime );
#       endif
#   endif
#   if USE_VEGETATION_TREE
    ApplyTrunkBend( pos, cTreeInfo );
#       if USE_DEFORM
    VertexDeform( pos, In.Normal, In.Color.xyz, cDeform.x, cDeform.y, cTime );
#       endif
#   endif
    Output.Position = mul( cWorldViewProj, pos );
    float3 worldPos = mul( cWorld, pos ).xyz;
    float3 worldNormal = normalize( mul( cWorld, float4( In.Normal, 0 ) ).xyz );
#   if USE_NORMAL_MAP
    float3 worldTangent = mul( cWorld, float4( In.Tangent.xyz, 0.0f ) ).xyz;
#   endif
#endif

    Output.ProjPos = Output.Position;
    Output.WorldEyeDir = normalize( worldPos.xyz - cWorldEyePosition);
    Output.WorldNormal = normalize( worldNormal );
    Output.TexCoord = In.TexCoord;

#if USE_NORMAL_MAP
    Output.WorldTangent = worldTangent;
    Output.WorldBiNormal = cross( Output.WorldTangent, Output.WorldNormal ) * In.Tangent.w;
#endif

    return Output;
}
