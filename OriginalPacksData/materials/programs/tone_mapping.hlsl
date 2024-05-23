#include "materials/programs/utils_pack.hlsl"
#include "materials/programs/utils_pbr.hlsl"

static const float3x3 ACESInputMat =
{
    { 0.59719, 0.35458, 0.04823 },
    { 0.07600, 0.90834, 0.01566 },
    { 0.02840, 0.13383, 0.83777 }
};

// ODT_SAT => XYZ => D60_2_D65 => sRGB
static const float3x3 ACESOutputMat =
{
    { 1.60475, -0.53108, -0.07367 },
    { -0.10208,  1.10813, -0.00605 },
    { -0.00327, -0.07276,  1.07602 }
};

float3 RRTAndODTFit(float3 v)
{
    float3 a = v * (v + 0.0245786f) - 0.000090537f;
    float3 b = v * (0.983729f * v + 0.4329510f) + 0.238081f;
    return a / b;
}

float3 tone_ACES( float3 x )
{
    float3 filmic = mul(ACESInputMat, x);
    filmic = RRTAndODTFit(filmic);
    filmic = mul(ACESOutputMat, filmic);
    filmic = saturate(filmic);
    return filmic;
}

struct VS_OUTPUT
{
    float4      Position    : SV_POSITION;
    float2      TexCoord    : TEXCOORD0;
};

struct PS_OUTPUT
{
    float4      Color0      : SV_TARGET;
};

Texture2D       tMain       : register( t0 );
SamplerState    sMain       : register( s0 );
Texture2D       tDistortion : register( t1 );
SamplerState    sDistortion : register( s1 );

PS_OUTPUT mainFP( VS_OUTPUT In )
{
    PS_OUTPUT Out;
    const float2 offset = tDistortion.Sample( sDistortion, In.TexCoord ).xy;
    const float2 texCoord = In.TexCoord - offset;
    Out.Color0.xyz = tone_ACES( tMain.Sample( sMain, texCoord ).xyz );
    Out.Color0.xyz = LinearToSRGB( Out.Color0.xyz );
    Out.Color0.xyz = pow( Out.Color0.xyz, 1.0f / 1.2f );
    Out.Color0.a = dot( Out.Color0.rgb, float3( 0.299, 0.587, 0.114 ) ); // luminance
    return Out;
}
