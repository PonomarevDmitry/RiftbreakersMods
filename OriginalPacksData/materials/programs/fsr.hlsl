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
	uint4 Const0;
	uint4 Const1;
	uint4 Const2;
	uint4 Const3;
};

#define A_GPU 1
#define A_HLSL 1

SamplerState		samLinearClamp : register(s0);

#if FP16_SUPPORT
	#define A_HALF
	#include "ffx_a.h"
	Texture2D<AH4> InputTexture : register(t0);
	RWTexture2D<AH4> OutputTexture : register(u0);
	#define FSR_EASU_H 1
	AH4 FsrEasuRH(AF2 p) { AH4 res = InputTexture.GatherRed(samLinearClamp, p, int2(0, 0)); return res; }
	AH4 FsrEasuGH(AF2 p) { AH4 res = InputTexture.GatherGreen(samLinearClamp, p, int2(0, 0)); return res; }
	AH4 FsrEasuBH(AF2 p) { AH4 res = InputTexture.GatherBlue(samLinearClamp, p, int2(0, 0)); return res; }
#else
	#include "ffx_a.h"
	Texture2D InputTexture : register(t0);
	RWTexture2D<float4> OutputTexture : register(u0);
	#define FSR_EASU_F 1
	AF4 FsrEasuRF(AF2 p) { AF4 res = InputTexture.GatherRed(samLinearClamp, p, int2(0, 0)); return res; }
	AF4 FsrEasuGF(AF2 p) { AF4 res = InputTexture.GatherGreen(samLinearClamp, p, int2(0, 0)); return res; }
	AF4 FsrEasuBF(AF2 p) { AF4 res = InputTexture.GatherBlue(samLinearClamp, p, int2(0, 0)); return res; }
#endif

#include "ffx_fsr1.h"

void CurrFilter(int2 pos)
{
#if SAMPLE_NEAREST
	AF2 pp = AF2(pos) * AF2_AU2(Const0.xy) + AF2_AU2(Const1.zw);
	OutputTexture[pos] = InputTexture.Load(int3(int2(pp + AF2(0.01, 0.01)), 0));
#else
	#if FP16_SUPPORT
		AH3 c;
		FsrEasuH(c, pos, Const0, Const1, Const2, Const3);
		OutputTexture[pos] = AH4(c, 1);
	#else
		AF3 c;
		FsrEasuF(c, pos, Const0, Const1, Const2, Const3);
		OutputTexture[pos] = float4(c, 1);
	#endif
#endif
}

[numthreads(WIDTH, HEIGHT, DEPTH)]
void mainCS(uint3 LocalThreadId : SV_GroupThreadID, uint3 WorkGroupId : SV_GroupID, uint3 Dtid : SV_DispatchThreadID)
{
	// Do remapping of local xy in workgroup for a more PS-like swizzle pattern.
	AU2 gxy = ARmp8x8(LocalThreadId.x) + AU2(WorkGroupId.x << 4u, WorkGroupId.y << 4u);
	CurrFilter(gxy);
	gxy.x += 8u;
	CurrFilter(gxy);
	gxy.y += 8u;
	CurrFilter(gxy);
	gxy.x -= 8u;
	CurrFilter(gxy);
}

