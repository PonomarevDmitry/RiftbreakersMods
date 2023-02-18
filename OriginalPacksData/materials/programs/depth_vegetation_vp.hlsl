#include "materials/programs/utils_vegetation.hlsl"

cbuffer VPConstantBuffer : register(b0)
{
    matrix      cViewProj;
#if USE_INSTANCING
    float4      cInstanceInfo; // offset, stride
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
#if USE_INSTANCING
    uint        InstanceId      : SV_InstanceID;
#endif
};

struct VS_OUTPUT
{
    float4      Position        : SV_POSITION;
    float2      UV0             : TEXCOORD0;
};

#if USE_INSTANCING
StructuredBuffer<float4> bInstanceData;
#endif

VS_OUTPUT mainVP( VS_INPUT In )
{
    VS_OUTPUT Out;

#if USE_INSTANCING
    uint instanceDataAddr = uint(cInstanceInfo.x) + uint(cInstanceInfo.y) * In.InstanceId;
    uint instanceMatrixDataAddr = instanceDataAddr + 1;
    float4 cBendingInfo = bInstanceData[ instanceDataAddr ];
    matrix cWorld;
    cWorld[0] = bInstanceData[ instanceMatrixDataAddr + 0 ];
    cWorld[1] = bInstanceData[ instanceMatrixDataAddr + 1 ];
    cWorld[2] = bInstanceData[ instanceMatrixDataAddr + 2 ];
    cWorld[3] = float4( 0.0, 0.0, 0.0, 1.0 );
#endif

    half3 vWorldPos = mul( cWorld, In.Position ).xyz;
    float4 vPos = float4( In.Position.xyz, 1.0f );

    MainBending( vPos, cBendingInfo.xy );

#if USE_DEFORM
    VertexDeform( vPos, In.Normal, In.Color.xyz, cDeform.x, cDeform.y, cTime );
#endif

    float4 worldPos = mul( cWorld, vPos );
    Out.Position = mul( cViewProj, worldPos );
    Out.UV0 = In.UV0.xy;

    return Out;
}