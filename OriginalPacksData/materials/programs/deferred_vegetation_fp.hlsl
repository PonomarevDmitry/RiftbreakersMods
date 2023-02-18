#include "materials/programs/utils.hlsl"
#include "materials/programs/pack_ops.hlsl"

cbuffer FPConstantBuffer : register(b0)
{    
    float       cGlowAmount;
    float       cGlowFactor;
#if USE_DISSOLVE_MAP  
    float       cDissolveAmount;
    float       cDissolveSize;
    float4      cDissolveColor;
#endif
#if USE_SUBSURFACE
    float4      cSubSurfaceColor;
#endif
#if USE_BURNED_MAP
    float4      cBurningAmount;
    float4      cBurningColor;
#endif
};

struct VS_OUTPUT
{
    float4      Position      : SV_POSITION;
    float2      UV0           : TEXCOORD0;
    float3      Normal        : TEXCOORD1;
    float3      Tangent       : TEXCOORD2;
    float3      BiNormal      : TEXCOORD3;
    float3      WorldPos      : TEXCOORD4;
#if USE_TWOSIDEDSIGN
    bool        IsFrontFace   : SV_IsFrontFace;
#endif
};

struct PS_OUTPUT
{
    float4      GBuffer0      : SV_TARGET0; // Albedo (xyz), 
    float4      GBuffer1      : SV_TARGET1; // World Space Normal (xyz)
    float4      GBuffer2      : SV_TARGET2; // Occlusion (x), Roughness (y), Metalness (z)
    float4      GBuffer3      : SV_TARGET3; // Emissive (xyz)
    float4      GBuffer4      : SV_TARGET4; // SubsurfaceScattering (xyz)
};

Texture2D       tAlbedoTex;
SamplerState    sAlbedoTex;
Texture2D       tNormalTex;
SamplerState    sNormalTex;
Texture2D       tPackedTex;
SamplerState    sPackedTex;
Texture2D       tEmissiveTex;
SamplerState    sEmissiveTex;
Texture2D       tGradientTex;
SamplerState    sGradientTex;
#if USE_SUBSURFACE_MAP
Texture2D       tSubSurfaceTex;
SamplerState    sSubSurfaceTex;
#endif
#if USE_DISSOLVE_MAP
Texture2D       tDissolveTex;
SamplerState    sDissolveTex;
#endif
#if USE_BURNED_MAP
Texture2D       tBurnedAlbedoTex;
SamplerState    sBurnedAlbedoTex;
Texture2D       tBurnedNormalTex;
SamplerState    sBurnedNormalTex;
Texture2D       tBurnedEmissiveTex;
SamplerState    sBurnedEmissiveTex;
Texture2D       tBurnedGradientTex;
SamplerState    sBurnedGradientTex;
#endif
#if USE_REFLECTION_MAP
TextureCube     tReflectionTex;
SamplerState    sReflectionTex;
#endif

PS_OUTPUT mainFP( VS_OUTPUT In )
{
    PS_OUTPUT Out;

    float4 albedo = tAlbedoTex.Sample( sAlbedoTex, In.UV0.xy ).xyzw;

#if USE_ALPHA_TEST
    clip( albedo.a > 0.25 ? 1 : -1 );
#endif

#if USE_SNOW && USE_SUBSURFACE
    if ( albedo.a > 0.75 || cSubSurfaceColor.x > 0 ) 
        albedo.xyz = lerp( albedo.xyz, float3(1.0, 1.0, 1.0) - tBurnedAlbedoTex.Sample( sBurnedAlbedoTex, In.UV0.xy ).xyz, 0.5);
#endif

    Out.GBuffer0.xyzw = float4( albedo.xyz, 1.0f );
    Out.GBuffer2.xyzw = tPackedTex.Sample( sPackedTex, In.UV0.xy );

    float3 texNormal = texNormal2D( tNormalTex, sNormalTex, In.UV0.xy );
    float3x3 normalRotation = float3x3( In.Tangent, In.BiNormal, In.Normal );
    float3 normal = mul( texNormal, normalRotation );

#if USE_TWOSIDEDSIGN
    normal *= float( In.IsFrontFace ? +1 : -1 );
#endif

    float gradient = tGradientTex.Sample( sGradientTex, In.UV0.xy ).x;
    float3 emissive = tEmissiveTex.Sample( sEmissiveTex, In.UV0.xy ).xyz * gradient; 
    emissive *= cGlowAmount * cGlowFactor;

#if USE_DISSOLVE_MAP || USE_BURNED_MAP
    float dissolve = tDissolveTex.Sample( sDissolveTex, In.UV0.xy ).x;
#endif

#if USE_BURNED_MAP
    float burningDiff = dissolve - cBurningAmount.x;
    if ( burningDiff >= 0 )
    {

    }
    else if ( abs( burningDiff ) < 0.1f && cBurningAmount.x > 0 && cBurningAmount.x < 1 )
    {
        float burningPower = abs( burningDiff ) / 0.1f;
        float3 burningColor = cBurningColor.xyz;
        burningColor += burningPower * burningPower;
        burningColor *= cBurningAmount.x * burningPower;
        emissive.xyz = burningColor * 8.0f;
    }
    else
    {
#if USE_ALPHA_TEST
        clip( albedo.a > 0.75f ? 1:-1 );
#endif
        float3 texNormal = texNormal2D( tBurnedNormalTex, sBurnedNormalTex, In.UV0.xy );
        normal += mul( texNormal, normalRotation );
        Out.GBuffer0.xyz = tBurnedAlbedoTex.Sample( sBurnedAlbedoTex, In.UV0.xy ).xyz;
#if !USE_SUBSURFACE_MAP
        Out.GBuffer2.yz = float2( max( 0.8f, Out.GBuffer2.y ), 1.0f );
#endif
        float burnedGradient = tBurnedGradientTex.Sample( sBurnedGradientTex, In.UV0.xy ).x * tDissolveTex.Sample( sDissolveTex, cBurningAmount.zw / 50 ).x;
        emissive.xyz = tBurnedEmissiveTex.Sample( sBurnedEmissiveTex, In.UV0.xy + cBurningAmount.zw ).xyz * burnedGradient * cBurningAmount.y * 50.0f;
    }
#endif

    Out.GBuffer1.xyz = encodeNormal( normal );

#if USE_DISSOLVE_MAP
    clip( dissolve >= cDissolveAmount ? 1:-1 );
    float dissolveDiff = dissolve - cDissolveAmount;
    if ( dissolveDiff < cDissolveSize && cDissolveAmount > 0 && cDissolveAmount < 1 )
    {
        float dissolvePower = saturate( dissolveDiff / cDissolveSize );
        float3 dissolveColor = cDissolveColor.rgb;
        dissolveColor += cDissolveColor.a * dissolvePower * dissolvePower;
        dissolveColor *= cDissolveAmount * dissolvePower;
        emissive.xyz = dissolveColor;
    }
#endif

    Out.GBuffer3 = float4( emissive, 1.0 );

#if USE_SUBSURFACE_MAP
    Out.GBuffer4 = float4( tSubSurfaceTex.Sample( sSubSurfaceTex, In.UV0.xy ).xyz, 1.0 );
#elif USE_SUBSURFACE
    Out.GBuffer4 = float4( cSubSurfaceColor.xyz * ( 1 - Out.GBuffer2.z ), 1.0 );
    Out.GBuffer2.z = 0.0;
#else
    Out.GBuffer4 = float( 0.0, 0.0, 0.0, 1.0 );
#endif

    return Out;
}
