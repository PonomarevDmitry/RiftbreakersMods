cbuffer CSConstantBuffer : register(b0)
{
    matrix                  cInvViewProjMatrix;
    matrix                  cPrevViewProjMatrix;
	float2 					cNearFarClip;
    int2                    cViewportSize;
    float3                  cCameraWorldPos;
    int                     cNumLights;
    float4                  cVolumetricFogParams1;       // x - scatteringDistribution, y - extinctionScale, z - maxDistance, w - fogDensity
    uint2                   cTiledDeferredGridSize;
#if CLOUDS
    float4                  cCloudsParams;              // cloudsOpacity (x), cloudsDensity (y),  cloudsSpeed (zw)
    float                   cTime;
#endif
    float4                  cVolumetricJitterOffset; 
};

SamplerState                sBilinearClamp;
SamplerState                sBilinearWrap;

Texture3D<float4>           VBufferScattering;

#if USE_EMISSIVE
    Texture3D<float4>       VBufferEmissive;
#endif

#if USE_TEMPORAL
    Texture3D<float4>       LightScatteringHistory;
#endif

#if CLOUDS
    Texture2D               tCloudsNoiseTex;
#endif

#if LIGHT_MASK
    Texture2D               tLightMaskTex;
#endif

#if SHADOW_MAP
    Texture2D               tShadowTex;
#endif

#include "materials/programs/utils_struct.hlsl"
#include "materials/programs/volumetric_fog_internal.hlsl"

StructuredBuffer<uint>      LightIndexList;
StructuredBuffer<Light>     Lights;
StructuredBuffer<Shadow>    Shadows;

#include "materials/programs/tiled_deferred_light_internal.hlsl"

RWTexture3D<float4>         LightScattering : register( u0 );

inline void ComputeSpotLightScattering( in float3 worldPos, in Light light, in float2 uv, inout float3 output )
{
#if SHADOW_MAP
    float shadow = 1.0f;
    [branch]
    if ( light.ShadowIntensity > 0.0f )
    {
        shadow = GetSpotLightShadow( float4( worldPos, 1.0f ), Shadows[ light.ShadowDataOffset ] );
        shadow += ( 1.0f - light.ShadowIntensity );
    }

    [branch]
    if ( shadow > 0.0f )
#endif
    {
        const float3 toLightVec = worldPos - light.WorldPos.xyz;
        const float dotVector = dot( toLightVec,toLightVec );
        const float rcpVectorlength = rsqrt( dotVector );
        const float3 L = -toLightVec * rcpVectorlength;

        float attenuation = GetAngleAttenuation( L, light.WorldDir, light.GetSpotLightAngleScale(), light.GetSpotLightAngleOffset() );
        if ( attenuation > 0.0f ) 
        {
            const float distanceToLight = rcpVectorlength * dotVector;
            attenuation *= GetDistanceAttenuation( distanceToLight, light.LightInvSquareRadius );
            attenuation *= saturate( distanceToLight / 5.0f );

            const float3 V = normalize( cCameraWorldPos.xyz - worldPos.xyz );
                    
#if SHADOW_MAP
            output += light.LightColor * ( HenyeyGreensteinPhase( cVolumetricFogParams1.x, dot( L, -V ) ) * attenuation * shadow * light.ScatteringIntensity );
#else
            output += light.LightColor * ( HenyeyGreensteinPhase( cVolumetricFogParams1.x, dot( L, -V ) ) * attenuation * light.ScatteringIntensity );
#endif
        }
    }
}

inline void ComputePointLightScattering( in float3 worldPos, in Light light, in float2 uv, inout float3 output )
{
    const float3 toLightVec = worldPos.xyz - light.WorldPos.xyz;
    const float dotVector = dot( toLightVec,toLightVec );
    const float rcpVectorlength = rsqrt( dotVector );
    const float distanceToLight = rcpVectorlength * dotVector;

#if SHADOW_MAP
    float shadow = 1.0f;
    [branch]
    if ( light.ShadowIntensity > 0.0f )
    {
        shadow = GetPointLightShadow( toLightVec, Shadows[ light.ShadowDataOffset ] );
        shadow += ( 1.0f - light.ShadowIntensity );
    }

    [branch]
    if ( shadow > 0.0f )
#endif
    {
        const float attenuation = GetDistanceAttenuation( distanceToLight, light.LightInvSquareRadius );
        if ( attenuation > 0.0f )
        {
            const float3 L = -toLightVec * rcpVectorlength;
            const float3 V = normalize( cCameraWorldPos.xyz - worldPos.xyz );

#if SHADOW_MAP
            output += light.LightColor * ( HenyeyGreensteinPhase( cVolumetricFogParams1.x, dot( L, -V ) ) * attenuation * shadow * light.ScatteringIntensity );
#else
            output += light.LightColor * ( HenyeyGreensteinPhase( cVolumetricFogParams1.x, dot( L, -V ) ) * attenuation * light.ScatteringIntensity );
#endif 
        }
    }
}

inline void ComputeDirectionalLightScattering( in float3 worldPos, in Light light, in float2 uv, inout float3 output )
{
#if SHADOW_MAP
    float shadow = 1.0f;
    [branch]
    if ( light.ShadowIntensity > 0.0f )
    {
        shadow = GetDirectionalShadow( float4( worldPos, 1.0f ), Shadows[ light.ShadowDataOffset ] );
    }

    [branch]
    if ( shadow > 0.0f )
#endif
    {    
        const float3 L = -light.WorldDir.xyz;
        const float3 V = normalize( cCameraWorldPos.xyz - worldPos.xyz );

        float attenuation = 1.0f;
    #if CLOUDS
        attenuation *= GetCloudsAttenuation( worldPos.xyz, light.WorldDir, cTime, cCloudsParams.x, cCloudsParams.zw );
    #endif
    #if LIGHT_MASK
        attenuation *= tLightMaskTex.SampleLevel( sBilinearClamp, mul( Shadows[ 0 ].GetShadowViewProjMatrix(), float4( worldPos.xyz, 1.0f ) ).xy, 0.0f ).x;
    #endif

        if ( attenuation > 0.0f )
        {
#if SHADOW_MAP
            output += light.LightColor * ( HenyeyGreensteinPhase( cVolumetricFogParams1.x, dot( L, V ) ) * attenuation * shadow * light.ScatteringIntensity );
#else
            output += light.LightColor * ( HenyeyGreensteinPhase( cVolumetricFogParams1.x, dot( L, V ) ) * attenuation * light.ScatteringIntensity );
#endif 
        }
    }
}

[numthreads( 4, 4, 4 )]
void main( uint3 groupID : SV_GroupID, uint3 dispatchThreadID : SV_DispatchThreadID )
{
    uint3 dims;
    LightScattering.GetDimensions( dims.x, dims.y, dims.z );

    const int3 did = dispatchThreadID;
    if ( any( did >= dims ) )
        return;

    float2 screenUV = float2( did.xy ) / dims.xy;
    float3 lightScattering = float3( 0.0, 0.0, 0.0 );

    uint2 tileIndex = cTiledDeferredGridSize.xy * screenUV;
    const uint linearTileIndex = ( tileIndex.y * cTiledDeferredGridSize.x ) + tileIndex.x;
    const uint lightIndexListAddress = linearTileIndex * TILED_DEFERRED_MAX_LIGHT_BUCKET_COUNT;
    const uint lastMaxLightIndex = max( 0, cNumLights - 1 );
    const uint lastLightBucket = min( lastMaxLightIndex / 32u, max( 0u, ( uint ) TILED_DEFERRED_MAX_LIGHT_BUCKET_COUNT - 1 ) );

    uint lightCount = 0;
    float3 worldPos = GetVolumeWorldPos( did, dims, cVolumetricJitterOffset.xyz );
    [loop]
    for ( uint lightBucket = 0; lightBucket <= lastLightBucket; ++lightBucket )
    {    
        uint lightBits = LightIndexList[ lightIndexListAddress + lightBucket ];
        [loop]
        while ( lightBits != 0 && lightCount < cNumLights )
        {
            const uint lightBitIndex = firstbitlow( lightBits );
            const uint lightIndex = lightBucket * 32 + lightBitIndex;
            lightBits ^= 1u << lightBitIndex;
            lightCount++;

            Light light = Lights[ lightIndex ];
            switch ( light.Type )
            {
                case POINT_LIGHT:
                {
                    ComputePointLightScattering( worldPos, light, screenUV.xy, lightScattering );
                }
                break;
                case SPOT_LIGHT:
                {
                    ComputeSpotLightScattering( worldPos, light, screenUV.xy, lightScattering );
                }
                break;
                case DIRECTIONAL_LIGHT:
                {
                    ComputeDirectionalLightScattering( worldPos, light, screenUV.xy, lightScattering );
                }
                break;
            }
        }
    }

    float4 materialScatteringAndAbsorption = VBufferScattering[ did ];
    float extinction = materialScatteringAndAbsorption.w + Luminance( materialScatteringAndAbsorption.xyz );
    float4 scatteringAndExtinction = float4( lightScattering * materialScatteringAndAbsorption.xyz, extinction );

#if USE_EMISSIVE
    scatteringAndExtinction.xyz += VBufferEmissive[ did ].xyz;
#endif

#if USE_TEMPORAL
    float prevWeight = 0.9f;
    float3 prevWorldPos = GetVolumeWorldPos( did, dims, 0.5f );
    float3 prevUV = GetVolumeUV( prevWorldPos, cPrevViewProjMatrix );
    float4 prevScatteringAndExtinction = LightScatteringHistory.SampleLevel( sBilinearClamp, prevUV, 0.0 );
    scatteringAndExtinction = lerp( scatteringAndExtinction, prevScatteringAndExtinction, prevWeight );
#endif

    scatteringAndExtinction = isnan( scatteringAndExtinction ) || isinf( scatteringAndExtinction ) ? 0 : scatteringAndExtinction;
    LightScattering[ did ] = max( scatteringAndExtinction, 0 );
}