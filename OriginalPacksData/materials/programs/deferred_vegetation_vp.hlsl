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
    float3      Normal          : NORMAL;
    float2      UV0             : TEXCOORD0;
    float4      Tangent         : TANGENT0;
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

    float4 vPos = float4( In.Position.xyz, 1.0f );
    float3 vNormal = In.Normal;

    MainBending( vPos, cBendingInfo.xy );
#if USE_DEFORM
    VertexDeform( vPos, vNormal, In.Color.xyz, cDeform.x, cDeform.y, cTime );
#endif

    float4 worldPos = mul( cWorld, vPos );

    Out.Position = mul( cViewProj, worldPos );
    Out.UV0 = In.UV0.xy;
    Out.WorldPos = worldPos.xyz;
    Out.Normal = normalize( mul( cWorld, float4( vNormal, 0.0 ) ).xyz );
    Out.Tangent = normalize( mul( cWorld, float4( In.Tangent.xyz, 0.0 ) ).xyz );
    Out.BiNormal = cross( Out.Tangent, Out.Normal ) * In.Tangent.w;

    return Out;
}