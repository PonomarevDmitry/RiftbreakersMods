// FidelityFX Super Resolution Sample
//
// Copyright (c) 2021 Advanced Micro Devices, Inc. All rights reserved.
//
// This file is part of the FidelityFX Super Resolution beta which is 
// released under the BETA SOFTWARE EVALUATION LICENSE AGREEMENT.
//
// See file LICENSE.txt for full license details.

cbuffer cb : register(b0)
{
    float4    cViewportSize;
    float4 	  cTextureSize;
};

#define A_GPU 1
#define A_HLSL 1

SamplerState		samLinearClamp : register(s0);

#if FP16_SUPPORT
	#define A_HALF
	#include "materials/programs/fsr_compat.hlsl"
	Texture2D<AH4> InputTexture : register(t0);
	RWTexture2D<AH4> OutputTexture : register(u0);
	#define FSR_EASU_H 1
	AH4 FsrEasuRH(AF2 p) { AH4 res = InputTexture.GatherRed(samLinearClamp, p, int2(0, 0)); return res; }
	AH4 FsrEasuGH(AF2 p) { AH4 res = InputTexture.GatherGreen(samLinearClamp, p, int2(0, 0)); return res; }
	AH4 FsrEasuBH(AF2 p) { AH4 res = InputTexture.GatherBlue(samLinearClamp, p, int2(0, 0)); return res; }
#else
	#include "materials/programs/fsr_compat.hlsl"
	Texture2D InputTexture : register(t0);
	RWTexture2D<float4> OutputTexture : register(u0);
	#define FSR_EASU_F 1
	AF4 FsrEasuRF(AF2 p) { AF4 res = InputTexture.GatherRed(samLinearClamp, p, int2(0, 0)); return res; }
	AF4 FsrEasuGF(AF2 p) { AF4 res = InputTexture.GatherGreen(samLinearClamp, p, int2(0, 0)); return res; }
	AF4 FsrEasuBF(AF2 p) { AF4 res = InputTexture.GatherBlue(samLinearClamp, p, int2(0, 0)); return res; }
#endif

#include "materials/programs/fsr_internal.hlsl"

void CurrFilter(int2 pos, AU4 Const0, AU4 Const1, AU4 Const2, AU4 Const3)
{
#if FP16_SUPPORT
	AH3 c;
	FsrEasuH(c, pos, Const0, Const1, Const2, Const3);
	OutputTexture[pos] = AH4(c, 1);
#else
	AF3 c;
	FsrEasuF(c, pos, Const0, Const1, Const2, Const3);
	OutputTexture[pos] = float4(c, 1);
#endif
}

[numthreads(64, 1, 1)]
void mainCS(uint3 LocalThreadId : SV_GroupThreadID, uint3 WorkGroupId : SV_GroupID, uint3 Dtid : SV_DispatchThreadID)
{
	AU4 const0, const1, const2, const3;
	FsrEasuCon(
		const0, const1, const2, const3,		// The calculated constants.
		cTextureSize.x, cTextureSize.y,		// Viewport size (top left aligned) in the input image which is to be scaled.
		cTextureSize.x, cTextureSize.y,		// The size of the input image.
		cViewportSize.x, cViewportSize.y ); // The output resolution.

	// Do remapping of local xy in workgroup for a more PS-like swizzle pattern.
	AU2 gxy = ARmp8x8(LocalThreadId.x) + AU2(WorkGroupId.x << 4u, WorkGroupId.y << 4u);
	CurrFilter(gxy, const0, const1, const2, const3);
	gxy.x += 8u;
	CurrFilter(gxy, const0, const1, const2, const3);
	gxy.y += 8u;
	CurrFilter(gxy, const0, const1, const2, const3);
	gxy.x -= 8u;
	CurrFilter(gxy, const0, const1, const2, const3);
}

