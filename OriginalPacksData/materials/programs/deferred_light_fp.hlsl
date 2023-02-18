#include "materials/programs/pack_ops.hlsl"
#include "materials/programs/pbr_utils.hlsl"

cbuffer FPConstantBuffer : register(b0)
{
    float4      cFocalParams; 
    float4      cLightParams;   // lightColor (xyz), lightInvSquareRadius (w)
#if SKYBOX
    float4      cSkyboxParams;     // skyboxDiffuseIntensity (x), skyboxSpecularIntensity (y)
#endif
#if SPOT_LIGHT
    float4      cSpotLightParams;  // lightRange (x), lightOuterAngle (y), lightAngleScale (z), lightAngleOffset (w)
#endif
#if SPOT_LIGHT || CLOUDS
	float4      cLightWorldDir;
#endif 
    matrix      cInvView;
    float4      cCameraWorldPos;
    float4      cLightWorldPos;
#if SHADOW_MAP
    matrix      cShadowViewProj;
#endif
#if SHADOW_MAP || SHADOW_BUFFER
    float4      cShadowParams;
#endif
#if LIGHT_MASK
    matrix      cLightMaskViewProj;
#endif
#if CLOUDS
    float4      cCloudsParams;     // cloudsOpacity (x), cloudsDensity (y),  cloudsSpeed (zw)
    float       cTime;
#endif
};

struct VS_OUTPUT
{
    float4      Position : SV_POSITION;
    float4      TexCoord : TEXCOORD0;
};

struct PS_OUTPUT
{
    float4      Color    : SV_TARGET;
};

//float4 GBuffer0  // Albedo (xyz), Subsurface (w)
//float3 GBuffer1  // World Space Normal (xyz), 
//float3 GBuffer2  // Occlusion (x), Roughness (y), Metalness (z)
//float4 GBuffer3  // Emissive/Subsurface (xyz), ShadingFeature (w)

Texture2D                       tGBuffer0;
SamplerState                    sGBuffer0;
Texture2D                       tGBuffer1;
SamplerState                    sGBuffer1;
Texture2D                       tGBuffer2;
SamplerState                    sGBuffer2;
Texture2D                       tGBuffer4;
SamplerState                    sGBuffer4;
Texture2D                       tDepthTex;
SamplerState                    sDepthTex;

#if EMISSIVE
    Texture2D                   tGBuffer3;
    SamplerState                sGBuffer3;
#endif

#if SKYBOX
	Texture2D                   tEnvBRDF;
	SamplerState                sEnvBRDF;
	TextureCube                 tEnvDiffuse;
	SamplerState                sEnvDiffuse;
    TextureCube                 tEnvSpecular;
    SamplerState                sEnvSpecular;
#endif

#if SHADOW_MAP
	Texture2D                   tShadowTex;
	SamplerComparisonState      sShadowTex;
#endif

#if SHADOW_BUFFER
    Texture2D                   tShadowBufferTex;
    SamplerState                sShadowBufferTex;
#endif

#if LIGHT_MASK && POINT_LIGHT
    TextureCube                 tLightMaskTex;
    SamplerState                sLightMaskTex;
#elif LIGHT_MASK
    Texture2D                   tLightMaskTex;
    SamplerState                sLightMaskTex;
#endif

#if CLOUDS
    Texture2D                   tCloudsNoiseTex;
    SamplerState                sCloudsNoiseTex;
#endif

#include "materials/programs/shadow_utils.hlsl"

#if SKYBOX
float3 IBL( float NdotV, float3 N, float3 V, float roughness, float3 specularColor, float3 diffuseColor, float specularIntensity, float diffuseIntensity )
{
    float3 diffuseDominantDirection = N;
    float3 diffuseLight = GetEnvDiffuse( tEnvDiffuse, sEnvDiffuse, diffuseDominantDirection );
    float3 diffuse = diffuseLight * diffuseColor * diffuseIntensity;

    float smoothness = 1.0f - Pow4( roughness );
    float2 specularBRDF = GetEnvBRDF( tEnvBRDF, sEnvBRDF, float2( NdotV, smoothness ) );
    float mipLevel = roughness * 8.0f;
    float3 reflectionDir = normalize( reflect( -V, N ) );
    float3 specularLight = GetEnvSpecular( tEnvSpecular, sEnvSpecular, reflectionDir, mipLevel );
    float3 specular = specularLight * ( specularColor * specularBRDF.x + saturate( 50.0 * specularColor.g ) * specularBRDF.y ) * specularIntensity;

    return diffuse + specular;
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
    float cloud = tCloudsNoiseTex.Sample( sCloudsNoiseTex, cloudUv ).x;
    float cloudMask = tCloudsNoiseTex.Sample( sCloudsNoiseTex, cloudMaskUv ).x;
    cloud = ( ( cloudMask * cloudMackScale ) * cloud ) * cloudScale;
    return lerp( 1, saturate( cloud ), cloudsOpacity - 0.1 );
}
#endif

float4 GetAlbedoShading( Texture2D t, SamplerState s, float2 uv )
{
    float4 albedo = t.Sample(s, uv);
#if GAMMA_CORRECTION
    albedo.xyz = SRGBToLinear( albedo.xyz );
#endif 
    return albedo;
}

float3 GetNormal( Texture2D t, SamplerState s, float2 uv )
{
    return decodeNormal( t.Sample(s, uv).xyz );
}

float4 GetOcclusionRoughnessMetalness( Texture2D t, SamplerState s, float2 uv )
{
    float4 material = t.Sample(s, uv).xyzw;
    material.x = saturate( material.x );
    return material;
}

float3 GetCustomData( Texture2D t, SamplerState s, float2 uv )
{
    float3 data = t.Sample(s, uv).xyz;
#if GAMMA_CORRECTION
    data.xyz = SRGBToLinear( data.xyz );
#endif
    return data;
}

PS_OUTPUT mainFP( VS_OUTPUT In )
{
    PS_OUTPUT output;
    output.Color = float4( 0.0f, 0.0f, 0.0f, 1.0f );

    float4 screenUV = In.TexCoord;
#if POINT_LIGHT || SPOT_LIGHT
    screenUV /= screenUV.w;
    screenUV.xy = float2(screenUV.x, screenUV.y * -1) * 0.5 + 0.5;
#endif

    float4 albedoShading = GetAlbedoShading( tGBuffer0, sGBuffer0, screenUV.xy );
    float4 occlusionRoughnessMetalness = GetOcclusionRoughnessMetalness( tGBuffer2, sGBuffer2, screenUV.xy );

    float depth = tDepthTex.SampleLevel( sDepthTex, screenUV.xy, 0.0f ).r;
    float2 viewUV = ( screenUV.xy * float2( 2.0f, -2.0f ) ) - float2( 1.0f, -1.0f );
    float4 viewPos = float4( viewUV * cFocalParams.zw * -depth, depth, 1.0f );
    float4 worldPos = mul( cInvView, viewPos );

    float roughness = occlusionRoughnessMetalness.y;
    float metalness = occlusionRoughnessMetalness.z;
    float occlusion = occlusionRoughnessMetalness.x;

#if POINT_LIGHT || SPOT_LIGHT
    float3 toLightVec = worldPos.xyz * cLightWorldPos.w - cLightWorldPos.xyz;
    float dotVector = dot( toLightVec,toLightVec );
    float rcpVectorlength = rsqrt( dotVector );
    float distanceToLight = rcpVectorlength * dotVector;
    float3 L = -toLightVec * rcpVectorlength;
#else
    float3 L = cLightWorldPos.xyz;
#endif

    float attenuation = 1.0f;

#if POINT_LIGHT
    attenuation *= GetDistanceAttenuation( distanceToLight, cLightParams.w );
#elif SPOT_LIGHT
    attenuation *= GetAngleAttenuation( L, cLightWorldDir, cSpotLightParams.z, cSpotLightParams.w );
    attenuation *= GetDistanceAttenuation( distanceToLight, cLightParams.w );
#elif CLOUDS && DIRECTIONAL_LIGHT
    attenuation *= GetCloudsAttenuation( worldPos, cLightWorldDir, cTime, cCloudsParams.x, cCloudsParams.zw );
#endif

    float3 N    = GetNormal( tGBuffer1, sGBuffer1, screenUV.xy );
    float3 V    = normalize( cCameraWorldPos - worldPos.xyz );
    float3 H    = normalize( L + V );

    float NdotV = abs( dot( N, V ) ) + 0.001;
    float LdotH = saturate( dot( L, H ) );
    float NdotH = saturate( dot( N, H ) );
    float NdotL = clamp( dot( N, L ), 0.001, 1.0);

    float3 albedo = albedoShading.xyz;
    float3 diffuseColor = lerp( albedo.xyz, 0.0f, metalness );
    float3 specularColor = lerp( 0.04f, albedo.xyz, metalness );

    float3 F    = F_Schlick( specularColor, LdotH );
    float  G    = V_SmithJointApprox( Pow4( roughness ), NdotV, NdotL );
    float  D    = D_GGX( Pow4( roughness ), NdotH );

    float3 specularTerm = ( D * G * F );
    float3 diffuseTerm = DisneyDiffuse( diffuseColor, roughness, NdotV, NdotL, LdotH ) ;

#if LIGHT_MASK && DIRECTIONAL_LIGHT
    float4 lightUV = mul( cLightMaskViewProj, worldPos );
    attenuation *= tLightMaskTex.Sample( sLightMaskTex, lightUV.xy ).x;
#elif LIGHT_MASK && SPOT_LIGHT
    float4 lightUV = mul( cLightMaskViewProj, worldPos );
    lightUV.xy = lightUV.xy / lightUV.w + float2( 0.5, 0.5 );
    attenuation *= tLightMaskTex.Sample( sLightMaskTex, lightUV.xy ).x;
#elif LIGHT_MASK && POINT_LIGHT
    float4 lightUV = mul( cLightMaskViewProj, worldPos );
    attenuation *= tLightMaskTex.Sample( sLightMaskTex, lightUV.xyz ).x;
#endif

    output.Color.xyz = NdotL * attenuation * cLightParams.xyz * ( diffuseTerm + specularTerm );

    float3 subsurface = GetCustomData( tGBuffer4, sGBuffer4, screenUV.xy );
    if ( subsurface.x > 0.0f )
    {
#if DIRECTIONAL_LIGHT
        float inScatter = saturate( ( 1.5 + dot( L, -V ) ) / 2.0 ) * subsurface.y;
#elif SPOT_LIGHT
        float inScatter = pow( saturate( dot( L, -V ) ), 3 );
#elif POINT_LIGHT
        float inScatter = pow( saturate( dot( L, -V ) ), 6 );
#endif
        float normalContribution = saturate( dot( N, H ) );
        float backScatter = ( 1 - occlusion ) * normalContribution / ( 3.14f * 2 );
        output.Color.xyz += cLightParams.xyz * attenuation * lerp( backScatter, 1, inScatter ) * albedo * subsurface.x;
    }

#if SHADOW_MAP
    float4 shadowUV = mul( cShadowViewProj, worldPos );
    float shadow = GetShadow( shadowUV );
#elif SHADOW_BUFFER && DIRECTIONAL_LIGHT
    float shadow = tShadowBufferTex.Sample( sShadowBufferTex, screenUV.xy ).y;
#elif SHADOW_BUFFER && SPOT_LIGHT
    float shadow = tShadowBufferTex.Sample( sShadowBufferTex, screenUV.xy ).z;
#elif SHADOW_BUFFER && POINT_LIGHT
    float shadow = tShadowBufferTex.Sample( sShadowBufferTex, screenUV.xy ).w;
#endif

#if SHADOW_MAP || SHADOW_BUFFER
#if DIRECTIONAL_LIGHT
    float shadowIntensity = cShadowParams.z;
#else
    float shadowIntensity = 1.0f;
#endif
    float shadowLuminosityFactor = 1.0 - ( ( 1.0 - shadow ) * clamp( shadowIntensity, 0.0f, 1.0f ) );
    float shadowAmbientFactor = 1.0 - ( ( 1.0 - shadow ) * clamp( shadowIntensity - 1.0f, 0.0f, 1.0f ) );
    output.Color.xyz *= shadowLuminosityFactor;
#endif

#if SKYBOX
    output.Color.xyz += IBL( NdotV, N, V, roughness, specularColor, diffuseColor, cSkyboxParams.x, cSkyboxParams.y );
#endif

#if SHADOW_MAP || SHADOW_BUFFER
    output.Color.xyz *= shadowAmbientFactor;
#endif

    output.Color.xyz *= occlusion;

#if EMISSIVE
    float3 emissive = GetCustomData( tGBuffer3, sGBuffer3, screenUV.xy );
  	output.Color.xyz = output.Color.xyz + emissive.xyz;
#endif

    return output;
}

