#define MAX_BONE_MATRICES 48
#define MAX_VIEWPORT_COUNT 6

cbuffer VPConstantBuffer : register(b0)
{
#if USE_VIEWPORTARRAYINDEX
    matrix              cViewProj[ MAX_VIEWPORT_COUNT ];
#elif USE_INSTANCING || USE_HW_SKINNING
    matrix              cViewProj;
#endif
#if USE_INSTANCING
    float4              cInstanceInfo;
#elif USE_HW_SKINNING
    float3x4            cWorld3x4Array[ MAX_BONE_MATRICES ];
#elif USE_VIEWPORTARRAYINDEX
    matrix              cWorld;
#else
    matrix              cWorldViewProj;
#endif
};

#if USE_INSTANCING
StructuredBuffer<float4> bInstanceData;
#endif

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
#if USE_INSTANCING || USE_VIEWPORTARRAYINDEX
    uint    InstanceId      : SV_InstanceID;
#endif
};

struct VS_OUTPUT
{
    float4  Position        : SV_POSITION;
#if USE_TEXCOORD
    float2  TexCoord        : TEXCOORD0;
#endif
#if USE_VIEWPORTARRAYINDEX
    uint    ViewportIndex   : SV_ViewportArrayIndex;
#endif
};

VS_OUTPUT mainVP( VS_INPUT In )
{
    VS_OUTPUT Out;
    float4 pos = float4( In.Position.xyz, 1.0f );

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
#endif

#if USE_HW_SKINNING && USE_INSTANCING
    float3x4 cWorld = float3x4( 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0 );
    for ( int i = 0; i < 4; ++i )
    {        
        uint idx = instanceDataAddr + uint( In.BlendIndices[ i ] ) * 3;
        float3x4 boneWorld = { bInstanceData[ idx + 0 ], bInstanceData[ idx + 1 ], bInstanceData[ idx + 2 ] };
        cWorld += boneWorld * In.BlendWeights[ i ];
    }
#elif USE_HW_SKINNING
    float3x4 cWorld = In.BlendWeights.x * cWorld3x4Array[ In.BlendIndices.x ];
    cWorld += In.BlendWeights.y * cWorld3x4Array[ In.BlendIndices.y ];
    cWorld += In.BlendWeights.z * cWorld3x4Array[ In.BlendIndices.z ];
    cWorld += In.BlendWeights.w * cWorld3x4Array[ In.BlendIndices.w ];
#elif USE_INSTANCING
    float3x4 cWorld = { 
        bInstanceData[ instanceDataAddr + 0 ], 
        bInstanceData[ instanceDataAddr + 1 ], 
        bInstanceData[ instanceDataAddr + 2 ] 
    };
#endif

#if USE_HW_SKINNING || USE_INSTANCING || USE_VIEWPORTARRAYINDEX
    float4 worldPos = float4( mul( cWorld, pos ).xyz, 1.0f );
#endif 

#if USE_VIEWPORTARRAYINDEX
    Out.Position = mul( cViewProj[ viewportIndex ], worldPos );
#elif USE_INSTANCING || USE_HW_SKINNING
    Out.Position = mul( cViewProj, worldPos );
#else
    Out.Position = mul( cWorldViewProj, pos );
#endif

#if USE_TEXCOORD
    Out.TexCoord = In.TexCoord;
#endif

    return Out;
}
