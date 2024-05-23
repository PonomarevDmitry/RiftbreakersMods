#include "materials/programs/utils_vegetation.hlsl"

#define MAX_BONE_MATRICES 48

cbuffer VPConstantBuffer : register(b0)
{
    matrix      cViewProj;
#if USE_VELOCITY
    matrix      cPrevViewProj;
#endif
#if USE_INSTANCING
    float4      cInstanceInfo; // offset, stride
#else
#   if USE_HW_SKINNING 
    float3x4    cWorld3x4Array[ MAX_BONE_MATRICES ];
#       if USE_VELOCITY
    float3x4    cPrevWorld3x4Array[ MAX_BONE_MATRICES ];
#       endif
#   else
    matrix      cWorld;
#       if USE_VELOCITY
    matrix      cPrevWorld;
#       endif
#   endif
    float4      cBendingInfo;
    float4      cPrevBendingInfo;
#endif
#if USE_DEFORM
    float2      cDeform;
    float       cTime;
#   if USE_VELOCITY
    float       cPrevTime;
#   endif
#endif
};

struct VS_INPUT
{
    float4      Position        : POSITION;
    float3      Normal          : NORMAL;
    float2      UV0             : TEXCOORD0;
    float4      Tangent         : TANGENT0;
#if USE_HW_SKINNING
    float4      BlendWeights    : BLENDWEIGHT;
    int4        BlendIndices    : BLENDINDICES;
#endif
#if USE_DEFORM
    float4      Color           : COLOR;
#endif
#if USE_INSTANCING
    uint        InstanceId      : SV_InstanceID;
#endif
};

struct VS_OUTPUT
{
    float4      Position        : SV_POSITION;
    float2      UV0             : TEXCOORD0;
    float3      Normal          : TEXCOORD1;
    float3      Tangent         : TEXCOORD2;
    float3      BiNormal        : TEXCOORD3;
    float3      WorldPos        : TEXCOORD4;
#if USE_VELOCITY
    float4      CurrPos         : TEXCOORD5;
    float4      PrevPos         : TEXCOORD6;
#endif
};

#if USE_INSTANCING
StructuredBuffer<float4> bInstanceData;
#endif

VS_OUTPUT mainVP( VS_INPUT In )
{
    VS_OUTPUT Out;

#if USE_HW_SKINNING
#   if USE_INSTANCING
            float3x4 cWorld = float3x4( 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0 );
            float3x4 cPrevWorld = float3x4( 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0 );
            
            uint instanceDataAddr = uint( cInstanceInfo.x ) + uint( cInstanceInfo.y ) * In.InstanceId;
            float4 cBendingInfo = bInstanceData[ instanceDataAddr ];
#       if USE_VELOCITY
            uint prevInstanceDataAddr = instanceDataAddr + uint( cInstanceInfo.z );
            float4 cPrevBendingInfo = bInstanceData[ prevInstanceDataAddr ];
#       endif
            for ( int i = 0; i < 4; ++i )
            {                    
                float weight = In.BlendWeights[ i ];
                uint boneIdx = uint( In.BlendIndices[ i ] );

                uint idx = instanceDataAddr + 1 + boneIdx * 3;
                float3x4 boneWorld;
                boneWorld[0] = bInstanceData[ idx     ] * weight;
                boneWorld[1] = bInstanceData[ idx + 1 ] * weight;
                boneWorld[2] = bInstanceData[ idx + 2 ] * weight;
                cWorld += boneWorld;
                
#       if USE_VELOCITY
                uint prevIdx = prevInstanceDataAddr + 1 + boneIdx * 3;
                float3x4 prevBoneWorld;
                prevBoneWorld[0] = bInstanceData[ prevIdx     ] * weight;
                prevBoneWorld[1] = bInstanceData[ prevIdx + 1 ] * weight;
                prevBoneWorld[2] = bInstanceData[ prevIdx + 2 ] * weight;
                cPrevWorld += prevBoneWorld;
#       endif
            }
#   else
            float3x4 cWorld = In.BlendWeights.x * cWorld3x4Array[ In.BlendIndices.x ];
            cWorld += In.BlendWeights.y * cWorld3x4Array[ In.BlendIndices.y ];
            cWorld += In.BlendWeights.z * cWorld3x4Array[ In.BlendIndices.z ];
            cWorld += In.BlendWeights.w * cWorld3x4Array[ In.BlendIndices.w ];

#       if USE_VELOCITY
            float3x4 cPrevWorld = In.BlendWeights.x * cPrevWorld3x4Array[ In.BlendIndices.x ];
            cPrevWorld += In.BlendWeights.y * cPrevWorld3x4Array[ In.BlendIndices.y ];
            cPrevWorld += In.BlendWeights.z * cPrevWorld3x4Array[ In.BlendIndices.z ];
            cPrevWorld += In.BlendWeights.w * cPrevWorld3x4Array[ In.BlendIndices.w ];
#       endif
#   endif
#else
#   if USE_INSTANCING
            uint instanceDataAddr = uint( cInstanceInfo.x ) + uint( cInstanceInfo.y ) * In.InstanceId;
            float4 cBendingInfo = bInstanceData[ instanceDataAddr ];
            float3x4 cWorld = float3x4( bInstanceData[ instanceDataAddr + 1 ], bInstanceData[ instanceDataAddr + 2 ], bInstanceData[ instanceDataAddr + 3 ] );
#       if USE_VELOCITY
            float4 cPrevBendingInfo = bInstanceData[ instanceDataAddr + 4 ];
            float3x4 cPrevWorld = float3x4( bInstanceData[ instanceDataAddr + 5 ], bInstanceData[ instanceDataAddr + 6 ], bInstanceData[ instanceDataAddr + 7 ] );
#       endif
#   endif
#endif

    float4 pos = float4( In.Position.xyz, 1.0f );
    VertexBending( pos, cBendingInfo );
#if USE_DEFORM
    VertexDeform( pos, In.Normal, In.Color.xyz, cDeform.x, cDeform.y, cTime );
#endif
    float3 worldPos = mul( cWorld, pos ).xyz;
    Out.WorldPos = worldPos.xyz;
    Out.Position = mul( cViewProj, float4( worldPos, 1.0f ) );

#if USE_VELOCITY
    Out.CurrPos = Out.Position;
    float4 prevPos = float4( In.Position.xyz, 1.0f );
    VertexBending( prevPos, cPrevBendingInfo );
#if USE_DEFORM
    VertexDeform( prevPos, In.Normal, In.Color.xyz, cDeform.x, cDeform.y, cPrevTime );
#endif
    float3 prevWorldPos = mul( cPrevWorld, prevPos ).xyz;
    Out.PrevPos = mul( cPrevViewProj, float4( prevWorldPos, 1.0f ) );
#endif

    Out.UV0 = In.UV0.xy;
    Out.Normal = normalize( mul( cWorld, float4( In.Normal, 0.0 ) ).xyz );
    Out.Tangent = normalize( mul( cWorld, float4( In.Tangent.xyz, 0.0 ) ).xyz );
    Out.BiNormal = cross( Out.Tangent, Out.Normal ) * In.Tangent.w;

    return Out;
}