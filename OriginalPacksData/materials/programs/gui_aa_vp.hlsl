cbuffer VPConstantBuffer : register(b0)
{
    matrix  cWorldViewProj;
    float4  cTexelOffset;
	float4  cViewportSize;
};

struct VS_INPUT
{
    float2  Position    : POSITION;
	float2  Pivot    	: NORMAL;
    float4  Color       : COLOR;
#if USE_TEXTURE
    float2  TexCoord    : TEXCOORD0;
#endif
};

struct VS_OUTPUT
{
    float4  Position    : SV_POSITION;
    float4  Color       : COLOR;
#if USE_TEXTURE
    float2  TexCoord    : TEXCOORD0;
#endif
};

VS_OUTPUT mainVP( VS_INPUT In )
{
    VS_OUTPUT Out;

    float4 position = mul( cWorldViewProj, float4(In.Position, 0.0, 1.0) ); // UDC
	float4 pivot = mul( cWorldViewProj, float4(In.Pivot, 0.0, 1.0) ); // UDC
	position.x += 2.0 * cTexelOffset.z;
    position.y -= 2.0 * cTexelOffset.w;

	float2 pivotRound = float2( round( pivot.x * cViewportSize.x * 0.5 +0.001 ), round( pivot.y * cViewportSize.y * 0.5 +0.001 ) );
	float2 pivotRoundUDC = 2.0 * pivotRound * cViewportSize.zw;
	float2 pivotDelta = pivot - pivotRoundUDC; // UDC
	position.y -= pivotDelta.y;

    Out.Position = position;
    Out.Color = In.Color;

#if USE_TEXTURE
    Out.TexCoord = In.TexCoord;
#endif
    return Out;
}
