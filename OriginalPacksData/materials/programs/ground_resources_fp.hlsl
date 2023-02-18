#include "materials/programs/utils.hlsl"
#include "materials/programs/pack_ops.hlsl"

cbuffer PSConstantBuffer : register(b0)
{
    float       cGlowFactor;
    float       cAlpha;
    float       cMIPBias;
}

struct VS_OUTPUT
{
    float4      Position      : SV_POSITION;
    float2      UV0           : TEXCOORD0;
    float3      Normal        : TEXCOORD1;
    float3      Tangent       : TEXCOORD2;
    float3      BiNormal      : TEXCOORD3;
    float3      WorldPos      : TEXCOORD4;
    float       Alpha         : TEXCOORD5;
};

struct PS_OUTPUT
{
    float4      GBuffer0      : SV_TARGET0; // Albedo (xyz), 
    float4      GBuffer1      : SV_TARGET1; // World Space Normal (xyz)
    float4      GBuffer2      : SV_TARGET2; // Occlusion (x), Roughness (y), Metalness (z)
    float4      GBuffer3      : SV_TARGET3; // Emissive (xyz)
    float4      GBuffer4      : SV_TARGET4; // SubsurfaceScattering (xyz)
};

Texture2D       tAlbedoTex;
SamplerState    sAlbedoTex;
Texture2D       tNormalTex;
SamplerState    sNormalTex;
Texture2D       tPackedTex;
SamplerState    sPackedTex;
Texture2D       tEmissiveTex;
SamplerState    sEmissiveTex;

PS_OUTPUT mainFP( VS_OUTPUT In )
{
    PS_OUTPUT Out;

    float4 albedo = tAlbedoTex.SampleBias( sAlbedoTex, In.UV0, cMIPBias );

    float vAlpha = clamp(In.Alpha, 0,1);
    float alpha = albedo.w;
    alpha *= vAlpha * vAlpha;

    Out.GBuffer0 = albedo;
    Out.GBuffer0.w = alpha;

    Out.GBuffer2 = tPackedTex.SampleBias( sPackedTex, In.UV0, cMIPBias );
    Out.GBuffer2.w = alpha;

    float MipBiasNormal = cMIPBias * 0.5;

    float3 texNormal = texNormal2DBias( tNormalTex, sNormalTex, In.UV0, MipBiasNormal );
    float3x3 normalRotation = float3x3( In.Tangent, In.BiNormal, In.Normal );
    Out.GBuffer1.xyz = encodeNormal( mul( texNormal, normalRotation ).xyz );
    Out.GBuffer1.w = alpha;

    Out.GBuffer3 = cGlowFactor * tEmissiveTex.Sample( sEmissiveTex, In.UV0 );
    Out.GBuffer3.w = alpha;

    Out.GBuffer4 = 0.0f;
    Out.GBuffer4.w = alpha;

    return Out;
}
