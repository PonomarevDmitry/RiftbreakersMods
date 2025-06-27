cbuffer FPConstantBuffer : register(b0)
{   
#if SKYBOX_SPECULAR || SKYBOX_DIFFUSE
    float4                      cSkyboxParams;     // skyboxSpecularIntensity (x), skyboxDiffuseIntensity (y)
#endif 
#if USE_VELOCITY
    float4                      cJitterOffset;
#endif
    float3                      cCameraWorldPos;    
    float                       cGlowAmount;
    float                       cGlowFactor;
    float                       cMIPBias;
#if USE_DISSOLVE_MAP  
    float                       cDissolveAmount;
    float                       cDissolveSize;
    float4                      cDissolveColor;
#endif
#if USE_GLASS
    float4                      cEdgeColor;
#endif
#if USE_FOG
    float                       cFogMaxDistance;
#endif
    int                         cNumLights;
    int2                        cViewportSize;
};

struct VS_OUTPUT
{
    float4                      Position            : SV_POSITION;
    float2                      TexCoord            : TEXCOORD0;
    float3                      WorldNormal         : TEXCOORD2;
    float4                      ProjPos             : TEXCOORD4;
    float3                      WorldPos            : TEXCOORD5;
    float3                      WorldTangent        : TEXCOORD6;
    float3                      WorldBiNormal       : TEXCOORD7;
};

struct PS_OUTPUT
{
    float4                      Color               : SV_TARGET0;
#if USE_UPSCALE_MASK
    float                       UpscaleMask         : SV_TARGET1;
#endif
};

Texture2D                       tAlbedoTex;
SamplerState                    sAlbedoTex;
Texture2D                       tNormalTex;
SamplerState                    sNormalTex;
Texture2D                       tPackedTex;
SamplerState                    sPackedTex;
Texture2D                       tEmissiveTex;
SamplerState                    sEmissiveTex;
Texture2D                       tGradientTex;
SamplerState                    sBilinearClamp;

#if USE_DISSOLVE_MAP
    Texture2D                   tDissolveTex;
    SamplerState                sDissolveTex;
#endif

#if USE_FOG
    Texture3D                   tLightScattering;
    SamplerState                sLightScattering;
#endif

#if SHADOW_MAP
    Texture2D                   tShadowTex;
    SamplerComparisonState      sShadowComparisonSampler;
#endif

#if SKYBOX_DIFFUSE
    TextureCube                 tEnvDiffuse;
    SamplerState                sEnvDiffuse;
#endif

#if SKYBOX_SPECULAR
    Texture2D<float4>           tEnvBRDF;
    SamplerState                sEnvBRDF;
    TextureCube                 tEnvSpecular;
    SamplerState                sEnvSpecular;
#endif

#if LIGHT_MASK
    Texture2D                   tLightMaskTex;
#endif

#include "materials/programs/utils_struct.hlsl"
#include "materials/programs/utils_fog.hlsl"

StructuredBuffer<uint>          LightIndexList;
StructuredBuffer<Light>         Lights;

#if SHADOW_MAP
    StructuredBuffer<Shadow>    Shadows;
#endif

#if USE_GLASS
inline float GetReflectionPower( in float3 worldPos, in float3 worldNor )
{
    const float3 V = normalize( cCameraWorldPos.xyz - worldPos.xyz );
    const float3 N = worldNor;
    const float NdotV = abs( dot( N, V ) ) + 0.001;
    return NdotV;
}
#endif 

#include "materials/programs/tiled_deferred_light_internal.hlsl"

PS_OUTPUT mainFP( VS_OUTPUT In )
{
    PS_OUTPUT Out;

    float3 texNormal = texNormal2D( tNormalTex, sNormalTex, In.TexCoord );
    float3x3 normalRotation = float3x3( In.WorldTangent, In.WorldBiNormal, In.WorldNormal );
    float3 normal = mul( texNormal, normalRotation );
    float3 occlusionRoughnessMetalness = tPackedTex.SampleBias( sPackedTex, In.TexCoord, cMIPBias ).xyz;
    float3 emissive = tEmissiveTex.SampleBias( sEmissiveTex, In.TexCoord, cMIPBias).xyz;
    emissive.xyz = SRGBToLinear( emissive.xyz );
    emissive.xyz *= tGradientTex.SampleBias( sBilinearClamp, In.TexCoord, cMIPBias).x * cGlowAmount * cGlowFactor;

    float4 albedo = tAlbedoTex.SampleBias( sAlbedoTex, In.TexCoord, cMIPBias );
#if USE_GLASS
    float edgeFactor = GetReflectionPower( In.WorldPos.xyz, normal );
    albedo.xyz = lerp( cEdgeColor.xyz, albedo.xyz, edgeFactor );
    albedo.w = min( 1.0, albedo.w / edgeFactor );
#endif
    albedo.xyz = SRGBToLinear( albedo.xyz );

#if USE_DISSOLVE_MAP
    float dissolve = tDissolveTex.SampleBias( sDissolveTex, In.TexCoord, cMIPBias).x;
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

    Surface surface;
    surface.Albedo = albedo.xyz;
    surface.WorldPos = float4( In.WorldPos.xyz, 1.0f );
    surface.Normal = normal.xyz;
    surface.SubSurface = float3( 0.0f, 0.0f, 0.0f );
    surface.Emissive = emissive;
    surface.Occlusion = occlusionRoughnessMetalness.x;
    surface.Roughness = occlusionRoughnessMetalness.y;
    surface.Refraction = float4( 0.0, 0.0, 0.0, 0.0 );
    surface.Diffuse = lerp( surface.Albedo.xyz, 0.0f, occlusionRoughnessMetalness.z );
    surface.Specular = lerp( 0.04f, surface.Albedo.xyz, occlusionRoughnessMetalness.z );

    Lighting lighting;
    lighting.Diffuse = float3( 0.0, 0.0, 0.0 );
    lighting.Specular = float3( 0.0, 0.0, 0.0 );

    float2 screenPos = In.ProjPos.xy / In.ProjPos.w;
    screenPos = screenPos * float2( 0.5f, -0.5f ) + float2( 0.5f, 0.5f );

    const uint linearTileIndex = LinearTileIndex( screenPos, cViewportSize );
    const uint lightIndexListAddress = linearTileIndex * TILED_DEFERRED_MAX_LIGHT_BUCKET_COUNT;
    const uint lastMaxLightIndex = cNumLights - 1;
    const uint lastLightBucket = min( lastMaxLightIndex / 32u, max( 0u, ( uint ) TILED_DEFERRED_MAX_LIGHT_BUCKET_COUNT - 1 ) );
    [loop]
    for ( uint lightBucket = 0; lightBucket <= lastLightBucket; ++lightBucket )
    {    
        uint lightBits = LightIndexList[ lightIndexListAddress + lightBucket ];
        [loop]
        while (lightBits != 0)
        {
            const uint lightBitIndex = firstbitlow( lightBits );
            const uint lightIndex = lightBucket * 32 + lightBitIndex;
            lightBits ^= 1u << lightBitIndex;

            Light light = Lights[ lightIndex ];
            switch ( light.Type )
            {
                case POINT_LIGHT:
                {
                    ComputePointLight( surface, light, lighting );
                }
                break;
                case SPOT_LIGHT:
                {
                    ComputeSpotLight( surface, light, lighting );
                }
                break;
                case DIRECTIONAL_LIGHT:
                {
                    ComputeDirectionalLight( surface, light, In.TexCoord, lighting );
                }
                break;
            }
        }
    }

    Out.Color = float4( ComputeOutputColor( surface, lighting ), albedo.w );

#if USE_FOG
    Out.Color.xyz = GetFog( Out.Color.xyz, In.ProjPos );
#endif

    return Out;
}
