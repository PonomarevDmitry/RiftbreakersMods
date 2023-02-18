cbuffer FPConstantBuffer : register(b0)
{
    float4    cViewportSize;
    float4 	  cTextureSize;
}

#define A_GPU 1
#define A_HLSL 1

Texture2D InputTexture;
RWTexture2D<float4> OutputTexture;

#include "materials/programs/cas_compat.hlsl"


inline float3 accurateSRGBToLinear(in float3 sRGBCol )
{
    float3 linearRGBLo = sRGBCol / 12.92;
    float3 linearRGBHi = pow (( sRGBCol + 0.055) / 1.055 , 2.4) ;
    float3 linearRGB = ( sRGBCol <= 0.04045) ? linearRGBLo : linearRGBHi ;
    return linearRGB;
}

inline float3 accurateLinearToSRGB(in float3 linearCol )
{
    float3 sRGBLo = linearCol * 12.92;
    float3 sRGBHi = ( pow( abs ( linearCol ) , 1.0/2.4) * 1.055) - 0.055;
    float3 sRGB = ( linearCol <= 0.0031308) ? sRGBLo : sRGBHi ;
    return sRGB;
} 

AF3 CasLoad(ASU2 p) 
{ 
	AF3 c = InputTexture.Load(int3(p, 0)).rgb; 
	c = accurateSRGBToLinear( c );
	return c;
}

void CasInput(inout AF1 r, inout AF1 g, inout AF1 b) {}

#include "materials/programs/cas_utils.hlsl"

[numthreads(64, 1, 1)]
void mainCS(uint3 LocalThreadId : SV_GroupThreadID, uint3 WorkGroupId : SV_GroupID)
{
 	uint4 const0, const1;
 	CasSetup( const0, const1, 0.0f, cTextureSize.x, cTextureSize.y, cViewportSize.x, cViewportSize.y );

	AU2 gxy = ARmp8x8(LocalThreadId.x) + AU2(WorkGroupId.x << 4u, WorkGroupId.y << 4u);

	AF3 c;
	CasFilter(c.r, c.g, c.b, gxy, const0, const1, false );
	c.xyz = accurateLinearToSRGB( c.xyz );
	OutputTexture[ASU2(gxy)] = AF4(c, 1);
	gxy.x += 8u;

	CasFilter(c.r, c.g, c.b, gxy, const0, const1, false );
	c.xyz = accurateLinearToSRGB( c.xyz );
	OutputTexture[ASU2(gxy)] = AF4(c, 1);
	gxy.y += 8u;

	CasFilter(c.r, c.g, c.b, gxy, const0, const1, false );
	c.xyz = accurateLinearToSRGB( c.xyz );
	OutputTexture[ASU2(gxy)] = AF4(c, 1);
	gxy.x -= 8u;

	CasFilter(c.r, c.g, c.b, gxy, const0, const1, false );
	c.xyz = accurateLinearToSRGB( c.xyz );
	OutputTexture[ASU2(gxy)] = AF4(c, 1);
}
