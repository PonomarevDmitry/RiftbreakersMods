cbuffer CSConstantBuffer : register(b0)
{
#if POSTPROCESS 
    float4              cPostProcessParams;     // x - desaturation, y - brightness, z - contrast, w - redTone
#endif
#if VOLUMETRIC_FOG
    float4              cVolumetricFogParams1;   // x - scatteringDistribution, y - extinctionScale, z - maxDistance
#endif   
#if VOLUMETRIC_FOG
    float4              cNearFarClip;
#endif
#if REFLECTIONS
    matrix              cInvViewProjMatrix;
    float3              cCameraWorldPos;
#endif
    int2                cViewportSize;
};

#if VOLUMETRIC_FOG
    Texture3D           tLightScattering;
    SamplerState        sLightScattering;
#endif

#if REFLECTIONS
    Texture2D           tEnvBRDF;
    SamplerState        sEnvBRDF;
    Texture2D           tReflections;
    SamplerState        sReflections;
    Texture2D           tGBuffer0;
    SamplerState        sGBuffer0;
    Texture2D           tGBuffer1;
    SamplerState        sGBuffer1;
    Texture2D           tGBuffer2;
    SamplerState        sGBuffer2;
#endif

    Texture2D           tMain;
    SamplerState        sMain;

#if VOLUMETRIC_FOG || REFLECTIONS 
    Texture2D           tDepth;
    SamplerState        sDepth;
#endif

RWTexture2D< float4 >   OutputTexture : register(u0);

#include "materials/programs/utils_light.hlsl"
#include "materials/programs/utils_fog.hlsl"

#if REFLECTIONS
float3 GetWorldPos( float2 uv, float depth )
{
    float4 projPos = float4( uv * float2( 2.0, -2.0 ) + float2( -1.0, 1.0 ), depth, 1.0 );
    float4 worldPos = mul( cInvViewProjMatrix, projPos );
    return worldPos.xyz / worldPos.w;
}
#endif

#if VOLUMETRIC_FOG 
float GetLinearDepth( float depth )
{
#if INVERTED_DEPTH_RANGE
    return -( cNearFarClip.y * cNearFarClip.x ) / ( depth * ( cNearFarClip.x - cNearFarClip.y ) - cNearFarClip.x );
#else
    return -( cNearFarClip.x * cNearFarClip.y ) / ( depth * ( cNearFarClip.y - cNearFarClip.x ) - cNearFarClip.y );
#endif
}
#endif

[numthreads( 16, 16, 1 )]
void main( uint2 dispatchThreadID : SV_DispatchThreadID )
{
    const int3 did = int3( dispatchThreadID.xy, 0 );
    if ( any( did.xy >= cViewportSize ) )
        return;

    float3 output = tMain.Load( did ).xyz;
    const float2 screenUV = float2( did.xy ) / cViewportSize;

#if VOLUMETRIC_FOG || REFLECTIONS
    const float depth = tDepth.Load( did ).r;
#endif

#if VOLUMETRIC_FOG
    const float linearDepth = GetLinearDepth( depth );
#endif

#if REFLECTIONS
    const float3 worldPos = GetWorldPos( screenUV.xy, depth );
#endif

#if REFLECTIONS 
    const float3 albedo = LoadAlbedo( tGBuffer0, did );
    const float3 occlusionRoughnessMetalness = LoadOcclusionRoughnessMetalness( tGBuffer2, did );
    const float occlusion = occlusionRoughnessMetalness.x;
    const float roughness = occlusionRoughnessMetalness.y; 
    const float metalness = occlusionRoughnessMetalness.z;

    const float3 specularLight = tReflections.SampleLevel( sReflections, screenUV.xy, 0.0f );
    const float3 specularColor = lerp( 0.04f, albedo.xyz, metalness );

    const float3 N = LoadNormal( tGBuffer1, did );
    const float3 V = normalize( cCameraWorldPos - worldPos );
    const float NdotV = abs( dot( N, V ) ) + 0.001;

    output += GetSkyboxSpecular( NdotV, N, roughness, specularLight, specularColor ) * occlusion;
#endif 

#if VOLUMETRIC_FOG
    float4 fog = GetVolumetricFog( screenUV, linearDepth, cVolumetricFogParams1.z );
    output = output * fog.a + fog.rgb;
#endif

#if POSTPROCESS
    if ( any( cPostProcessParams.xw > 0 ) || any( cPostProcessParams.yz ) != 1 )
    {
        float3 greyscale = dot( output, float3( 0.3f, 0.59f, 0.11f ) ).xxx; 
        greyscale.yz *= 1.0f - cPostProcessParams.w;
        output = lerp( output, greyscale, cPostProcessParams.x );
        output *= cPostProcessParams.z;
        output = max( float3( 0.0f, 0.0f, 0.0f ), output + cPostProcessParams.yyy );
    }
#endif

    OutputTexture[ did.xy ] = float4( output, 1.0f );
}