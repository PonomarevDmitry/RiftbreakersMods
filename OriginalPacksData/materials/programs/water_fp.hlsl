#include "materials/programs/pbr_utils.hlsl"

cbuffer FPConstantBuffer : register(b0)
{
    matrix    cInvProj;
    matrix    cInvView;
    matrix    cViewProj;

    float4    cSkyboxParams;
    float4    cPBRLightParams;
    float4    cLightDirection;

    float4    cWaterColor;
    float     cWaterDepth;
    float     cWaterDepthBias;
    float     cWaterLevel;

    float4    cFogParams;
    float4    cFogColour;

    float     cFresnelBias;
    float     cFresnelScale;
    float     cFresnelPower;

#if SUPPORT_SHADOW
    float     cPcfTexelOffset;
    matrix    cShadowViewProj;
#endif
};

struct VS_OUTPUT
{
    float4      Position      : SV_POSITION;
    float2      UV0           : TEXCOORD0;
    float3      ViewPos       : TEXCOORD1;
    float3      Normal        : TEXCOORD2;
    float3      Tangent       : TEXCOORD3;
    float3      BiNormal      : TEXCOORD4;

    float4      ProjPos       : TEXCOORD5;
    float3      WorldEyeDir   : TEXCOORD6;
};

struct PS_OUTPUT
{
    float4  Color0      : SV_TARGET0;
};

Texture2D       tNoise;
SamplerState    sNoise;
Texture2D       tIlluminance;
SamplerState    sIlluminance;
Texture2D       tDepthTex;
SamplerState    sDepthTex;
Texture2D       tEnvBRDF;
SamplerState    sEnvBRDF;
TextureCube     tEnvDiffuse;
SamplerState    sEnvDiffuse;
TextureCube     tEnvSpecular;
SamplerState    sEnvSpecular;
Texture2D       tFoam;
SamplerState    sFoam;

inline float4 getViewPosFromDepth( float2 screenPos )
{
    float x = screenPos.x * 2.0f - 1.0f;
    float y = (1.0f - screenPos.y) * 2.0f - 1.0f;
    float z = tDepthTex.SampleLevel( sDepthTex, screenPos.xy, 0 ).r;

    float4 projPos = float4( x, y, z, 1.0f );
    float4 viewPos = mul( cInvProj, projPos );
    viewPos = viewPos.xyzw / viewPos.w;
    return viewPos;
}

inline float4 getWorldPosFromDepth( float2 screenPos )
{
    float4 viewPos = getViewPosFromDepth( screenPos );
    return mul( cInvView, viewPos );
}

static const float REFRACTION_MAX_DEPTH = 0.5;

float3 IBL( float NdotV, float3 N, float3 reflection, float roughness, float3 specularColor, float3 diffuseColor, float specularIntensity, float diffuseIntensity )
{
    float smoothness = 1.0f - roughness;
    float mipLevel = roughness * 7.0f;

    float3 diffuseDominantDirection = N;
    float3 diffuseLight = GetEnvDiffuse( tEnvDiffuse, sEnvDiffuse, diffuseDominantDirection );
    float3 diffuse = diffuseLight * diffuseColor * diffuseIntensity;

    float2 specualrBRDF = GetEnvBRDF( tEnvBRDF, sEnvBRDF, float2( NdotV, smoothness ) );
    float3 specularLight = GetEnvSpecular( tEnvSpecular, sEnvSpecular, reflection, mipLevel );
    float3 specular = specularLight * (specularColor * specualrBRDF.x + specualrBRDF.y) * specularIntensity;

    return diffuse + specular;
}

inline float3 GetWaterColor( VS_OUTPUT In, float3 normal )
{
    float roughness = 0.15f;//max( 0.1f, 0.0f );
    float metalness = 0.0f;

    float3 L    = -cLightDirection.xyz;
    float3 N    = normal;
    float3 V    = -normalize( In.ViewPos.xyz );
    float3 H    = normalize( L + V );

    float NdotV = abs(dot(N,V)) + 0.001;
    float LdotH = saturate(dot(L,H));
    float NdotH = saturate(dot(N,H));
    float NdotL = clamp(dot(N,L), 0.001, 1.0);

    float3 WorldV = mul(cInvView,float4(V,0.0f));
    float3 WorldN = mul(cInvView,float4(N,0.0f));
    float WorldNdotV = abs(dot(WorldN,WorldV)) + 0.001;
    float3 reflection = normalize(reflect(-WorldV, WorldN));

    float3 diffuseColor = lerp( cWaterColor, 0.0f, metalness );
    float3 specularColor = lerp( 0.04f, cWaterColor, metalness );

    float3 F    = F_Schlick(specularColor, LdotH );
    float  G    = V_SmithJointApprox( roughness, NdotV, NdotL );
    float  D    = D_GGX( roughness, NdotH );

    float3 specularTerm = ( D * G * F );
    float3 diffuseTerm = DisneyDiffuse( diffuseColor, roughness, NdotV, NdotL, LdotH ) ;

    float attenuation = 0.4f;

    float3 waterColor = NdotL * attenuation * cPBRLightParams.xyz * ( diffuseTerm + specularTerm );
    waterColor += 0.6 * IBL( WorldNdotV, WorldN, reflection, roughness, specularColor, diffuseColor, cSkyboxParams.x, cSkyboxParams.y );

    return waterColor;
}

inline float3 GetRefractColor( VS_OUTPUT In, float3 normal, float3 screenPos )
{
    float2 offset = 0.02 * normal.xz / screenPos.z;

    float3 viewPos = getViewPosFromDepth( screenPos ).xyz;

    float worldDepth = length( viewPos.xyz - In.ViewPos.xyz );
    float waterDepthFactor = saturate( min( worldDepth / cWaterDepth, 1.0f ) + cWaterDepthBias );

	float4 sceneColor = tIlluminance.Sample( sIlluminance, screenPos.xy + offset );
	float4 refraction = lerp( sceneColor, cWaterColor, waterDepthFactor );
    return refraction;
}

PS_OUTPUT water_fp( VS_OUTPUT In )
{
    PS_OUTPUT Out;

    float3 screenPos = In.ProjPos.xyz / In.ProjPos.w;
    screenPos.xy = screenPos.xy * float2( 0.5f, -0.5f ) + float2( 0.5f, 0.5f );

    float3 texNormal = texNormal2D( tNoise, sNoise, In.UV0 );
    float3x3 normalRotation = float3x3( In.Tangent, In.BiNormal, In.Normal );
    float3 normal = normalize( mul( texNormal, normalRotation ).xyz );

    float3 eyeVector = normalize( In.WorldEyeDir );
    float3 worldNormal = normalize( mul( cInvView, float4( normal, 0.0f ) ).xyz );

    float3 refractColor =  GetRefractColor( In, normal, screenPos );
    float3 surfaceColor = GetWaterColor( In, normal );

    float fresnel = saturate( calcFresnel( cFresnelBias, cFresnelScale, cFresnelPower, eyeVector, worldNormal ) );
    Out.Color0.xyz = lerp( surfaceColor, refractColor, (1.0 - fresnel) );

    float y = getWorldPosFromDepth( screenPos ).y;

    float4 foamColor = tFoam.Sample( sFoam, In.UV0 * 12.0);
    float coastFactor = ( cWaterLevel - y ) / 0.5;
    if ( coastFactor < 1.0 )
        Out.Color0.xyz = lerp( foamColor.xyz, Out.Color0.xyz, saturate( (1.0 - foamColor.a) / (1.0 - coastFactor ) ) ) ;

    addFog( Out.Color0.xyz, cFogColour.rgb, -In.ViewPos.z, cFogParams );
    Out.Color0.a = 1.0;
    return Out;
}