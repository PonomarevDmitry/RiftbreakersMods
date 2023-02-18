#include "materials/programs/utils.hlsl"
#include "materials/programs/pack_ops.hlsl"

cbuffer FPConstantBuffer : register(b0)
{
#if USE_DISSOLVE_MAP  
    float4      cDissolveColor;
    float       cDissolveAmount;
    float       cDissolveSize;
#endif
    float       cGlowAmount;
    float       cGlowFactor;
#if USE_REFLECTION_MAP
    float2      cReflectionParams;
    float3      cWorldCameraPos;
#endif
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
#if USE_DISSOLVE_MAP
Texture2D       tDissolveTex;
SamplerState    sDissolveTex;
#endif
#if USE_REFLECTION_MAP
TextureCube     tReflectionTex;
SamplerState    sReflectionTex;
#endif
#if USE_MIPMAP_CHECKER
Texture2D       tMipMapCheckerTex;
SamplerState    sMipMapCheckerTex;
#endif

PS_OUTPUT mainFP( VS_OUTPUT In )
{
    PS_OUTPUT Out;

    float4 albedo = tAlbedoTex.SampleBias( sAlbedoTex, In.UV0, cMIPBias).xyzw;

#if USE_MIPMAP_CHECKER
    float lod = max( 0.0, tAlbedoTex.CalculateLevelOfDetail(sAlbedoTex,In.UV0) + cMIPBias );

    float4 mipmapChecker = tMipMapCheckerTex.SampleLevel( sMipMapCheckerTex, In.UV0, lod).xyzw;
    albedo.xyz = lerp( albedo.xyz, mipmapChecker.rgb, mipmapChecker.a );
#endif

#if USE_ALPHA_TEST
    clip ( albedo.a > 0.5f ? 1:-1 );
#endif

    Out.GBuffer0.xyzw = float4( albedo.xyz, 1.0f );
    Out.GBuffer2.xyzw = tPackedTex.SampleBias( sPackedTex, In.UV0, cMIPBias);

    float3 texNormal = texNormal2D( tNormalTex, sNormalTex, In.UV0);
    float3x3 normalRotation = float3x3( In.Tangent, In.BiNormal, In.Normal );
    float3 normal = mul( texNormal, normalRotation );
    Out.GBuffer1.xyz = encodeNormal( normal );

    float3 emissive = tEmissiveTex.SampleBias( sEmissiveTex, In.UV0, cMIPBias).xyz * tGradientTex.SampleBias( sGradientTex, In.UV0, cMIPBias).x;
    emissive *= cGlowAmount * cGlowFactor;

#if USE_REFLECTION_MAP
    float roughness = Out.GBuffer2.y;
    if ( roughness < cReflectionParams.x )
    {
        float3 reflectRay = reflect( normalize( In.WorldPos - cWorldCameraPos ), normal );
        float mipLevel = roughness * 8.0f;
        float3 reflection = tReflectionTex.SampleLevel( sReflectionTex, reflectRay, mipLevel ).xyz;
        emissive.xyz += reflection * cReflectionParams.y;
    }
#endif

#if USE_DISSOLVE_MAP
    float dissolve = tDissolveTex.SampleBias( sDissolveTex, In.UV0, cMIPBias).x;
    clip( dissolve >= cDissolveAmount ? 1:-1 );

    float dissolveDiff = dissolve - cDissolveAmount;
    if ( dissolveDiff < cDissolveSize && cDissolveAmount > 0 && cDissolveAmount < 1 )
    {
        float dissolvePower = saturate( dissolveDiff / cDissolveSize );
        float3 dissolveColor = cDissolveColor.rgb;
        dissolveColor += cDissolveColor.a * dissolvePower * dissolvePower;
        dissolveColor *= cDissolveAmount * dissolvePower;
        emissive.xyz = dissolveColor;
    }
#endif

    Out.GBuffer3 = float4( emissive.xyz, 1.0f );
    Out.GBuffer4 = 0.0f;

    return Out;
}
