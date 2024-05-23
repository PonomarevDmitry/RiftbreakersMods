cbuffer FPConstantBuffer : register(b0)
{
    float2             cNearFarClip;
};

struct VS_OUTPUT
{
    float4 Position     : SV_POSITION;
    float2 UV0          : TEXCOORD0;
};

Texture2D       tDepth   : register( t0 );
SamplerState    sDepth   : register( s0 );

float mainFP( VS_OUTPUT In ) : SV_TARGET
{
    float zDepth = tDepth.Sample( sDepth, In.UV0.xy ).r;
#if INVERTED_DEPTH_RANGE
    return((cNearFarClip.y * cNearFarClip.x) / (zDepth * (cNearFarClip.x - cNearFarClip.y) - cNearFarClip.x));
#else
    return((cNearFarClip.x * cNearFarClip.y) / (zDepth * (cNearFarClip.y - cNearFarClip.x) - cNearFarClip.y));
#endif
}


