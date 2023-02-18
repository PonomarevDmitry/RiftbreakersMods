#include "materials/programs/pack_ops.hlsl"
#include "materials/programs/pbr_utils.hlsl"

cbuffer FPConstantBuffer : register(b0)
{
    float4      cFocalParams; 
    float4      cSkyboxParams;     // skyboxDiffuseIntensity (x), skyboxSpecularIntensity (y)
    matrix      cInvView;
    float4      cCameraWorldPos;
};

struct VS_OUTPUT
{
    float4      Position : SV_POSITION;
    float2      TexCoord : TEXCOORD0;
};

struct PS_OUTPUT
{
    float4      Color    : SV_TARGET;
};

Texture2D                       tGBuffer0;
SamplerState                    sGBuffer0;
Texture2D                       tGBuffer1;
SamplerState                    sGBuffer1;
Texture2D                       tGBuffer2;
SamplerState                    sGBuffer2;
Texture2D                       tDepthTex;
SamplerState                    sDepthTex;
Texture2D                       tEnvBRDF;
SamplerState                    sEnvBRDF;
TextureCube                     tEnvDiffuse;
SamplerState                    sEnvDiffuse;
Texture2D                       tReflections;
SamplerState                    sReflections;

float3 IBL( float NdotV, float3 N, float roughness, float3 specularLight, float3 specularColor, float3 diffuseColor, float specularIntensity, float diffuseIntensity )
{
    float smoothness = 1.0f - roughness;

    float3 diffuseDominantDirection = N;
    float3 diffuseLight = GetEnvDiffuse( tEnvDiffuse, sEnvDiffuse, diffuseDominantDirection );
    float3 diffuse = diffuseLight * diffuseColor * diffuseIntensity;

    float2 specualrBRDF = GetEnvBRDF( tEnvBRDF, sEnvBRDF, float2( NdotV, smoothness ) );
    float3 specular = specularLight * ( specularColor * specualrBRDF.x + saturate( 50.0 * specularColor.g ) * specualrBRDF.y ) * specularIntensity;

    return diffuse + specular;
}

float3 GetAlbedo( Texture2D t, SamplerState s, float2 uv )
{
    float3 albedo = t.Sample(s, uv).xyz;
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

float3 GetReflections( Texture2D t, SamplerState s, float2 uv )
{
    return t.Sample(s, uv).xyz;
}

PS_OUTPUT mainFP( VS_OUTPUT In )
{            
    PS_OUTPUT output;
    output.Color = float4( 0.0f, 0.0f, 0.0f, 1.0f );

    float2 screenUV = In.TexCoord;

    float depth = tDepthTex.SampleLevel( sDepthTex, screenUV.xy, 0.0f ).r;
    float2 viewUV = ( screenUV.xy * float2( 2.0f, -2.0f ) ) - float2( 1.0f, -1.0f );
    float4 viewPos = float4( viewUV * cFocalParams.zw * -depth, depth, 1.0f );
    float4 worldPos = mul( cInvView, viewPos );

    float3 N    = GetNormal( tGBuffer1, sGBuffer1, screenUV.xy );
    float3 V    = normalize( cCameraWorldPos - worldPos.xyz );

    float NdotV = abs( dot( N, V ) ) + 0.001;

    float3 albedo = GetAlbedo( tGBuffer0, sGBuffer0, screenUV.xy );
    float4 occlusionRoughnessMetalness = GetOcclusionRoughnessMetalness( tGBuffer2, sGBuffer2, screenUV.xy );
    float roughness = occlusionRoughnessMetalness.y; 
    float metalness = occlusionRoughnessMetalness.z;
    float occlusion = occlusionRoughnessMetalness.x;

    float3 specularLight = GetReflections( tReflections, sReflections, screenUV.xy );
    float3 diffuseColor = lerp( albedo.xyz, 0.0f, metalness );
    float3 specularColor = lerp( 0.04f, albedo.xyz, metalness );

    output.Color.xyz += IBL( NdotV, N, Pow4( roughness ), specularLight, specularColor, diffuseColor, cSkyboxParams.x, cSkyboxParams.y );
    output.Color.xyz *= occlusion;
    
    return output;
}