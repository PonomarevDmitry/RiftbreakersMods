#include "materials/programs/utils.hlsl"
#include "materials/programs/utils_pack.hlsl"

cbuffer FPConstantBuffer : register(b0)
{
    float4      cDissolveColor;
    float       cDissolveAmount;
    float       cDissolveSize;
    float       cGlowAmount;
    float       cGlowFactor;
#if USE_VELOCITY
    float4      cJitterOffset;
#endif
    float       cHealthAmount;
    float       cMaxHeight;
    float       cTime;
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
    float3      LocalPos      : TEXCOORD7;
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

    float4 albedo = tAlbedoTex.Sample( sAlbedoTex, In.UV0 ).xyzw;
    float3 texNormal = texNormal2D( tNormalTex, sNormalTex, In.UV0 );
    float3 emissive = tEmissiveTex.Sample( sEmissiveTex, In.UV0 ).xyz * tGradientTex.Sample( sGradientTex, In.UV0 ).x;

    float3 aabb = float3( 20, cMaxHeight, 20 );
    float2 localPos = In.LocalPos.xz + cTime;
    float dissolve = tDissolveTex.Sample( sDissolveTex, float2( localPos.x / aabb.x, localPos.y / aabb.z ) ).x;

    if ( cHealthAmount != 1.0f )
    {    
        float albedoDiff =  saturate( 1.0 - cHealthAmount );
        albedo.xyz = lerp( albedo.xyz, float3(0.1, 0.1, 0.1), albedoDiff );
        emissive *= min( cHealthAmount * 2.0f, 1.0f );
    }
    
    float3x3 normalRotation = float3x3( In.Tangent, In.BiNormal, In.Normal );
    Out.GBuffer1.xyz = encodeNormal( mul( texNormal, normalRotation ).xyz );
    Out.GBuffer3.xyz = emissive * cGlowAmount * cGlowFactor;
    Out.GBuffer0 = float4( albedo.xyz, 1.0f );
    Out.GBuffer2.xyz = tPackedTex.Sample( sPackedTex, In.UV0 ).xyz;
    Out.GBuffer4 = 0.0f;

#if USE_VELOCITY
    float2 screenPos = ( In.CurrPos.xy / In.CurrPos.w ) + cJitterOffset.xy;
    float2 prevScreenPos = ( In.PrevPos.xy / In.PrevPos.w ) + cJitterOffset.zw;
    Out.GBuffer5 = screenPos - prevScreenPos;
#else
    Out.GBuffer5 = 0.0f;
#endif

    float height = saturate( ( 1.0f - In.LocalPos.y / aabb.y ) - 0.2 * dissolve );

    float dissolveAmount = cDissolveAmount;//* 0.00001 + 0.8;
    float dissolveSize = cDissolveSize;// * 0.00001 + 0.02;

    clip( height >= ( dissolveAmount ) ? 1:-1 );

    float dissolveDiff = height - dissolveAmount;
    if ( dissolveDiff < dissolveSize && dissolveAmount > 0 && dissolveAmount < 1 )
    {
        float3 dissolveColor = cDissolveColor.rgb * 0.5 * (0.8 + 0.2 * dissolve);
        dissolveColor *= dissolveAmount;
        Out.GBuffer3.xyz = dissolveColor;
    }

    return Out;
}
