#include "materials/programs/utils.hlsl"
#include "materials/programs/utils_pack.hlsl"

cbuffer FPConstantBuffer : register(b0)
{
#if USE_VELOCITY
    float4      cJitterOffset;
#endif
    float       cTime;
    float       cGlowAmount;
    float       cGlowFactor;
    float       cFresnelScale;
    float       cFresnelPower;
    float4      cFresnelColor;
    float       cDissolveAmount;
    float3      cWorldCameraPos;
    float       cMIPBias;
};

struct VS_OUTPUT
{
    float4      Position      : SV_POSITION;
    float2      UV0           : TEXCOORD0;
    float3      Normal        : TEXCOORD1;
    float3      Tangent       : TEXCOORD2;
    float3      BiNormal      : TEXCOORD3;
    float3      WorldPos      : TEXCOORD4;
#if USE_VELOCITY
    float4      CurrPos       : TEXCOORD5;
    float4      PrevPos       : TEXCOORD6;
#endif
};

struct PS_OUTPUT
{
    float4      GBuffer0      : SV_TARGET0; // Albedo (xyz), 
    float4      GBuffer1      : SV_TARGET1; // World Space Normal (xyz)
    float4      GBuffer2      : SV_TARGET2; // Occlusion (x), Roughness (y), Metalness (z)
    float4      GBuffer3      : SV_TARGET3; // Emissive (xyz)
    float4      GBuffer4      : SV_TARGET4; // SubsurfaceScattering (xyz)
    float2      GBuffer5      : SV_TARGET5; // Velocity (xy)
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
Texture2D       tDissolveTex;
SamplerState    sDissolveTex;

PS_OUTPUT mainFP( VS_OUTPUT In )
{
    PS_OUTPUT Out;

    Out.GBuffer0.xyzw = float4( tAlbedoTex.SampleBias( sAlbedoTex, In.UV0, cMIPBias ).xyz, 1.0f );
    Out.GBuffer2.xyz = tPackedTex.SampleBias( sPackedTex, In.UV0, cMIPBias ).xyz;
    Out.GBuffer4 = 0.0f;

    float3 texNormal = texNormal2D( tNormalTex, sNormalTex, In.UV0 );
    float3x3 normalRotation = float3x3( In.Tangent, In.BiNormal, In.Normal );
    Out.GBuffer1.xyz = encodeNormal( mul( texNormal, normalRotation ).xyz );

    float fresnelTime = cTime + ( In.WorldPos.x * In.WorldPos.z ) / 200;
    float fresnelInterval = ( cos( fresnelTime * 2.5f ) + 1 ) / 2.0f;
    float fresnelScale = cFresnelScale - ( 0.5f * cFresnelScale * fresnelInterval );
    float fresnelPower = cFresnelPower + ( 2.0f * cFresnelPower * fresnelInterval );

    float fresnel = calcFresnel( 0.0f, fresnelScale, fresnelPower, normalize( In.WorldPos - cWorldCameraPos ), In.Normal );
    float3 emissive = tEmissiveTex.Sample( sEmissiveTex, In.UV0 ).x * tGradientTex.Sample( sGradientTex, In.UV0 ).x;
    emissive = lerp( emissive, cFresnelColor.xyz, fresnel );
    Out.GBuffer3.xyz = emissive * ( cGlowAmount - 1.0f * ( cos( fresnelTime * 7.5f ) + 1 ) / 2.0f );

    float dissolve = tDissolveTex.SampleBias( sDissolveTex, In.UV0, cMIPBias ).x;
    clip( dissolve >= cDissolveAmount ? 1:-1 );
    float dissolveDiff = dissolve - cDissolveAmount;
    if ( dissolveDiff < 0.2f && cDissolveAmount > 0 && cDissolveAmount < 1 )
    {
        float dissolvePower = saturate( dissolveDiff / 0.2f );
        Out.GBuffer3.xyz = cFresnelColor.rgb * cDissolveAmount * dissolvePower * cGlowAmount * 25.0f;
    }

    Out.GBuffer3.xyz *= cGlowFactor;

#if USE_VELOCITY
    float2 screenPos = ( In.CurrPos.xy / In.CurrPos.w ) + cJitterOffset.xy;
    float2 prevScreenPos = ( In.PrevPos.xy / In.PrevPos.w ) + cJitterOffset.zw;
    Out.GBuffer5 = screenPos - prevScreenPos;
#else
    Out.GBuffer5 = 0.0f;
#endif

    return Out;
}
