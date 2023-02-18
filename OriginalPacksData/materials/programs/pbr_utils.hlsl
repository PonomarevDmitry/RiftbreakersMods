#include "materials/programs/utils.hlsl"

inline float Pow5( float x )
{
    float xx = x * x;
    return xx * xx * x;
}

inline float Pow4( float x )
{
    float xx = x * x;
    return xx * xx;
}

// Burley 2012, "Physically-Based Shading at Disney"
inline float3 DisneyDiffuse( float3 diffuseColor, float roughness, float NdotV, float NdotL, float LdotH )
{
    float energyBias = lerp( 0.0, 0.5, roughness );
    float energyFactor = lerp( 1.0 , 1.0 / 1.51, roughness );
    float fd90 = energyBias + 2.0 * LdotH * LdotH * roughness;

    float lightScatter = 1 + ( fd90 - 1 ) * Pow5( 1 - NdotL );
    float viewScatter = 1 + ( fd90 - 1 ) * Pow5( 1 - NdotV );

    return diffuseColor * (lightScatter * viewScatter * energyFactor) * ( 1 / PI );
}

// Walter 2007, "Microfacet models for refraction through rough surfaces"
inline float D_GGX( float roughness, float NdotH )
{
    float a = max( 0.001f, roughness );
    float a2 = a * a;
    float d = ( NdotH * a2 - NdotH ) * NdotH + 1;
    return a2 / ( PI * d * d + 1e-7f);
}

// Schlick 1994, "An Inexpensive BRDF Model for Physically-Based Rendering"
inline float3 F_Schlick( float3 specularColor, float VdotH )
{
    return specularColor + (1 - specularColor) * Pow5( 1 - VdotH );
}

// Smith 1967, "Geometrical shadowing of a random rough surface"
inline float V_Smith( float roughness, float NdotV, float NdotL )
{
    float a = roughness;
    float a2 = a * a;

    float schlickV = NdotV + sqrt( NdotV * (NdotV - NdotV * a2) + a2 );
    float schlickL = NdotL + sqrt( NdotL * (NdotL - NdotL * a2) + a2 );

    return rcp( schlickV * schlickL );
}

// Schlick 1994, "An Inexpensive BRDF Model for Physically-Based Rendering"
inline float V_Schlick( float roughness, float NdotV, float NdotL )
{
    float a = roughness;
    float k = a * 0.5;

    float schlickV = NdotV * (1 - k) + k;
    float schlickL = NdotL * (1 - k) + k;

    return 0.25 / ( schlickV * schlickL );
}

// Heitz 2014, "Understanding the Masking-Shadowing Function in Microfacet-Based BRDFs"
inline float V_SmithJointApprox( float roughness, float NdotV, float NdotL )
{
    float a = roughness;
    float k = a;

    float schlickV = NdotL * ( NdotV * ( 1 - k ) + k );
    float schlickL = NdotV * ( NdotL * ( 1 - k ) + k );

    return 0.5 * rcp( schlickV + schlickL + 1e-5f );
}

inline float2 GetEnvBRDF( Texture2D t, SamplerState s, float2 uv )
{
    return t.Sample(s, uv).xy;
}

inline float3 GetEnvDiffuse( TextureCube t, SamplerState s, float3 uvw )
{
    return t.Sample(s, uvw).xyz;
}

inline float3 GetEnvSpecular( TextureCube t, SamplerState s, float3 uvw, float mip )
{
    return t.SampleLevel(s, uvw, mip).xyz;
}

inline float3 GetEnvSpecular( Texture2D t, SamplerState s, float2 uv )
{
    return t.Sample(s, uv).xyz;
}

inline float GetDistanceAttenuation( float distance, float lightInvSquareRadius )
{
    float d2 = distance * distance;
    float attenuation = 1.0 / (d2 + 1.0);
    attenuation *= pow( saturate(1.0f - pow( d2 * lightInvSquareRadius, 2.0f)), 2.0f);
    return attenuation;
}

inline float GetAngleAttenuation( float3 L, float3 lightDir, float lightAngleScale, float lightAngleOffset )
{
    float cd = dot( L, -lightDir );
    float attenuation = saturate ( cd * lightAngleScale + lightAngleOffset ) ;
    attenuation *= attenuation;
    return attenuation;
}
