cbuffer VPConstantBuffer
{
    float4 cViewportSize;
};

struct VS_OUTPUT
{
    float4  Position    : SV_POSITION;
    float4  TexCoord    : TEXCOORD0;
};

#define SUBPIX_SHIFT (1.0/4.0)

VS_OUTPUT main_vp( uint id : SV_VERTEXID )
{
    VS_OUTPUT Out;
    
	float2 rcp_frame = float2(1.0 / cViewportSize.x, 1.0 / cViewportSize.y);
    Out.TexCoord.xy = float2(id & 2, (id << 1) & 2);
	Out.TexCoord.zw = Out.TexCoord.xy - (rcp_frame * (0.5 + SUBPIX_SHIFT));
    Out.Position = float4(Out.TexCoord.xy * float2(2.0, -2.0) + float2(-1.0, 1.0), 0.0, 1.0);

    return Out;
}