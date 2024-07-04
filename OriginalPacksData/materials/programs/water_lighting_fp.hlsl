cbuffer FPConstantBuffer : register(b0)
{   
#if SKYBOX_SPECULAR || SKYBOX_DIFFUSE
    float4                  cSkyboxParams;     // skyboxSpecularIntensity (x), skyboxDiffuseIntensity (y)
#endif
    float3                  cCameraWorldPos;
    uint                    cNumLights;
    uint2                   cViewportSize;
};

struct VS_OUTPUT
{
    float4                  Position      : SV_POSITION;
    float2                  TexCoord      : TEXCOORD0;
    float4                  ProjPos       : TEXCOORD4;
    float3                  WorldPos      : TEXCOORD5;
};

struct PS_OUTPUT
{
    float4                  Color         : SV_TARGET0;
#if USE_UPSCALE_MASK
    float                   UpscaleMask   : SV_TARGET1;
#endif
};

Texture2D<float4>           tGBuffer0;
SamplerState                sGBuffer0;
Texture2D<float4>           tGBuffer1;
SamplerState                sGBuffer1;
Texture2D<float4>           tGBuffer2;
SamplerState                sGBuffer2;
Texture2D<float4>           tGBuffer3;
SamplerState                sPointClamp;
Texture2D<float4>           tGBuffer4;
SamplerState                sBilinearClamp;

#if SHADOW_MAP
    Texture2D               tShadowTex;
    SamplerComparisonState  sShadowComparisonSampler;
#endif

#if SKYBOX_DIFFUSE
    TextureCube             tEnvDiffuse;
    SamplerState            sEnvDiffuse;
#endif

#if SKYBOX_SPECULAR
    Texture2D<float4>       tEnvBRDF;
    SamplerState            sEnvBRDF;
    TextureCube             tEnvSpecular;
    SamplerState            sEnvSpecular;
#endif

#if LIGHT_MASK
    Texture2D               tLightMaskTex;
#endif

#include "materials/programs/utils_struct.hlsl"
#include "materials/programs/utils_fog.hlsl"

StructuredBuffer<uint>      LightIndexList;
StructuredBuffer<Light>     Lights;
StructuredBuffer<Shadow>    Shadows;

#include "materials/programs/tiled_deferred_light_internal.hlsl"

inline float3 ComputeWaterOutputColor( in Surface surface, inout Lighting lighting, float specularPower )
{   
#if SKYBOX_DIFFUSE || SKYBOX_SPECULAR   
    const float3 N = surface.Normal;
    const float3 V = normalize( cCameraWorldPos.xyz - surface.WorldPos.xyz );
    const float NdotV = abs( dot( N, V ) ) + 0.001;
    #if SKYBOX_DIFFUSE   
    lighting.Diffuse += GetSkyboxDiffuse( NdotV, N, V, surface.Roughness, surface.Diffuse, cSkyboxParams.y );
    #endif
    #if SKYBOX_SPECULAR   
    lighting.Specular += GetSkyboxSpecular( NdotV, N, V, surface.Roughness, surface.Specular, cSkyboxParams.x ) * specularPower;
    #endif
#endif

    float3 color = lerp( lighting.Diffuse, surface.Refraction.xyz, surface.Refraction.a );
    color += lighting.Specular;
    color *= surface.Occlusion;
    color += surface.Emissive;
    ClampOutputColorIntensity( color );
    return color;
}

PS_OUTPUT mainFP( VS_OUTPUT In )
{
    PS_OUTPUT Out;

    float2 screenCoords = In.ProjPos.xy / In.ProjPos.w * float2( 0.5f, -0.5f ) + float2( 0.5f, 0.5f );
    float4 occlusionRoughnessMetalness = GetOcclusionRoughnessMetalness( tGBuffer2, sGBuffer2, screenCoords );
    float3 refractOrEmissive = tGBuffer3.SampleLevel( sBilinearClamp, screenCoords, 0.0f ).xyz;
    float3 alphaRefractEmissive = tGBuffer4.SampleLevel( sPointClamp, screenCoords, 0.0f ).xyz;
    float specularIntensity = ( alphaRefractEmissive.z == 0.0f ) ? occlusionRoughnessMetalness.x : 1.0f;

    Surface surface;
    surface.Albedo = GetAlbedo( tGBuffer0, sGBuffer0, screenCoords ).xyz;
    surface.WorldPos = float4( In.WorldPos.xyz, 1.0f );
    surface.Normal = GetNormal( tGBuffer1, sGBuffer1, screenCoords );
    surface.SubSurface = float3( 0.0f, 0.0f, 0.0f );
    surface.Emissive = ( alphaRefractEmissive.z == 1.0f ) ? refractOrEmissive : float3( 0.0f, 0.0f, 0.0f );
    surface.Occlusion = ( alphaRefractEmissive.z == 1.0f ) ? occlusionRoughnessMetalness.x : 1.0f;
    surface.Roughness = occlusionRoughnessMetalness.y;
    surface.Refraction = ( alphaRefractEmissive.z == 0.0f ) ? float4( refractOrEmissive.xyz, alphaRefractEmissive.y ) : float4( 0.0f, 0.0f, 0.0f, 0.0f );
    surface.Diffuse = lerp( surface.Albedo.xyz, 0.0f, occlusionRoughnessMetalness.z );
    surface.Specular = lerp( 0.04f, surface.Albedo.xyz, occlusionRoughnessMetalness.z );

    Lighting lighting;
    lighting.Diffuse = float3( 0.0, 0.0, 0.0 );
    lighting.Specular = float3( 0.0, 0.0, 0.0 );

    const uint linearTileIndex = LinearTileIndex( screenCoords, cViewportSize );
    const uint lightIndexListAddress = linearTileIndex * TILED_DEFERRED_MAX_LIGHT_BUCKET_COUNT;
    const uint lastMaxLightIndex = cNumLights - 1;
    const uint lastLightBucket = min( lastMaxLightIndex / 32u, max( 0u, ( uint ) TILED_DEFERRED_MAX_LIGHT_BUCKET_COUNT - 1 ) );

    for ( uint lightBucket = 0; lightBucket <= lastLightBucket; ++lightBucket )
    {    
        uint lightBits = LightIndexList[ lightIndexListAddress + lightBucket ];
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
                    ComputePointLight( surface, light, screenCoords, lighting );
                }
                break;
                case SPOT_LIGHT:
                {
                    ComputeSpotLight( surface, light, screenCoords, lighting );
                }
                break;
                case DIRECTIONAL_LIGHT:
                {
                    ComputeDirectionalLight( surface, light, screenCoords, lighting );
                }
                break;
            }
        }
    }

    Out.Color = float4( ComputeWaterOutputColor( surface, lighting, specularIntensity ), alphaRefractEmissive.x );
    return Out;
}
