/**********************************************************************
Copyright (c) 2019 Advanced Micro Devices, Inc. All rights reserved.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
********************************************************************/

#include "denoiser_utils_d3d12.hlsl"

cbuffer PassData : register(b0)
{
    float4 BufferDimensions;
#if UPSCALE
    float4 InputDimensions;
#endif
}

Texture2D<uint> RaytracerResult : register(t0);

RWStructuredBuffer<uint> ShadowMask : register(u0);

#if UPSCALE
void CopyResult(uint2 gtid, uint2 gid, float scale)
#else
void CopyResult(uint2 gtid, uint2 gid)
#endif
{
    const uint2 did = gid * uint2(8, 4) + gtid;
    const uint linear_tile_index = LinearTileIndex(gid, uint(BufferDimensions.x));
#if UPSCALE
    const bool hit_light = RaytracerResult[did * scale] > 0;
#else
    const bool hit_light = RaytracerResult[did] > 0;
#endif
    const uint lane_mask = hit_light ? GetBitMaskFromPixelPosition(did) : 0;
    ShadowMask[linear_tile_index] = WaveActiveBitOr(lane_mask);
}

[numthreads(8, 4, 1)]
void main(uint2 gtid : SV_GroupThreadID, uint2 gid : SV_GroupID)
{
#if UPSCALE
    const float scale = InputDimensions.x / BufferDimensions.x;
#endif
    gid *= 4;
    uint2 tile_dimensions = (uint2(BufferDimensions.xy) + uint2(7, 3)) / uint2(8, 4);

    for (int i = 0; i < 4; ++i)
    {
        for (int j = 0; j < 4; ++j)
        {
            uint2 tile_id = uint2(gid.x + i, gid.y + j);
            tile_id = clamp(tile_id, uint2(0,0), tile_dimensions - 1);
#if UPSCALE
            CopyResult(gtid, tile_id, scale);
#else
            CopyResult(gtid, tile_id);
#endif
        }
    }
}
