cbuffer VPConstantBuffer
{
    float3 cGridOrigin;
    int    cGridSize;
}

struct VS_INPUT
{
    uint    InstanceId  : SV_InstanceID;
};

struct VS_OUTPUT
{
    float4  Position    : SV_POSITION;
    int    Flags        : TEXCOORD0;
};

StructuredBuffer<int> bInstanceData;

VS_OUTPUT mainVP( VS_INPUT In )
{
    int x = In.InstanceId % cGridSize;
    int z = In.InstanceId / cGridSize;

    float3 position = cGridOrigin + float3( x * 2.0 + 1.0, 0.0, z * 2.0 + 1.0 );

    VS_OUTPUT Out;
    Out.Flags = bInstanceData[ In.InstanceId ];
    Out.Position = float4(position, 1.0 );

    return Out;
}