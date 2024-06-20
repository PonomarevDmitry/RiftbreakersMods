cbuffer FPConstantBuffer : register(b0)
{
    matrix      cWorld;
    float4      cEmissiveColor;
    float       cGlowAmount;
    float       cGlowFactor;
    float       cAlpha;
    float       cTime; 
    float3      cTargetPos;
    float       cRadius;
    float       cIsEnemy;
#if USE_FOG
    float      cFogMaxDistance;
#endif
};

struct VS_OUTPUT
{
    float4      Position         : SV_POSITION;
    float2      TexCoord         : TEXCOORD0;
    float4      ObjectPos        : TEXCOORD1;
    float4      WorldPos         : TEXCOORD2;
    float4      ProjPos          : TEXCOORD3;
};

struct PS_OUTPUT
{
    float4      Color            : SV_TARGET0;
};

Texture2D       tColorTex;
SamplerState    sColorTex;
Texture2D       tEnemyTex;
SamplerState    sEnemyTex;
Texture2D       tEmissiveTex;
SamplerState    sEmissiveTex;
Texture2D       tGradientTex;
SamplerState    sGradientTex;
#if USE_FOG
Texture3D       tLightScattering;
SamplerState    sLightScattering;
#endif

#include "materials/programs/utils.hlsl"
#include "materials/programs/utils_fog.hlsl"


PS_OUTPUT mainFP( VS_OUTPUT In ) 
{  
    PS_OUTPUT Out;

    float2 targetDir = cTargetPos.xz - float2( cWorld[0][3], cWorld[2][3] );
    float targetDistance = length( targetDir );
    targetDir = normalize( targetDir );
    float2 pixelDir = normalize( In.WorldPos.xz - float2( cWorld[0][3], cWorld[2][3] ) );

    float4 color = ( cIsEnemy > 0.0f ) ? texLinear2D( tEnemyTex, sEnemyTex, In.TexCoord ) : texLinear2D( tColorTex, sColorTex, In.TexCoord );

    float circleDistance = length( ( In.TexCoord.xy - float2( 0.5f, 0.5f ) ) * 2.0f );

    float pulseSpeed = 4.0f;
    if ( targetDistance < cRadius )
    {   
        float radiusRatio = targetDistance / cRadius;
        if ( radiusRatio > 0.75 )
            pulseSpeed = 7.0f;
        else if ( radiusRatio > 0.5 )
            pulseSpeed = 9.0f;
        else if ( radiusRatio > 0.25 )
            pulseSpeed = 11.0f;
        else
            pulseSpeed = 14.0f;
    }

    float pulseFrequency = 3.0f;
    float pulseScale = 8.0f;
    float pulsePower = ( sin( pulseFrequency * ( ( pulseSpeed *  cTime ) - ( circleDistance * pulseScale ) ) ) + 1 ) / 2;
    pulsePower *= ( 1.0f - ( circleDistance * circleDistance ) );

    float emissivePower = 0.0f;
    emissivePower = lerp( 0.0f, 0.5f, pulsePower );
    emissivePower += ( pulsePower > 0.0f ) ? tEmissiveTex.Sample( sEmissiveTex, In.TexCoord ).x * tGradientTex.Sample( sGradientTex, In.TexCoord ).x : 0.0f;
    float3 emissiveColor = ( cIsEnemy > 0.0f ) ? float3( 10.0f, 2.0f, 0.0f ) : cEmissiveColor.rgb;
    emissiveColor += cEmissiveColor.a * emissivePower * emissivePower;
    emissiveColor *= cGlowAmount * cGlowFactor * emissivePower;
    color.xyz = lerp( color.xyz, emissiveColor, emissivePower );
    color.a *= cAlpha;

    Out.Color = color;

    if ( targetDistance / cRadius > 1.0f )
    {
        float maxDistance = cRadius;
        float distance = targetDistance - cRadius;
        float distancePower = saturate( distance / maxDistance );
        float dotPower = lerp( 0.0f, 0.9f, distancePower );

        float dotProduct = dot( pixelDir, targetDir );
        if ( dotProduct < dotPower )
        {
            if ( dotPower - dotProduct < 0.2 )
            {
                float maxDistance2 = 0.2f;
                float distance2 = dotPower - dotProduct;
                float distancePower2 = saturate( distance2 / maxDistance2 );
                float dotPower2 = lerp( 1.0f, 0.0f, distancePower2 );
                Out.Color.xyzw *= dotPower2;
            } 
            else
            {
                Out.Color.xyzw *= 0.25f;
            }
        }
    }
    else if ( targetDistance / cRadius > 0.8f )
    {
        float maxDistance = cRadius * 0.2f;
        float distance = cRadius - targetDistance;
        float distancePower = saturate( distance / maxDistance );
        float dotPower = lerp( 0.0f, -1.0f, distancePower );

        float dotProduct = dot( pixelDir, targetDir );
        if ( dotProduct < dotPower )
        {
            if ( dotPower - dotProduct < 0.2 )
            {
                float maxDistance2 = 0.2f;
                float distance2 = dotPower - dotProduct;
                float distancePower2 = saturate( distance2 / maxDistance2 );
                float dotPower2 = lerp( 1.0f, 0.0f, distancePower2 );
                Out.Color.xyzw *= dotPower2;
            } 
            else
            {
                Out.Color.xyzw *= 0.25f;
            }
        }
    }

    float alphaPulsePower = 1.0f;
    float radiusRatio = targetDistance / cRadius;
    if ( radiusRatio < 1.0f )
    {         
        if ( radiusRatio > 0.75 )
            alphaPulsePower = 2.0f;
        else if ( radiusRatio > 0.5 )
            alphaPulsePower = 4.0f;
        else if ( radiusRatio > 0.25 )
            alphaPulsePower = 5.0f;
        else
            alphaPulsePower = 6.0f;
    }

    float alphaPulse = ( sin( PI * 2.0f * cTime * alphaPulsePower ) + 1.0f ) / 2.0f;
    Out.Color.w *= alphaPulse + ( 1.0f - alphaPulse ) * 0.25f;

#if USE_FOG
    Out.Color.xyz = GetFog( Out.Color.xyz, In.ProjPos );
#endif

    return Out;
}


