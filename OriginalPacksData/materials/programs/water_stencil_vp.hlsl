cbuffer VPConstantBuffer : register(b0)
{
    matrix   cWorldViewProj;
};

struct VS_INPUT
{
    float3      Position      : POSITION;
};

struct VS_OUTPUT
{
    float4      Position      : SV_POSITION;
};

VS_OUTPUT water_stencil_vp( VS_INPUT In )
{
    VS_OUTPUT Out;
    Out.Position = mul( cWorldViewProj, float4( In.Position, 1.0 ) );
    return Out;
}
