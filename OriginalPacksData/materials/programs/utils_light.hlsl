#include "materials/programs/utils_struct.hlsl"
#include "materials/programs/utils_pbr.hlsl"
#include "materials/programs/utils_pack.hlsl"
#include "materials/programs/utils_shadow.hlsl"

#if REFLECTIONS
float3 GetSkyboxSpecular( float NdotV, float3 N, float roughness, float3 specularLight, float3 specularColor )
{
    float smoothness = 1.0f - Pow4( roughness );
    float2 specularBRDF = GetEnvBRDF( tEnvBRDF, sEnvBRDF, float2( NdotV, smoothness ) );
    float3 specular = specularLight * ( specularColor * specularBRDF.x + saturate( 50.0 * specularColor.g ) * specularBRDF.y );
    return specular;
}
#endif

#if SKYBOX_DIFFUSE
float3 GetSkyboxDiffuse( float NdotV, float3 N, float3 V, float roughness, float3 diffuseColor, float diffuseIntensity )
{
    float3 diffuseDominantDirection = N;
    float3 diffuseLight = GetEnvDiffuse( tEnvDiffuse, sEnvDiffuse, diffuseDominantDirection );
    float3 diffuse = diffuseLight * diffuseColor * diffuseIntensity;
    return diffuse;
}
#endif

#if SKYBOX_SPECULAR
float3 GetSkyboxSpecular( float NdotV, float3 N, float3 V, float roughness, float3 specularColor, float specularIntensity )
{
    float smoothness = 1.0f - Pow4( roughness );
    float2 specularBRDF = GetEnvBRDF( tEnvBRDF, sEnvBRDF, float2( NdotV, smoothness ) );
    float mipLevel = roughness * 8.0f;
    float3 reflectionDir = normalize( reflect( -V, N ) );
    float3 specularLight = GetEnvSpecular( tEnvSpecular, sEnvSpecular, reflectionDir, mipLevel );
    float3 specular = specularLight * ( ( specularColor * specularBRDF.x + saturate( 50.0 * specularColor.g ) * specularBRDF.y ) * specularIntensity );
    return specular;
}
#endif

float3 GetLightMaskWorldPos( float3 worldPos, float3 lightDir )
{
    float3 planeNormal = float3( 0, 1, 0 );
    float planeDenom = dot( planeNormal, lightDir );
    float planeNom = dot( planeNormal, worldPos ) + 10.0f;
    float planeDistance = -( planeNom / planeDenom );
    return worldPos + lightDir * planeDistance;
}

#if CLOUDS
float GetCloudsAttenuation( float3 worldPos, float3 lightDir, float time, float cloudsOpacity, float2 cloudsSpeed )
{
    const float cloudMackScale = 5;
    const float cloudScale = 5;
    const float cloudUvScale = 0.01f;
    const float cloudMaskUvScale = 0.02f;

    float2 uv = GetLightMaskWorldPos( worldPos, lightDir ).xy;
    float2 cloudMaskSpeed = cloudsSpeed + float2( 0.0f, -0.01f );
    float2 cloudUv = ( uv * cloudUvScale ) + time * cloudsSpeed * 0.01;
    float2 cloudMaskUv = ( cloudUv.xy * cloudMaskUvScale ) + time * cloudMaskSpeed * 0.01;
    float cloud = tCloudsNoiseTex.SampleLevel( sBilinearWrap, cloudUv, 0.0f ).x;
    float cloudMask = tCloudsNoiseTex.SampleLevel( sBilinearWrap, cloudMaskUv, 0.0f ).x;
    cloud = ( ( cloudMask * cloudMackScale ) * cloud ) * cloudScale;
    return lerp( 1, saturate( cloud ), cloudsOpacity - 0.1 );
}
#endif

float4 GetAlbedo( Texture2D t, SamplerState s, float2 uv )
{
    float4 albedo = t.Sample( s, uv );
#if GAMMA_CORRECTION
    albedo.xyz = SRGBToLinear( albedo.xyz );
#endif 
    return albedo;
}

float4 LoadAlbedo( Texture2D t, int3 did )
{
    float4 albedo = t.Load( did );
#if GAMMA_CORRECTION
    albedo.xyz = SRGBToLinear( albedo.xyz );
#endif 
    return albedo;
}

float3 GetNormal( Texture2D t, SamplerState s, float2 uv )
{
    return decodeNormal( t.Sample( s, uv ).xyz );
}

float3 LoadNormal( Texture2D t, int3 did )
{
    return decodeNormal( t.Load( did ).xyz );
}

float4 GetOcclusionRoughnessMetalness( Texture2D t, SamplerState s, float2 uv )
{
    float4 material = t.Sample( s, uv ).xyzw;
    material.x = saturate( material.x );
    return material;
}

float4 LoadOcclusionRoughnessMetalness( Texture2D t, int3 did )
{
    float4 material = t.Load( did ).xyzw;
    material.x = saturate( material.x );
    return material;
}

float GetOcclusion( Texture2D t, SamplerState s, float2 uv )
{
    float occlusion = t.SampleLevel( s, uv, 0.0f ).x;
    return occlusion;
}

float LoadOcclusion( Texture2D t, int3 did )
{
    float occlusion = t.Load( did ).x;
    return occlusion;
}

float3 GetCustomData( Texture2D t, SamplerState s, float2 uv )
{
    float3 data = t.Sample( s, uv ).xyz;
#if GAMMA_CORRECTION
    data.xyz = SRGBToLinear( data.xyz );
#endif
    return data;
}

float3 LoadCustomData( Texture2D t, int3 did )
{
    float3 data = t.Load( did ).xyz;
#if GAMMA_CORRECTION
    data.xyz = SRGBToLinear( data.xyz );
#endif
    return data;
}

#if LIGHTING

#if SHADOW_MAP
inline float GetDirectionalShadow( in float4 worldPos, in Shadow shadow )
{
    float4 uv = mul( shadow.GetShadowViewProjMatrix(), worldPos.xyzw );
    uv = uv / uv.w;
    uv.xy = mad( uv.xy, shadow.GetShadowViewportSize(), shadow.GetShadowViewportOffset() );

#if SHADOW_PCSS
    return GetShadowPCSS( uv.xy, uv.z, shadow.GetShadowNearFar(), shadow.GetShadowLightSize() * DIRECTIONAL_SHADOW_PENUMBRA, DIRECTIONAL_SHADOW_BIAS, shadow.GetShadowViewportClamp(), shadow.GetShadowViewportSize() );
#elif SHADOW_PCF
    return GetShadowPCF( uv.xy, uv.z, DIRECTIONAL_SHADOW_BIAS, shadow.GetShadowViewportClamp(), float2( 0.0005f, 0.0005f ) );
#else
    return GetShadowSimple( uv.xy, uv.z );
#endif
}
#endif 

#if SHADOW_MAP
inline float GetSpotLightShadow( in float4 worldPos, in Shadow shadow )
{
    float4 uv = mul( shadow.GetShadowViewProjMatrix(), worldPos.xyzw );
    uv = uv / uv.w;
    uv.xy = mad( uv.xy, shadow.GetShadowViewportSize(), shadow.GetShadowViewportOffset() );

#if SHADOW_PCSS
    return GetSpotLightShadowPCSS( uv.xy, uv.z, shadow.GetShadowNearFar(), SPOT_SHADOW_PENUMBRA, SPOT_SHADOW_BIAS, shadow.GetShadowViewportClamp(), shadow.GetShadowViewportSize() );
#elif SHADOW_PCF
    return GetShadowPCF( uv.xy, uv.z, SPOT_SHADOW_BIAS, shadow.GetShadowViewportClamp(), float2( 0.0005f, 0.0005f ) );
#else
    return GetShadowSimple( uv.xy, uv.z );
#endif
}
#endif

#if SHADOW_MAP
inline float GetPointLightShadow( in float3 toLightVec, in Shadow shadow )
{
    float3 uv = 0;
    float viewportIdx = 0;
    float3 absToLightVec = abs( toLightVec );
    if ( absToLightVec.x > absToLightVec.y && absToLightVec.x > absToLightVec.z )
    {
        float negX = step( toLightVec.x, 0.0f );
        uv = float3( toLightVec.zy, absToLightVec.x ) * float3( lerp( 1.0f, -1.0f, negX ), -1.0f, 1.0f );
        viewportIdx = negX;
    }
    else if (absToLightVec.y > absToLightVec.z)
    {
        float negY = step( toLightVec.y, 0.0f );
        uv = float3( toLightVec.zx, absToLightVec.y ) * float3( 1.0f, lerp( 1.0f, -1.0f, negY ), 1.0f );
        viewportIdx = 2.0f + negY;
    }
    else
    {
        float negZ = step( toLightVec.z, 0.0f );
        uv = float3( toLightVec.xy, absToLightVec.z ) * float3( lerp( -1.0, 1.0, negZ ), -1, 1 );
        viewportIdx = 4.0f + negZ;
    }

    uv.xy = ( ( uv.xy / uv.z ) + 1.0f ) * 0.5;
    uv.xy = mad( uv.xy, shadow.GetShadowViewportSize(), shadow.GetShadowViewportOffset( viewportIdx ) );
    uv.z = shadow.GetShadowRemapNearFar().x + shadow.GetShadowRemapNearFar().y / ( max( max( abs( toLightVec.x ), abs( toLightVec.y ) ), abs( toLightVec.z ) ) );

#if SHADOW_PCSS
    return GetSpotLightShadowPCSS( uv.xy, uv.z, shadow.GetShadowNearFar(), shadow.GetShadowLightSize() * POINT_SHADOW_PENUMBRA, POINT_SHADOW_BIAS, shadow.GetShadowViewportClamp( viewportIdx ), shadow.GetShadowViewportSize() );
#elif SHADOW_PCF
    return GetShadowPCF( uv.xy, uv.z, POINT_SHADOW_BIAS, shadow.GetShadowViewportClamp( viewportIdx ), shadow.GetShadowViewportTexel( viewportIdx ) );
#else
    return GetShadowSimple( uv.xy, uv.z );
#endif
}
#endif

inline void ComputePBRTerms( in Surface surface, in float3 N, in float3 L, in float3 H, in float3 V, inout Lighting lighting )
{
    const float LdotH = saturate( dot( L, H ) );
    const float NdotV = abs( dot( N, V ) ) + 0.001;
    const float NdotL = clamp( dot( N, L ), 0.001, 1.0 );
    const float NdotH = saturate( dot( N, H ) );

    const float  R    = Pow2( surface.Roughness ); 
    const float  D    = D_GGX( R, NdotH );
    const float  G    = V_SmithJointApprox( R, NdotV, NdotL );
    const float3 F    = F_Schlick( surface.Specular, LdotH );

    lighting.Specular = NdotL * ( D * G * F );
    lighting.Diffuse = NdotL * DisneyDiffuse( surface.Diffuse, surface.Roughness, NdotV, NdotL, LdotH );
}

inline void ComputeSpotLight( in Surface surface, in Light light, in float2 uv, inout Lighting lighting )
{   
    float shadow = 1.0f;
#if SHADOW_MAP
    [branch]
    if ( light.ShadowIntensity > 0.0f )
    {
        shadow = GetSpotLightShadow( surface.WorldPos, Shadows[ light.ShadowDataOffset ] );
        shadow = saturate( shadow + ( 1.0f - light.ShadowIntensity ) );
    }

    [branch]
    if ( shadow > 0.0f )
#endif
    {
        const float3 toLightVec = surface.WorldPos.xyz - light.WorldPos.xyz;
        const float dotVector = dot( toLightVec,toLightVec );
        const float rcpVectorlength = rsqrt( dotVector );
        const float3 L = -toLightVec * rcpVectorlength;

        float attenuation = GetAngleAttenuation( L, light.WorldDir, light.GetSpotLightAngleScale(), light.GetSpotLightAngleOffset() );
        if ( attenuation > 0.0f ) 
        {
            const float distanceToLight = rcpVectorlength * dotVector;
            const float3 N = surface.Normal;
            const float3 V = normalize( cCameraWorldPos.xyz - surface.WorldPos.xyz );
            const float3 H = normalize( L + V );

            attenuation *= GetDistanceAttenuation( distanceToLight, light.LightInvSquareRadius );

            Lighting instanceLighting;
            ComputePBRTerms( surface, N, L, H, V, instanceLighting );

            if ( surface.SubSurface.x > 0.0f )
            {
                const float inScatter = pow( saturate( dot( L, -V ) ), 3 );
                const float normalContribution = saturate( dot( N, H ) );
                const float backScatter = ( 1 - surface.Occlusion ) * normalContribution / ( 3.14f * 2 );
                instanceLighting.Diffuse += surface.Albedo * ( lerp( backScatter, 1, inScatter ) * surface.SubSurface.x );
            }

            const float3 lightColor = light.LightColor * ( attenuation * shadow );
            lighting.Diffuse += lightColor * instanceLighting.Diffuse;
            lighting.Specular += lightColor * instanceLighting.Specular;
        }
    }
}

inline void ComputePointLight( in Surface surface, in Light light, in float2 uv, inout Lighting lighting )
{
    const float3 toLightVec = surface.WorldPos.xyz - light.WorldPos.xyz;

    float shadow = 1.0f;
#if SHADOW_MAP
    [branch]
    if ( light.ShadowIntensity > 0.0f )
    {
        shadow = GetPointLightShadow( toLightVec, Shadows[ light.ShadowDataOffset ] );
        shadow = saturate( shadow + ( 1.0f - light.ShadowIntensity ) );
    }

    [branch]
    if ( shadow > 0.0f )
#endif
    {
        const float dotVector = dot( toLightVec,toLightVec );
        const float rcpVectorlength = rsqrt( dotVector );
        const float distanceToLight = rcpVectorlength * dotVector;

        const float attenuation = GetDistanceAttenuation( distanceToLight, light.LightInvSquareRadius );
        if ( attenuation > 0.0f )
        {
            const float3 N = surface.Normal;
            const float3 L = -toLightVec * rcpVectorlength;
            const float3 V = normalize( cCameraWorldPos.xyz - surface.WorldPos.xyz );
            const float3 H = normalize( L + V );

            Lighting instanceLighting;
            ComputePBRTerms( surface, N, L, H, V, instanceLighting );

            if ( surface.SubSurface.x > 0.0f )
            {
                const float inScatter = pow( saturate( dot( L, -V ) ), 6 );
                const float normalContribution = saturate( dot( N, H ) );
                const float backScatter = ( 1 - surface.Occlusion ) * normalContribution / ( 3.14f * 2 );
                instanceLighting.Diffuse += surface.Albedo * ( lerp( backScatter, 1, inScatter ) * surface.SubSurface.x );
            }

            const float3 lightColor = light.LightColor * ( attenuation * shadow );
            lighting.Diffuse += lightColor * instanceLighting.Diffuse;
            lighting.Specular += lightColor * instanceLighting.Specular;
        }
    }
}

inline void ComputeDirectionalLight( in Surface surface, in Light light, in float2 uv, inout Lighting lighting )
{
    const float3 N = surface.Normal;
    const float3 V = normalize( cCameraWorldPos.xyz - surface.WorldPos.xyz );

    float shadow = 1.0f;
#if SHADOW_MAP || SHADOW_BUFFER
    [branch]
    if ( light.ShadowIntensity > 0.0f )
    {
#if SHADOW_BUFFER
        shadow = tRaytracedShadowsTex.SampleLevel( sBilinearClamp, uv.xy, 0.0f  ).y;
#elif SHADOW_MAP
        shadow = GetDirectionalShadow( surface.WorldPos, Shadows[ light.ShadowDataOffset ] );
#endif
    }

    [branch]
    if ( shadow > 0.0f )
#endif
    {
        const float3 L = -light.WorldDir.xyz;
        const float3 H = normalize( L + V );

        float attenuation = 1.0f;
    #if CLOUDS
        attenuation *= GetCloudsAttenuation( surface.WorldPos.xyz, light.WorldDir, cTime, cCloudsParams.x, cCloudsParams.zw );
    #endif
    #if LIGHT_MASK
        attenuation *= tLightMaskTex.SampleLevel( sBilinearClamp, mul( Shadows[ 0 ].GetShadowViewProjMatrix(), surface.WorldPos ).xy, 0.0f ).x;
    #endif

        if ( attenuation > 0.0f )
        {
            Lighting instanceLighting;
            ComputePBRTerms( surface, N, L, H, V, instanceLighting );

            if ( surface.SubSurface.x > 0.0f )
            {
                const float inScatter = saturate( ( 1.5 + dot( L, -V ) ) / 2.0 ) * surface.SubSurface.y;
                const float normalContribution = saturate( dot( N, H ) );
                const float backScatter = ( 1 - surface.Occlusion ) * normalContribution / ( 3.14f * 2 );
                instanceLighting.Diffuse += surface.Albedo * ( lerp( backScatter, 1, inScatter ) * surface.SubSurface.x );
            }

            const float3 lightColor = light.LightColor * ( attenuation * shadow );
            lighting.Diffuse += lightColor * instanceLighting.Diffuse;
            lighting.Specular += lightColor * instanceLighting.Specular;
        }
    }
}

inline void ClampOutputColorIntensity( inout float3 output )
{ 
    const float outputLengthSqr = dot( output, output );
    const float outputLengthInv = rsqrt( max( outputLengthSqr, 0.00000001f ) );
    const float outputLength = outputLengthSqr * outputLengthInv;
    const float MAX_ADDITIONAL_LIGHTS_POWER = 25.0f;
    output = output * min( MAX_ADDITIONAL_LIGHTS_POWER, outputLength ) * outputLengthInv;
}

inline float3 ComputeOutputColor( in Surface surface, inout Lighting lighting )
{   
#if SKYBOX_DIFFUSE || SKYBOX_SPECULAR   
    const float3 N = surface.Normal;
    const float3 V = normalize( cCameraWorldPos.xyz - surface.WorldPos.xyz );
    const float NdotV = abs( dot( N, V ) ) + 0.001;
    #if SKYBOX_DIFFUSE   
    lighting.Diffuse += GetSkyboxDiffuse( NdotV, N, V, surface.Roughness, surface.Diffuse, cSkyboxParams.y );
    #endif
    #if SKYBOX_SPECULAR   
    lighting.Specular += GetSkyboxSpecular( NdotV, N, V, surface.Roughness, surface.Specular, cSkyboxParams.x );
    #endif
#endif

    float3 color = lerp( lighting.Diffuse, surface.Refraction.xyz, surface.Refraction.a );
    color += lighting.Specular;
    color *= surface.Occlusion;
    ClampOutputColorIntensity( color );
    color += surface.Emissive;	
    return color;
}
#endif