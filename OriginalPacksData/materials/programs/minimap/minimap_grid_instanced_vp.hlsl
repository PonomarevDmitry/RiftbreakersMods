cbuffer VPConstantBuffer
{
    int cGridWidth;
    int cGridHeight;
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
    int x = In.InstanceId % cGridWidth;
    int z = In.InstanceId / cGridWidth;

    float3 origin = float3( -cGridWidth, 0.0, -cGridHeight );
    float3 position = origin + float3( x * 2.0 + 1.0, 0.0, z * 2.0 + 1.0 );

    VS_OUTPUT Out;
    Out.Flags = bInstanceData[ In.InstanceId ];
    Out.Position = float4(position, 1.0 );

    return Out;
}