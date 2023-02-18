#define MAX_BONE_MATRICES 48

cbuffer VPConstantBuffer : register(b0)
{
#if USE_INSTANCING
    matrix              cViewProj;
    float4              cInstanceInfo;
#elif USE_HW_SKINNING
    matrix              cViewProj;
    float3x4            cWorld3x4Array[ MAX_BONE_MATRICES ];
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
#if USE_INSTANCING
    uint    InstanceId      : SV_InstanceID;
#endif
};

struct VS_OUTPUT
{
    float4  Position    : SV_POSITION;
#if USE_TEXCOORD
    float2  TexCoord    : TEXCOORD0;
#endif
};

VS_OUTPUT mainVP( VS_INPUT In )
{
    VS_OUTPUT Out;
    float4 pos = float4( In.Position.xyz, 1.0f );

#if USE_HW_SKINNING
#   if USE_INSTANCING
    float last = 1.0f;
    float3x4 world = float3x4( 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0 );
    uint instanceDataAddr = uint(cInstanceInfo.x) + uint(cInstanceInfo.y) * In.InstanceId;
    for (int i = 0; i < 4; ++i)
    {        
        uint idx = instanceDataAddr + uint( In.BlendIndices[ i ] ) * 3;
        float weight = ( i == 3 ) ? last : In.BlendWeights[ i ];

        float3x4 boneWorld;
        boneWorld[0] = bInstanceData[ idx + 0 ];
        boneWorld[1] = bInstanceData[ idx + 1 ];
        boneWorld[2] = bInstanceData[ idx + 2 ];
        world += boneWorld * weight;

        last -= In.BlendWeights[ i ];
    }
#   else
    float last = 1.0f;
    float3x4 world = float3x4( 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0 );
    for (int i = 0; i < 4; ++i)
    {
        float weight = ( i == 3 ) ? last : In.BlendWeights[ i ];
        world += cWorld3x4Array[ In.BlendIndices[i] ] * weight;
        last -= In.BlendWeights[ i ];
    }
#   endif
    float4 worldPos = float4( mul( world, pos ), 1.0f );
    Out.Position = mul( cViewProj, worldPos );
#elif USE_INSTANCING
    uint instanceDataAddr = uint(cInstanceInfo.x) + uint(cInstanceInfo.y) * In.InstanceId;

    float3x4 world;
    world[0] = bInstanceData[ instanceDataAddr + 0 ];
    world[1] = bInstanceData[ instanceDataAddr + 1 ];
    world[2] = bInstanceData[ instanceDataAddr + 2 ];

    float4 worldPos = float4( mul( world, In.Position ), 1.0f );
    Out.Position = mul( cViewProj, worldPos );
#else
    Out.Position = mul( cWorldViewProj, pos );
#endif
#if USE_TEXCOORD
    Out.TexCoord = In.TexCoord;
#endif

    return Out;
}
