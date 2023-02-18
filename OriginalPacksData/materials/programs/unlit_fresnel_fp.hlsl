#include "materials/programs/utils.hlsl"

cbuffer FPConstantBuffer : register(b0)
{
    float4    cBlendColor1;
    float4    cBlendColor2;
#if USE_BURNED_MAP
    float4    cBurningAmount;
#endif
#if USE_DISSOLVE_MAP
    float4    cDissolveColor;
    float     cDissolveSize;
#endif
#if USE_DISSOLVE_MAP || USE_BURNED_MAP
    float     cDissolveAmount;
#endif
    float     cFresnelBias;
    float     cFresnelScale;
    float     cFresnelPower;
#if USE_FLARE
    float     cTime;     
    float     cFlarePower;
    float     cFlareSpeed;
#endif
#if USE_NOISE_MAP
    float4    cNoiseColor;
    float     cNoisePower;
    float     cNoiseTileScale;
#endif
#if USE_ALPHA
    float     cAlpha;
#endif
};

struct VS_OUTPUT
{
    float4 Position       : SV_POSITION;
    float2 TexCoord       : TEXCOORD0;
    float3 WorldNormal    : TEXCOORD1;
    float3 WorldEyeDir    : TEXCOORD2;
#if USE_NORMAL_MAP
    float3 WorldTangent   : TEXCOORD3;
    float3 WorldBiNormal  : TEXCOORD4;
#endif    
    float4 ProjPos        : TEXCOORD5;
};

struct PS_OUTPUT
{
    float4      Color       : SV_TARGET0;
};

#if USE_ALPHA_TEST
Texture2D       tAlbedoTex;
SamplerState    sAlbedoTex;
#endif
#if USE_DISSOLVE_MAP || USE_BURNED_MAP
Texture2D       tDissolveTex;
SamplerState    sDissolveTex;
#endif
 #if USE_NORMAL_MAP
Texture2D       tNormalTex;
SamplerState    sNormalTex;
#endif
#if USE_NOISE_MAP
Texture2D       tNoiseTex;
SamplerState    sNoiseTex;
#endif

PS_OUTPUT mainFP( VS_OUTPUT In ) 
{
    PS_OUTPUT Out;

#if USE_ALPHA_TEST
    float alpha = tAlbedoTex.Sample( sAlbedoTex, In.TexCoord ).w;
    clip( alpha > 0.25 ? 1 : -1 );
#endif

#if USE_DISSOLVE_MAP || USE_BURNED_MAP
    float dissolve = tDissolveTex.Sample( sDissolveTex, In.TexCoord ).x;
    clip( dissolve >= cDissolveAmount ? 1:-1 );    
#endif

#if USE_BURNED_MAP && USE_ALPHA_TEST
    if ( dissolve - cBurningAmount.x < 0 )
    {
        clip( alpha > 0.75f ? 1:-1 );
    }
#endif

#if USE_NORMAL_MAP
    float3 texNormal = texNormal2D( tNormalTex, sNormalTex, In.TexCoord );
    float3x3 normalRotation = float3x3( In.WorldTangent, In.WorldBiNormal, In.WorldNormal );
    float3 normal = mul( texNormal, normalRotation ).xyz;
#else
    float3 normal = In.WorldNormal.xyz;
#endif

    float fresnel = calcFresnel( cFresnelBias, cFresnelScale, cFresnelPower, In.WorldEyeDir, normal );

#if USE_FLARE
    fresnel = fresnel + cos( cTime * cFlareSpeed ) * cFlarePower;
#endif

    Out.Color = lerp( cBlendColor1, cBlendColor2, saturate( fresnel ) );
    Out.Color.w = saturate( Out.Color.w );

#if USE_DISSOLVE_MAP 
    float dissolveDiff = dissolve - cDissolveAmount;
    if ( dissolveDiff < cDissolveSize && cDissolveAmount > 0 && cDissolveAmount < 1 )
    {     
        float dissolvePower = saturate( dissolveDiff / cDissolveSize );
        float3 dissolveColor = cDissolveColor.rgb;
        dissolveColor += cDissolveColor.a * dissolvePower * dissolvePower;
        dissolveColor *= cDissolveAmount * dissolvePower;
        Out.Color = lerp( Out.Color, float4( dissolveColor.xyz, dissolvePower ), dissolvePower );
    }
#endif

#if USE_NOISE_MAP
    float2 screenPos = In.ProjPos.xy / In.ProjPos.w;
    screenPos = screenPos * float2( 0.5f, -0.5f ) + float2( 0.5f, 0.5f );
    Out.Color += cNoiseColor * tNoiseTex.Sample( sNoiseTex, screenPos * cNoiseTileScale ) * cNoisePower;
#endif

#if USE_ALPHA
    Out.Color.w *= cAlpha;
#endif

    Out.Color.w = saturate( Out.Color.w );

    return Out;
}


