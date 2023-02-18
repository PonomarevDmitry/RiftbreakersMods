#include "materials/programs/utils.hlsl"
#include "materials/programs/pack_ops.hlsl"

cbuffer FPConstantBuffer : register(b0)
{
    float       cGlowAmount;
    float       cMIPBias;
};

struct VS_OUTPUT
{
    float4      Position      : SV_POSITION;
    float2      UV0           : TEXCOORD0;
    float3      Normal        : TEXCOORD1;
    float3      Tangent       : TEXCOORD2;
    float3      BiNormal      : TEXCOORD3;
    float3      BlendWeight   : TEXCOORD4;
};

struct PS_OUTPUT
{
    float4      GBuffer0      : SV_TARGET0; // Albedo (xyz), 
    float4      GBuffer1      : SV_TARGET1; // World Space Normal (xyz)
    float4      GBuffer2      : SV_TARGET2; // Occlusion (x), Roughness (y), Metalness (z)
    float4      GBuffer3      : SV_TARGET3; // Emissive (xyz)
    float4      GBuffer4      : SV_TARGET4; // SubsurfaceScattering (xyz)
};

SamplerState    sAlbedoTex1;
Texture2D       tAlbedoTex1;
SamplerState    sNormalTex1;
Texture2D       tNormalTex1;
SamplerState    sPackedTex1;
Texture2D       tPackedTex1;
SamplerState    sEmissiveTex1;
Texture2D       tEmissiveTex1;

#if TEXTURES_COUNT >= 2
SamplerState    sAlbedoTex2;
Texture2D       tAlbedoTex2;
SamplerState    sNormalTex2;
Texture2D       tNormalTex2;
SamplerState    sPackedTex2;
Texture2D       tPackedTex2;
SamplerState    sEmissiveTex2;
Texture2D       tEmissiveTex2;
#endif

#if TEXTURES_COUNT >= 3
SamplerState    sAlbedoTex3;
Texture2D       tAlbedoTex3;
SamplerState    sNormalTex3;
Texture2D       tNormalTex3;
SamplerState    sPackedTex3;
Texture2D       tPackedTex3;
SamplerState    sEmissiveTex3;
Texture2D       tEmissiveTex3;
#endif

PS_OUTPUT mainFP( VS_OUTPUT In )
{
    PS_OUTPUT Out;

    float w0 = In.BlendWeight.x;
    float w1 = In.BlendWeight.y;
    float w2 = In.BlendWeight.z;

    float3 normal = float3( 0,0,0 );
    float3 albedo = float3( 0,0,0 );
    float3 material = float3( 0,0,0 );
    float3 emissive = float3( 0,0,0 );

    float MipBiasNormal = cMIPBias * 0.5;

    if ( w0 > 0 )
    {
        albedo += tAlbedoTex1.SampleBias( sAlbedoTex1, In.UV0, cMIPBias).xyz * w0;
        normal += texNormal2DBias( tNormalTex1, sNormalTex1, In.UV0, MipBiasNormal ) * w0;
        material += tPackedTex1.SampleBias( sPackedTex1, In.UV0, cMIPBias).xyz * w0;
        emissive += tEmissiveTex1.SampleBias( sEmissiveTex1, In.UV0, cMIPBias).xyz * w0;
    }

#if TEXTURES_COUNT >= 2
    if ( w1 > 0 )
    {
        albedo += tAlbedoTex2.SampleBias( sAlbedoTex2, In.UV0, cMIPBias).xyz * w1;
        normal += texNormal2DBias( tNormalTex2, sNormalTex2, In.UV0, MipBiasNormal ) * w1;
        material += tPackedTex2.SampleBias( sPackedTex2, In.UV0, cMIPBias).xyz * w1;
        emissive += tEmissiveTex2.SampleBias( sEmissiveTex2, In.UV0, cMIPBias).xyz * w1;
    }
#endif
#if TEXTURES_COUNT >= 3
    if ( w2 > 0 )
    {
        albedo += tAlbedoTex3.SampleBias( sAlbedoTex3, In.UV0, cMIPBias).xyz * w2;
        normal += texNormal2DBias( tNormalTex3, sNormalTex3, In.UV0, MipBiasNormal ) * w2;
        material += tPackedTex3.SampleBias( sPackedTex3, In.UV0, cMIPBias).xyz * w2;
        emissive += tEmissiveTex3.SampleBias( sEmissiveTex3, In.UV0, cMIPBias).xyz * w2;
    }
#endif

    Out.GBuffer0.xyzw = float4( albedo.xyz, 1.0f );
    Out.GBuffer2.xyz = material;
    Out.GBuffer3.xyz = emissive * cGlowAmount;
    Out.GBuffer4.xyzw = 0.0f;

    float3x3 normalRotation = float3x3( In.BiNormal, In.Tangent, In.Normal );
    Out.GBuffer1.xyz = encodeNormal( mul( normal, normalRotation ).xyz );
    return Out;
}