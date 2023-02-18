cbuffer VPConstantBuffer : register(b0)
{
    matrix  cWorldViewProj;
    float4  cTexelOffset;
	float4  cViewportSize;
};

struct VS_INPUT
{
    float4 Position     : POSITION;
    float4 Color        : COLOR0;
    float2 TexCoord     : TEXCOORD0;
    float4 ChannelMask  : BINORMAL;
};

struct VS_OUTPUT
{
    float4  Position    : SV_POSITION;
    float4  Color       : COLOR;
    float2  TexCoord    : TEXCOORD0;
    float4  ChannelMask : BINORMAL;
};

VS_OUTPUT mainVP( VS_INPUT In )
{
    VS_OUTPUT Out;
    
    float4 position = mul( cWorldViewProj, In.Position );

    position.x += 2.0 * cTexelOffset.z;
    position.y -= 2.0 * cTexelOffset.w;
	
    Out.Position = position;
    Out.TexCoord = In.TexCoord;
    Out.Color = In.Color;
    Out.ChannelMask = In.ChannelMask;
    
    return Out;
}
