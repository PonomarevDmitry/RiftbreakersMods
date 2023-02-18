#include "materials/programs/utils.hlsl"
#include "materials/programs/pack_ops.hlsl"

cbuffer FPConstantBuffer : register(b0)
{    
    float4      cFresnelColor;
    float       cFresnelBias;
    float       cFresnelScale;
    float       cFresnelPower;
    float       cGlowAmount;
    float       cGlowFactor;
    float3      cWorldCameraPos;
    float       cTime;
    float       cMIPBias;
};

struct VS_OUTPUT
{
    float4      Position      : SV_POSITION;
    float2      UV0           : TEXCOORD0;
    float3      Normal        : TEXCOORD1;
    float3      Tangent       : TEXCOORD2;
    float3      BiNormal      : TEXCOORD3;
    float3      WorldPos      : TEXCOORD4;
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
Texture2D       tGradientTex;
SamplerState    sGradientTex;
Texture2D       tSlantTex;
SamplerState    sSlantTex;

PS_OUTPUT mainFP( VS_OUTPUT In )
{
    PS_OUTPUT Out;

    float4 albedo = tAlbedoTex.SampleBias( sAlbedoTex, In.UV0, cMIPBias ).xyzw;

    Out.GBuffer0.xyzw = float4( albedo.xyz, 1.0f );
    Out.GBuffer2.xyz = tPackedTex.SampleBias( sPackedTex, In.UV0, cMIPBias ).xyz;

    float3 texNormal = texNormal2D( tNormalTex, sNormalTex, In.UV0 );
    float3x3 normalRotation = float3x3( In.Tangent, In.BiNormal, In.Normal );
    Out.GBuffer1.xyz = encodeNormal( mul( texNormal, normalRotation ).xyz );

    float2 worldPos;
    worldPos.x = ( In.WorldPos.x + cTime * 2.0 );
    worldPos.y = ( In.WorldPos.z + cTime * 2.0 );

    float emissive = calcFresnel( cFresnelBias, cFresnelScale, cFresnelPower, normalize( In.WorldPos - cWorldCameraPos ), In.Normal );
    emissive *= max( cGlowFactor, tSlantTex.Sample( sSlantTex, worldPos / 20.0 ).x * ( ( ( cos( cTime * 1.2 ) ) + 1 ) / 2.0 ) );
    emissive *= tGradientTex.Sample( sGradientTex, In.UV0 ).x * cGlowAmount;
    Out.GBuffer3.xyz = cFresnelColor.xyz * emissive;
    Out.GBuffer3.xyz += cGlowAmount * tEmissiveTex.Sample( sEmissiveTex, In.UV0 ).xyz;
    Out.GBuffer4 = 0.0f;

    return Out;
}
