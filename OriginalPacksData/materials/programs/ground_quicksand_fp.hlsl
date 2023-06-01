#include "materials/programs/utils.hlsl"
#include "materials/programs/utils_pack.hlsl"

cbuffer PSConstantBuffer : register(b0)
{
#if USE_VELOCITY
    float4      cJitterOffset;
#endif
    float       cGlowAmount;
    float       cAlpha;
    float       cFlowSpeed;
    float       cTime;
    float       cMIPBias;
}

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
    float       Alpha         : TEXCOORD7;
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
Texture2D       tFlowmapTex;
SamplerState    sFlowmapTex;

PS_OUTPUT mainFP( VS_OUTPUT In )
{
    PS_OUTPUT Out;

    float blendSpeed = clamp( ( In.Alpha - 0.2f ) / 1.8f, 0.0, 1.0 );
    float3 flowDir = tFlowmapTex.Sample( sFlowmapTex, In.UV0 ) * 2.0f - 1.0f;
    flowDir *= cFlowSpeed * blendSpeed;

    float phase0 = frac( cTime * 0.5f + 0.5f );
    float phase1 = frac( cTime * 0.5f + 1.0f );

    float2 uv0 = In.UV0 + flowDir.xy * phase0;
    float2 uv1 = In.UV0 + flowDir.xy * phase1;

    float flowLerp = abs( ( 0.5f - phase0 ) / 0.5f );

    float4 albedo0 = tAlbedoTex.SampleBias( sAlbedoTex, uv0, cMIPBias );
    float4 albedo1 = tAlbedoTex.SampleBias( sAlbedoTex, uv1, cMIPBias );
    float4 albedo = lerp( albedo0, albedo1, flowLerp );

    float alpha = albedo.w;
    alpha *= clamp( In.Alpha - 0.2f, 0.0, 1.0 ) * cAlpha;

    Out.GBuffer0.xyz = albedo.xyz;
    Out.GBuffer0.w = alpha;

    float3 packed0 = tPackedTex.SampleBias( sPackedTex, uv0, cMIPBias ).xyz;
    float3 packed1 = tPackedTex.SampleBias( sPackedTex, uv1, cMIPBias ).xyz;
	
    Out.GBuffer2.xyz = lerp( packed0, packed1, flowLerp );
    Out.GBuffer2.w = alpha;

    float MipBiasNormal = cMIPBias * 0.5;

#if USE_FLOW_NORMAL
    float3 normal0 = texNormal2DBias( tNormalTex, sNormalTex, uv0, MipBiasNormal );
    float3 normal1 = texNormal2DBias( tNormalTex, sNormalTex, uv1, MipBiasNormal );
    float3 normal = lerp( normal0, normal1, flowLerp );
#else
    float3 normal = texNormal2DBias( tNormalTex, sNormalTex, In.UV0, MipBiasNormal );
#endif

    float3x3 normalRotation = float3x3( In.Tangent, In.BiNormal, In.Normal );
    Out.GBuffer1.xyz = encodeNormal( mul( normal, normalRotation ).xyz );
    Out.GBuffer1.w = alpha;

    float3 emissive0 = tEmissiveTex.Sample( sEmissiveTex, uv0 ).xyz;
    float3 emissive1 = tEmissiveTex.Sample( sEmissiveTex, uv1 ).xyz;
    float3 emissive = lerp( emissive0.xyz, emissive1.xyz, flowLerp );

    float gradient0 = tGradientTex.Sample( sGradientTex, uv0 ).x;
    float gradient1  = tGradientTex.Sample( sGradientTex, uv1 ).x;
    float gradient = lerp( gradient0, gradient1, flowLerp );

    Out.GBuffer3.xyz = emissive.xyz * cGlowAmount * gradient;
    Out.GBuffer3.w = alpha;

    Out.GBuffer4 = 0.0f;
    Out.GBuffer4.w = alpha;

#if USE_VELOCITY
    float2 screenPos = ( In.CurrPos.xy / In.CurrPos.w ) + cJitterOffset.xy;
    float2 prevScreenPos = ( In.PrevPos.xy / In.PrevPos.w ) + cJitterOffset.zw;
    Out.GBuffer5 = screenPos - prevScreenPos;
#else
    Out.GBuffer5 = 0.0f;
#endif

    return Out;
}
