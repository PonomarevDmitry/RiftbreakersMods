#include "materials/programs/utils_vegetation.hlsl"

#define MAX_BONE_MATRICES 48
#define MAX_VIEWPORT_COUNT 6

cbuffer VPConstantBuffer : register(b0)
{
#if USE_VIEWPORTARRAYINDEX
    matrix      cViewProj[ MAX_VIEWPORT_COUNT ];
#else
    matrix      cViewProj;
#endif
#if USE_INSTANCING
    float4      cInstanceInfo; // offset, stride
#elif USE_HW_SKINNING 
    float3x4    cWorld3x4Array[ MAX_BONE_MATRICES ];
    float4      cBendingInfo;
#else
    matrix      cWorld;
    float4      cBendingInfo;
#endif
#if USE_DEFORM
    float2      cDeform;
    float       cTime;
#endif
};

struct VS_INPUT
{
    float4      Position        : POSITION;
    float2      UV0             : TEXCOORD0;
#if USE_DEFORM
    float3      Normal          : NORMAL;
    float4      Color           : COLOR;
#endif
#if USE_HW_SKINNING
    float4      BlendWeights    : BLENDWEIGHT;
    int4        BlendIndices    : BLENDINDICES;
#endif
#if USE_INSTANCING || USE_VIEWPORTARRAYINDEX
    uint        InstanceId      : SV_InstanceID;
#endif
};

struct VS_OUTPUT
{
    float4      Position        : SV_POSITION;
    float2      UV0             : TEXCOORD0;
#if USE_VIEWPORTARRAYINDEX
    uint        ViewportIndex   : SV_ViewportArrayIndex;
#endif
};

#if USE_INSTANCING
StructuredBuffer<float4> bInstanceData;
#endif

VS_OUTPUT mainVP( VS_INPUT In )
{
    VS_OUTPUT Out;

#if USE_INSTANCING && USE_VIEWPORTARRAYINDEX
    uint instanceId = In.InstanceId / 6;
#elif USE_INSTANCING || USE_VIEWPORTARRAYINDEX
    uint instanceId = In.InstanceId;
#endif 
#if USE_INSTANCING && USE_VIEWPORTARRAYINDEX
    uint viewportIndex = In.InstanceId % 6;
#elif USE_VIEWPORTARRAYINDEX
    uint viewportIndex = In.InstanceId;
#endif 

#if USE_VIEWPORTARRAYINDEX
    Out.ViewportIndex = viewportIndex;
#endif 

#if USE_INSTANCING
    uint instanceDataAddr = uint( cInstanceInfo.x ) + uint( cInstanceInfo.y ) * instanceId;
    float4 cBendingInfo = bInstanceData[ instanceDataAddr ];
#endif

    float4 pos = float4( In.Position.xyz, 1.0f );
    VertexBending( pos, cBendingInfo );

#if USE_DEFORM
    VertexDeform( pos, In.Normal, In.Color.xyz, cDeform.x, cDeform.y, cTime );
#endif

#if USE_HW_SKINNING && USE_INSTANCING
    uint instanceMatrixDataAddr = instanceDataAddr + 1;
    float3x4 cWorld = float3x4( 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0 );
    for ( int i = 0; i < 4; ++i )
    {        
        uint idx = instanceMatrixDataAddr + uint( In.BlendIndices[ i ] ) * 3;
        float3x4 boneWorld = { bInstanceData[ idx + 0 ], bInstanceData[ idx + 1 ], bInstanceData[ idx + 2 ] };
        cWorld += boneWorld * In.BlendWeights[ i ];
    }
#elif USE_HW_SKINNING
    float3x4 cWorld = In.BlendWeights.x * cWorld3x4Array[ In.BlendIndices.x ];
    cWorld += In.BlendWeights.y * cWorld3x4Array[ In.BlendIndices.y ];
    cWorld += In.BlendWeights.z * cWorld3x4Array[ In.BlendIndices.z ];
    cWorld += In.BlendWeights.w * cWorld3x4Array[ In.BlendIndices.w ];
#elif USE_INSTANCING
    uint instanceMatrixDataAddr = instanceDataAddr + 1;
    float3x4 cWorld = { 
        bInstanceData[ instanceMatrixDataAddr + 0 ], 
        bInstanceData[ instanceMatrixDataAddr + 1 ], 
        bInstanceData[ instanceMatrixDataAddr + 2 ] 
    };
#endif

    float4 worldPos = float4( mul( cWorld, pos ).xyz, 1.0f );

#if USE_VIEWPORTARRAYINDEX
    Out.Position = mul( cViewProj[ viewportIndex ], worldPos );
#else
    Out.Position = mul( cViewProj, worldPos );
#endif

    Out.UV0 = In.UV0.xy;
    return Out;
}