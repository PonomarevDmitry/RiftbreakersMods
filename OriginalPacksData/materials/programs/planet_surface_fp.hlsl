#include "materials/programs/utils.hlsl"
#include "materials/programs/utils_pack.hlsl"

cbuffer FPConstantBuffer : register(b0)
{    
    float4      cLightDirection;
#if USE_VELOCITY
    float4      cJitterOffset;
#endif
    float       cGlowAmount;
    float       cGlowFactor;
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

PS_OUTPUT mainFP( VS_OUTPUT In )
{
    PS_OUTPUT Out;

    float4 albedo = tAlbedoTex.Sample( sAlbedoTex, In.UV0 ).xyzw;
    clip ( albedo.a > 0.5f ? 1:-1 );

    Out.GBuffer0.xyzw = float4( albedo.xyz, 1.0f );
    Out.GBuffer2.xyzw = tPackedTex.Sample( sPackedTex, In.UV0 );

    float3 texNormal = texNormal2D( tNormalTex, sNormalTex, In.UV0 );
    float3x3 normalRotation = float3x3( In.Tangent, In.BiNormal, In.Normal );
    float3 normal = mul( texNormal, normalRotation );
    Out.GBuffer1.xyz = encodeNormal( normal );

    float3 emissive = tEmissiveTex.Sample( sEmissiveTex, In.UV0 ).xyz * max( 0.15, tGradientTex.Sample( sGradientTex, In.UV0 * 10 ).x );
    emissive *= cGlowAmount * cGlowFactor;

    float night = saturate( 0.5 + dot( In.Normal, cLightDirection.xyz ) );
    Out.GBuffer3 = float4( emissive.xyz, 1.0f ) * saturate( night * night );
    Out.GBuffer4 = 0.0f;

#if USE_VELOCITY
    float2 screenPos = ( In.CurrPos.xy / In.CurrPos.w ) + cJitterOffset.xy;
    float2 prevScreenPos = ( In.PrevPos.xy / In.PrevPos.w ) + cJitterOffset.zw;
    Out.GBuffer5 = screenPos - prevScreenPos;
#else
    Out.GBuffer5 = 0.0f;
#endif

    return Out;
}
