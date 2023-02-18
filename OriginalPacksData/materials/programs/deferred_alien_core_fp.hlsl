#include "materials/programs/utils.hlsl"
#include "materials/programs/pack_ops.hlsl"

cbuffer FPConstantBuffer : register(b0)
{
    float       cGlowAmount;
    float       cGlowFactor;
    float       cMIPBias;
    float       cTilingFactor;
};

struct VS_OUTPUT
{
    float4      Position      : SV_POSITION;
    float2      UV0           : TEXCOORD0;
    float3      Normal        : TEXCOORD1;
    float3      Tangent       : TEXCOORD2;
    float3      BiNormal      : TEXCOORD3;
    float3      WorldPos      : TEXCOORD4;
    float3      LocalPos      : TEXCOORD5;
};

struct PS_OUTPUT
{
    float4      GBuffer0      : SV_TARGET0; // Albedo (xyz), 
    float4      GBuffer1      : SV_TARGET1; // World Space Normal (xyz)
    float4      GBuffer2      : SV_TARGET2; // Occlusion (x), Roughness (y), Metalness (z)
    float4      GBuffer3      : SV_TARGET3; // Emissive (xyz)
    float4      GBuffer4      : SV_TARGET4; // SubsurfaceScattering (xyz)
};

Texture2D       tBlendTex;
SamplerState    sBlendTex;
Texture2D       tAlbedo1Tex;
SamplerState    sAlbedo1Tex;
Texture2D       tAlbedo2Tex;
SamplerState    sAlbedo2Tex;
Texture2D       tNormal1Tex;
SamplerState    sNormal1Tex;
Texture2D       tNormal2Tex;
SamplerState    sNormal2Tex;
Texture2D       tPacked1Tex;
SamplerState    sPacked1Tex;
Texture2D       tPacked2Tex;
SamplerState    sPacked2Tex;
Texture2D       tEmissive1Tex;
SamplerState    sEmissive1Tex;
Texture2D       tEmissive2Tex;
SamplerState    sEmissive2Tex;
Texture2D       tGradient1Tex;
SamplerState    sGradient1Tex;
Texture2D       tGradient2Tex;
SamplerState    sGradient2Tex;

PS_OUTPUT mainFP( VS_OUTPUT In )
{
    PS_OUTPUT Out;

    float4 albedo = tAlbedo1Tex.SampleBias( sAlbedo1Tex, In.UV0, cMIPBias).xyzw;
    float3 texNormal = texNormal2D( tNormal1Tex, sNormal1Tex, In.UV0);
    float3 emissive = tEmissive1Tex.SampleBias( sEmissive1Tex, In.UV0, cMIPBias).xyz * tGradient1Tex.SampleBias( sGradient1Tex, In.UV0, cMIPBias).x;
    float4 material = tPacked1Tex.SampleBias( sPacked1Tex, In.UV0, cMIPBias);

#if USE_MIPMAP_CHECKER
    float lod = max( 0.0, tAlbedo1Tex.CalculateLevelOfDetail(sAlbedo1Tex,In.UV0) + cMIPBias );
    float4 mipmapChecker = tMipMapCheckerTex.SampleLevel( sMipMapCheckerTex, In.UV0, lod).xyzw;
    albedo.xyz = lerp( albedo.xyz, mipmapChecker.rgb, mipmapChecker.a );
#endif

    float blend = tBlendTex.SampleBias( sBlendTex, float2( ( -In.LocalPos.x + ( 87.99f / 2.0f ) ) / 87.99f, ( -In.LocalPos.z + ( 86.59f / 2.0f ) ) / 86.59f ), cMIPBias ).x;
    if ( blend > 0.0f )
    {   
        float2 blendUV = float2( In.WorldPos.z / cTilingFactor, -In.WorldPos.x / cTilingFactor );
        albedo.xyz = lerp( albedo.xyz, tAlbedo2Tex.SampleBias( sAlbedo2Tex, blendUV, cMIPBias).xyz, blend );
        material = lerp( material, tPacked2Tex.SampleBias( sPacked2Tex, blendUV, cMIPBias), blend );
        float emissiveDiff =  saturate( 0.50 - blend );
        emissive = lerp( emissive, tEmissive2Tex.Sample( sEmissive2Tex, blendUV ).xyz * tGradient2Tex.Sample( sGradient2Tex, blendUV).x, ( emissiveDiff > 0 ) ? 1 : 0 );
        texNormal = lerp( texNormal, texNormal2D( tNormal2Tex, sNormal2Tex, blendUV).xyz, blend );
    }

    Out.GBuffer0.xyzw = float4( albedo.xyz, 1.0f );
    Out.GBuffer2.xyzw = material;

    float3x3 normalRotation = float3x3( In.Tangent, In.BiNormal, In.Normal );
    float3 normal = mul( texNormal, normalRotation );
    Out.GBuffer1.xyz = encodeNormal( normal );

    emissive *= cGlowAmount * cGlowFactor;

    Out.GBuffer3 = float4( emissive.xyz, 1.0f );
    Out.GBuffer4 = 0.0f;

    return Out;
}
