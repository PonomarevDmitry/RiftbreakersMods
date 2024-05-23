// FidelityFX Super Resolution Sample
//
// Copyright (c) 2021 Advanced Micro Devices, Inc. All rights reserved.
//
// This file is part of the FidelityFX Super Resolution beta which is 
// released under the BETA SOFTWARE EVALUATION LICENSE AGREEMENT.
//
// See file LICENSE.txt for full license details.

cbuffer FPConstantBuffer
{
	float       cSharpness;
};

#define A_GPU 1
#define A_HLSL 1

#if FP16_SUPPORT
	#define A_HALF
	#include "materials/programs/fsr_compat.hlsl"
	Texture2D<AH4> InputTexture : register(t0);
	RWTexture2D<AH4> OutputTexture : register(u0);
	#define FSR_RCAS_H 1
	void FsrRcasInputH(inout AH1 r, inout AH1 g, inout AH1 b) {}
	AH4 FsrRcasLoadH(ASW2 p) { return InputTexture.Load(ASW3(ASW2(p), 0)); }
#else
	#include "materials/programs/fsr_compat.hlsl"
	Texture2D InputTexture;
	RWTexture2D<float4> OutputTexture;
	#define FSR_RCAS_F 1
	void FsrRcasInputF(inout AF1 r, inout AF1 g, inout AF1 b) {}
	AF4 FsrRcasLoadF(ASU2 p) { return InputTexture.Load(int3(p, 0)); }
#endif

#include "materials/programs/fsr_internal.hlsl"

void CurrFilter(int2 pos, AU4 Const0)
{
#if FP16_SUPPORT
	AH3 c;
	FsrRcasH(c.r, c.g, c.b, pos, Const0);
	OutputTexture[pos] = AH4(c, 1);
#else
	AF3 c;
	FsrRcasF(c.r, c.g, c.b, pos, Const0);
	OutputTexture[pos] = float4(c, 1);
#endif
}

[numthreads(64, 1, 1)]
void mainCS(uint3 LocalThreadId : SV_GroupThreadID, uint3 WorkGroupId : SV_GroupID)
{
	AF1 sharpness = cSharpness;
    AU4 const0;
    FsrRcasCon(const0, sharpness);

    // Do remapping of local xy in workgroup for a more PS-like swizzle pattern.
	AU2 gxy = ARmp8x8(LocalThreadId.x) + AU2(WorkGroupId.x << 4u, WorkGroupId.y << 4u);
	CurrFilter(gxy, const0);
	gxy.x += 8u;
	CurrFilter(gxy, const0);
	gxy.y += 8u;
	CurrFilter(gxy, const0);
	gxy.x -= 8u;
	CurrFilter(gxy, const0);
}