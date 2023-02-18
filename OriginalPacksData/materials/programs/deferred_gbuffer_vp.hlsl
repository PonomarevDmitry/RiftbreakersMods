#define MAX_BONE_MATRICES 48

cbuffer VPConstantBuffer : register(b0)
{
#if USE_INSTANCING
    float4      cInstanceInfo; // offset, stride
    matrix      cViewProj;
#else
#   if USE_HW_SKINNING
    matrix      cViewProj;
    float3x4    cWorld3x4Array[ MAX_BONE_MATRICES ];
#   else
    matrix      cWorld;
    matrix      cViewProj;
#   endif
#   if USE_TILED_UV || USE_MIPMAP_CHECKER
    float       cTilingFactor;
#   endif
#   if USE_TILED_UV_ANIM
    float2      cTilingSpeed;
    float       cTime;
#   endif
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
#if USE_LOCAL_POS
    float3      LocalPos      : TEXCOORD5;
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
    float last = 1.0f;
    float3x4 world = float3x4( 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0 );
    uint instanceDataAddr = uint(cInstanceInfo.x) + uint(cInstanceInfo.y) * In.InstanceId;
    for (int i = 0; i < 4; ++i)
    {        
        uint idx = instanceDataAddr + uint( In.BlendIndices[ i ] ) * 3;
        float weight = ( i == 3 ) ? last : In.BlendWeights[ i ];

        float3x4 boneWorld;
        boneWorld[0] = bInstanceData[ idx + 0 ] * weight;
        boneWorld[1] = bInstanceData[ idx + 1 ] * weight;
        boneWorld[2] = bInstanceData[ idx + 2 ] * weight;
        world += boneWorld;

        last -= In.BlendWeights[ i ];
    }
#   else
    float last = 1.0f;
    float3x4 world = float3x4( 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0 );

    for (int i = 0; i < 4; ++i)
    {
        float weight = ( i == 3 ) ? last : In.BlendWeights[ i ];
        world += cWorld3x4Array[ In.BlendIndices[ i ] ] * weight;
        last -= In.BlendWeights[ i ];
    }
#   endif
    float4 worldPos = float4( mul( world, In.Position ).xyz, 1.0f );
    Out.WorldPos = worldPos.xyz;
    Out.Position = mul( cViewProj, worldPos );
    Out.Normal = normalize( mul( world, float4( In.Normal, 0.0f ) ) );
    Out.Tangent = normalize( mul( world, float4( In.Tangent.xyz, 0.0f ) ) );
#elif USE_INSTANCING
    uint instanceDataAddr = uint(cInstanceInfo.x) + uint(cInstanceInfo.y) * In.InstanceId;

    float3x4 world;
    world[0] = bInstanceData[ instanceDataAddr + 0 ];
    world[1] = bInstanceData[ instanceDataAddr + 1 ];
    world[2] = bInstanceData[ instanceDataAddr + 2 ];

    float4 worldPos = float4( mul( world, In.Position ).xyz, 1.0f );
    Out.Position = mul( cViewProj, worldPos );
    Out.WorldPos = worldPos.xyz;
    Out.Normal = normalize( mul( world, float4( In.Normal, 0.0f ) ) );
    Out.Tangent = normalize( mul( world, float4( In.Tangent.xyz, 0.0f ) ) );
#else
    float4 worldPos = float4( mul( cWorld, In.Position ).xyz, 1.0f );
    Out.Position = mul( cViewProj, worldPos );
    Out.WorldPos = worldPos.xyz;
    Out.Normal = normalize( mul( cWorld, float4( In.Normal, 0.0f ) ).xyz );
#if USE_MIPMAP_CHECKER
    Out.Tangent = normalize( mul( cWorld, float4( 1.0f, 0.0f, 0.0f, 0.0f ) ).xyz );
#else
    Out.Tangent = normalize( mul( cWorld, float4( In.Tangent.xyz, 0.0f ) ).xyz );
#endif
#endif

#if USE_MIPMAP_CHECKER
    Out.BiNormal = cross( Out.Tangent, Out.Normal );
#else
    Out.BiNormal = cross( Out.Tangent, Out.Normal ) * In.Tangent.w; 
#endif

#if USE_LOCAL_POS
    Out.LocalPos = In.Position;
#endif

    return Out;
}