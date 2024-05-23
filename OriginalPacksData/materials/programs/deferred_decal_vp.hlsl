cbuffer VPConstantBuffer : register(b0)
{
#if USE_INSTANCING
    float4  cInstanceInfo; // offset, stride
#else
    matrix  cWorld;
#   if USE_VELOCITY
    matrix  cPrevWorld;
#   endif
#endif
    matrix  cViewProj;
#if USE_VELOCITY
    matrix  cPrevViewProj;
#endif
};

struct VS_INPUT
{
    float4  Position      : POSITION;
    float2  TexCoord      : TEXCOORD0;
#if USE_INSTANCING
    uint    InstanceId    : SV_InstanceID;
#endif
};

struct VS_OUTPUT
{
    float4  Position      : SV_POSITION;
    float4  ProjPos       : TEXCOORD0;
    float3  Normal        : TEXCOORD1;
    float3  Tangent       : TEXCOORD2;
    float3  BiNormal      : TEXCOORD3;
    float2  TexCoord      : TEXCOORD4;
#if USE_VELOCITY
    float4  PrevPos       : TEXCOORD5;
#endif
#if USE_WORLD_POS
    float3  WorldPos      : TEXCOORD6;
#endif
};

#if USE_INSTANCING
StructuredBuffer<float4> bInstanceData;
#endif

VS_OUTPUT mainVP( VS_INPUT In )
{
    VS_OUTPUT Out;

#if USE_INSTANCING
    uint instanceDataAddr = uint( cInstanceInfo.x ) + uint( cInstanceInfo.y ) * In.InstanceId;
    float3x4 cWorld = { bInstanceData[ instanceDataAddr + 0 ], bInstanceData[ instanceDataAddr + 1 ], bInstanceData[ instanceDataAddr + 2 ] };
#   if USE_VELOCITY
    float3x4 cPrevWorld = { bInstanceData[ instanceDataAddr + 3 ], bInstanceData[ instanceDataAddr + 4 ], bInstanceData[ instanceDataAddr + 5 ] };
#   endif
#endif

    float4 worldPos = float4( mul( cWorld, In.Position ).xyz, 1.0f );
    Out.Position = mul( cViewProj, worldPos );
#if USE_WORLD_POS
    Out.WorldPos = worldPos;
#endif

    Out.Normal = normalize( mul( cWorld, float4( 0, 1, 0, 0 ) ).xyz );
    Out.Tangent = normalize( mul( cWorld, float4( 1, 0, 0, 0 ) ).xyz );

#if USE_VELOCITY
    float4 prevWorldPos = float4( mul( cPrevWorld, In.Position ).xyz, 1.0f );
    Out.PrevPos = mul( cPrevViewProj, prevWorldPos );
#endif
    Out.ProjPos = Out.Position;
    Out.BiNormal = cross( Out.Normal, Out.Tangent );
    Out.TexCoord = In.TexCoord;
                                                                                                 
    return Out;
}
