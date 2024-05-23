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
#endif

#if USE_TILED_UV || USE_MIPMAP_CHECKER
    float       cTilingFactor;
#endif
#if USE_TILED_UV_ANIM
    float2      cTilingSpeed;
    float       cTime;
#endif
};

struct VS_INPUT
{
    float4      Position      : POSITION;
    float3      Normal        : NORMAL;
#if !USE_TILED_UV
    float2      UV0           : TEXCOORD0;
#endif
#if !USE_MIPMAP_CHECKER
    float4      Tangent       : TANGENT0;
#endif
#if USE_HW_SKINNING
    float4      BlendWeights  : BLENDWEIGHT;
    int4        BlendIndices  : BLENDINDICES;
#endif
#if USE_INSTANCING
    uint        InstanceId    : SV_InstanceID;
#endif
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
#if USE_LOCAL_POS
    float3      LocalPos      : TEXCOORD7;
#endif
};

#if USE_INSTANCING
StructuredBuffer<float4> bInstanceData;
#endif

VS_OUTPUT mainVP( VS_INPUT In )
{
    VS_OUTPUT Out;

#if USE_TILED_UV
    Out.UV0 = mul( cWorld, In.Position ).xz / cTilingFactor;
#else
#   if USE_MIPMAP_CHECKER
        Out.UV0 = In.UV0 / cTilingFactor;
#   else
        Out.UV0 = In.UV0;
#   endif
#endif

#if USE_TILED_UV_ANIM
    Out.UV0 = Out.UV0 + cTilingSpeed * cTime;
#endif

#if USE_HW_SKINNING
#   if USE_INSTANCING
            float3x4 cWorld = float3x4( 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0 );
            float3x4 cPrevWorld = float3x4( 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0 );

            uint instanceDataAddr = uint( cInstanceInfo.x ) + uint( cInstanceInfo.y ) * In.InstanceId;
#   if USE_VELOCITY
            uint prevInstanceDataAddr = instanceDataAddr + uint( cInstanceInfo.z );
#   endif
            for ( int i = 0; i < 4; ++i )
            {                    
                float weight = In.BlendWeights[ i ];
                uint boneIdx = uint( In.BlendIndices[ i ] );

                uint idx = instanceDataAddr + boneIdx * 3;
                float3x4 boneWorld;
                boneWorld[0] = bInstanceData[ idx     ] * weight;
                boneWorld[1] = bInstanceData[ idx + 1 ] * weight;
                boneWorld[2] = bInstanceData[ idx + 2 ] * weight;
                cWorld += boneWorld;
                
#       if USE_VELOCITY
                uint prevIdx = prevInstanceDataAddr + boneIdx * 3;
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
            float3x4 cWorld = float3x4( bInstanceData[ instanceDataAddr + 0 ], bInstanceData[ instanceDataAddr + 1 ], bInstanceData[ instanceDataAddr + 2 ] );
#       if USE_VELOCITY
            float3x4 cPrevWorld = float3x4( bInstanceData[ instanceDataAddr + 3 ], bInstanceData[ instanceDataAddr + 4 ], bInstanceData[ instanceDataAddr + 5 ] );
#       endif
#   endif
#endif

    float4 worldPos = float4( mul( cWorld, In.Position ).xyz, 1.0f );
    Out.Position = mul( cViewProj, worldPos );
#if USE_VELOCITY
    Out.CurrPos = Out.Position;
    float4 prevWorldPos = float4( mul( cPrevWorld, In.Position ).xyz, 1.0f );
    Out.PrevPos = mul( cPrevViewProj, prevWorldPos );
#endif
    Out.WorldPos = worldPos.xyz;
    Out.Normal = normalize( mul( cWorld, float4( In.Normal, 0.0f ) ).xyz );
#if USE_MIPMAP_CHECKER
    Out.Tangent = normalize( mul( cWorld, float4( 1.0f, 0.0f, 0.0f, 0.0f ) ).xyz );
    Out.BiNormal = cross( Out.Tangent, Out.Normal );
#else
    float4 tangent = ( In.Tangent.w == 0.0f ) ? float4( 1.0f, 0.0f, 0.0f, 1.0f ) : In.Tangent; // fix for old 3dsMax exports
    Out.Tangent = normalize( mul( cWorld, float4( tangent.xyz, 0.0f ) ).xyz );
    Out.BiNormal = cross( Out.Tangent, Out.Normal ) * tangent.w; 
#endif

#if USE_LOCAL_POS
    Out.LocalPos = In.Position;
#endif

    return Out;
}