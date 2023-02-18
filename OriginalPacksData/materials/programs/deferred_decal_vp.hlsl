cbuffer VPConstantBuffer : register(b0)
{
#if USE_INSTANCING
    float4  cInstanceInfo; // offset, stride
    matrix  cViewProj;
#else
    matrix  cWorld;
    matrix  cViewProj;
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
};

#if USE_INSTANCING
StructuredBuffer<float4> bInstanceData;
#endif

VS_OUTPUT mainVP( VS_INPUT In )
{
    VS_OUTPUT Out;

#if USE_INSTANCING
    uint instanceDataAddr = uint(cInstanceInfo.x) + uint(cInstanceInfo.y) * In.InstanceId;

    float3x4 world;
    world[0] = bInstanceData[ instanceDataAddr + 0 ];
    world[1] = bInstanceData[ instanceDataAddr + 1 ];
    world[2] = bInstanceData[ instanceDataAddr + 2 ];

    float4 worldPos = float4( mul( world, In.Position.xyz ), 1.0f );
    Out.Position = mul( cViewProj, worldPos );
    Out.Normal = normalize( mul( world, float3( 0, 1, 0 ) ) );
    Out.Tangent = normalize( mul( world, float3( 1, 0, 0 ) ) );
#else
    float4 worldPos = mul( cWorld, float4( In.Position.xyz, 1.0f ) );
    Out.Position = mul( cViewProj, worldPos );
    Out.Normal = normalize( mul( cWorld, float4( 0, 1, 0, 0 ) ).xyz );
    Out.Tangent = normalize( mul( cWorld, float4( 1, 0, 0, 0 ) ).xyz );
#endif

    Out.ProjPos = Out.Position;
    Out.BiNormal = cross( Out.Normal, Out.Tangent );
    Out.TexCoord = In.TexCoord;
                                                                                                 
    return Out;
}
