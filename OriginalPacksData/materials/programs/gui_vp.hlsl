cbuffer VPConstantBuffer : register(b0)
{
    matrix  cWorldViewProj;
    float4  cTexelOffset;
};

struct VS_INPUT
{
    float2  Position    : POSITION;    
    float4  Color       : COLOR;
#if USE_TEXTURE || USE_BLEND_2_TEXTURE
    float2  TexCoord    : TEXCOORD0;
    float4  ChannelMask  : BINORMAL;
#endif
};

struct VS_OUTPUT
{
    float4  Position    : SV_POSITION;
    float4  Color       : COLOR;
#if USE_TEXTURE || USE_BLEND_2_TEXTURE
    float2  TexCoord    : TEXCOORD0;
    float4  ChannelMask : BINORMAL;
#endif
};

VS_OUTPUT mainVP( VS_INPUT In )
{
    VS_OUTPUT Out;

    float4 pos = mul( cWorldViewProj, float4(In.Position, 0.0, 1.0) );
    pos.x += 2.0 * cTexelOffset.z;
    pos.y -= 2.0 * cTexelOffset.w;
    Out.Position = pos;

    Out.Color = In.Color;

#if USE_TEXTURE || USE_BLEND_2_TEXTURE
    Out.TexCoord = In.TexCoord;
    Out.ChannelMask = In.ChannelMask;
#endif
    return Out;
}
