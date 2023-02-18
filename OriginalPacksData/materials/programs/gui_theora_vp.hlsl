cbuffer WVPConstantBuffer : register(b0)
{
    matrix cWorldViewProj; 
    float4 cTexelOffset;
};

struct VS_INPUT
{
    float4 Position     : POSITION;    
	float4 Color        : COLOR;
    float2 TexCoord     : TEXCOORD0;    
};

struct VS_OUTPUT
{
    float4 Position     : SV_POSITION;    
	float4 Color        : COLOR;
    float2 TexCoord     : TEXCOORD0;
};

VS_OUTPUT mainVP( VS_INPUT In )
{
    VS_OUTPUT Output;

    float4 pos = mul( cWorldViewProj, In.Position );
    pos.x += 2.0 * cTexelOffset.z;
    pos.y -= 2.0 * cTexelOffset.w;

    Output.TexCoord = In.TexCoord;
    Output.Position = pos;
	Output.Color = In.Color;
	
    return Output;
}
