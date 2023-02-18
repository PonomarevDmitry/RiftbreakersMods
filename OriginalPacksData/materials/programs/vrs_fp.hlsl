static const uint D3D12_SHADING_RATE_1X1 = 0;
static const uint D3D12_SHADING_RATE_1X2 = 0x1;
static const uint D3D12_SHADING_RATE_2X1 = 0x4;
static const uint D3D12_SHADING_RATE_2X2 = 0x5;
static const uint D3D12_SHADING_RATE_2X4 = 0x6;
static const uint D3D12_SHADING_RATE_4X2 = 0x9;
static const uint D3D12_SHADING_RATE_4X4 = 0xa;

static const uint D3D12_AXIS_SHADING_RATE_1X = 0x0;
static const uint D3D12_AXIS_SHADING_RATE_2X = 0x1;
static const uint D3D12_AXIS_SHADING_RATE_4X = 0x2;

#define D3D12_MAKE_COARSE_SHADING_RATE(x,y) ((x << 2) | (y))

Texture2D<uint> inU8 : register(t0);

struct VERTEX_OUT
{
	float4 vPosition : SV_POSITION;
	float2 vTexture : TEXCOORD;
};

cbuffer FPConstantBuffer : register(b0)
{
    float4    cViewportSize;
    float4 	  cTextureSize;
}

float4 mainPS(VERTEX_OUT input) : SV_Target
{
	//int tileSize = asint( g_TileSize );
	int tileSize = round(cViewportSize.x / cTextureSize.x);
	int2 pos = input.vPosition.xy / tileSize;

	// encode different shading rates as colors
	float3 color = float3(1, 1, 1);

	switch (inU8[pos].r)
	{
	case D3D12_SHADING_RATE_1X1:
		color = float3(0.5, 0.0, 0.0);
		break;
	case D3D12_SHADING_RATE_1X2:
		color = float3(0.5, 0.5, 0.0);
		break;
	case D3D12_SHADING_RATE_2X1:
		color = float3(0.5, 0.25, 0.0);
		break;
	case D3D12_SHADING_RATE_2X2:
		color = float3(0.0, 0.5, 0.0);
		break;
	case D3D12_SHADING_RATE_2X4:
		color = float3(0.25, 0.25, 0.5);
		break;
	case D3D12_SHADING_RATE_4X2:
		color = float3(0.5, 0.25, 0.5);
		break;
	case D3D12_SHADING_RATE_4X4:
		color = float3(0.0, 0.5, 0.5);
		break;
	}

	// add grid
	int2 grid = int2(input.vPosition.xy) % tileSize;
	bool border = (grid.x == 0) || (grid.y == 0);

	return float4(color, 0.5) * (border ? 0.5f : 1.0f);
}

