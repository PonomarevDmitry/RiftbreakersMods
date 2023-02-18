#include "materials/programs/utils.hlsl"

cbuffer FPConstantBuffer : register(b0)
{  
#if USE_GRADIENT_MAP
    float4    cEmissiveColor;
#endif    
#if USE_FRESNEL
    float4    cFresnelColor;
    float     cFresnelBias;
    float     cFresnelScale;
    float     cFresnelPower;
#endif
#if USE_DISSOLVE_MAP
    float4      cDissolveColor;
    float       cDissolveSize;
    float       cDissolveAmount;
#endif
#if USE_EMISSIVE_MAP
    float     cGlowAmount;
#endif
    float     cGlowFactor;
    float     cAlpha;
};

struct VS_OUTPUT
{
    float4 Position       : SV_POSITION;
    float2 TexCoord       : TEXCOORD0;
    float3 WorldNormal    : TEXCOORD1;
    float3 WorldEyeDir    : TEXCOORD2;
};

	Texture2D       tColorTex;
	SamplerState    sColorTex;

#if USE_EMISSIVE_MAP
    Texture2D       tEmissiveTex;
	SamplerState    sEmissiveTex;
#endif

#if USE_GRADIENT_MAP
	Texture2D       tGradientTex;
    SamplerState    sGradientTex;
#endif

#if USE_DISSOLVE_MAP
	Texture2D       tDissolveTex;
	SamplerState    sDissolveTex;
#endif

struct PS_OUTPUT
{
    float4      Color               : SV_TARGET0;
#if USE_UPSCALE_MASK
    float       UpscaleMask         : SV_TARGET1;
#endif
};

PS_OUTPUT mainFP( VS_OUTPUT In ) 
{
    PS_OUTPUT Out;

    Out.Color = texLinear2D( tColorTex, sColorTex, In.TexCoord );

	#if USE_FRESNEL
	    float fresnel = cFresnelBias + cFresnelScale * pow( 1 + dot( In.WorldEyeDir, In.WorldNormal ), cFresnelPower );
	    Out.Color.xyz = lerp( Out.Color.xyz, cFresnelColor.xyz * cGlowFactor, saturate( fresnel ) );
	#endif

	#if USE_EMISSIVE_MAP && USE_GRADIENT_MAP
	    float emissivePower = tEmissiveTex.Sample( sEmissiveTex, In.TexCoord ).x * tGradientTex.Sample( sGradientTex, In.TexCoord ).x;
	    float3 emissiveColor = cEmissiveColor.rgb;
	    emissiveColor += cEmissiveColor.a * emissivePower * emissivePower;
	    emissiveColor *= cGlowAmount * cGlowFactor * emissivePower;
	    Out.Color.xyz = lerp( Out.Color.xyz, emissiveColor, emissivePower );
	#elif USE_EMISSIVE_MAP
	    float emissivePower = tEmissiveTex.Sample( sEmissiveTex, In.TexCoord ).x;
	    float3 emissiveColor = Out.Color.xyz * cGlowAmount * cGlowFactor * emissivePower;
	    Out.Color.xyz = lerp( Out.Color.xyz, emissiveColor, emissivePower );
	#endif

	#if USE_DISSOLVE_MAP
	    float dissolve = tDissolveTex.Sample( sDissolveTex, In.TexCoord ).x;
	    clip( dissolve >= cDissolveAmount ? 1:-1 );

	    float dissolveDiff = dissolve - cDissolveAmount;
	    if ( dissolveDiff < cDissolveSize && cDissolveAmount > 0 && cDissolveAmount < 1 )
	    {
	        float dissolvePower = saturate( dissolveDiff / cDissolveSize );
	        float3 dissolveColor = cDissolveColor.rgb;
	        dissolveColor += cDissolveColor.a * dissolvePower * dissolvePower;
	        dissolveColor *= cDissolveAmount * dissolvePower;
	        Out.Color.xyz = dissolveColor;
	    }
	#endif

	Out.Color.a *= cAlpha;

#if USE_UPSCALE_MASK
    Out.UpscaleMask = 0.5f * Out.Color.a;
#endif

    return Out;
}


