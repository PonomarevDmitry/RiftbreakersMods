#include "materials/programs/utils.hlsl"
#include "materials/programs/pack_ops.hlsl"

cbuffer FPConstantBuffer : register(b0)
{   
    float       cFresnelOffset;
    float       cFresnelPower;
    float       cFresnelBias;  
    float3      cWorldCameraPos;
    float       cGlowAmount;
    float       cGlowFactor;
    float       cFlowSpeed;
    float       cFlowScale;
    float       cTime;
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
#if USE_ALPHA
    float       Alpha         : TEXCOORD5;
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

Texture2D       tAlbedo1Tex;
SamplerState    sAlbedo1Tex;
Texture2D       tNormal1Tex;
SamplerState    sNormal1Tex;
Texture2D       tPacked1Tex;
SamplerState    sPacked1Tex;
Texture2D       tEmissive1Tex;
SamplerState    sEmissive1Tex;

Texture2D       tAlbedo2Tex;
SamplerState    sAlbedo2Tex;
Texture2D       tNormal2Tex;
SamplerState    sNormal2Tex;
Texture2D       tPacked2Tex;
SamplerState    sPacked2Tex;
Texture2D       tEmissive2Tex;
SamplerState    sEmissive2Tex;

Texture2D       tNoiseTex;
SamplerState    sNoiseTex;
Texture2D       tGradientTex;
SamplerState    sGradientTex;

Texture2D       tFlowmapTex;
SamplerState    sFlowmapTex;

#if TERRAIN_BLEND == 1
Texture2D       tAlbedo3Tex;
SamplerState    sAlbedo3Tex;
Texture2D       tNormal3Tex;
SamplerState    sNormal3Tex;
Texture2D       tPacked3Tex;
SamplerState    sPacked3Tex;
Texture2D       tEmissive3Tex;
SamplerState    sEmissive3Tex;
#endif

PS_OUTPUT mainFP( VS_OUTPUT In )
{
    PS_OUTPUT Out;

    float3 eyeVec = normalize( In.WorldPos - cWorldCameraPos );
    float dotProduct = clamp( dot( eyeVec, In.Normal ), -1.0f, 1.0f );
    float fresnelPower = ( dotProduct + cFresnelOffset ) / cFresnelPower;
    float fresnel = saturate( ( fresnelPower * fresnelPower ) + cFresnelBias );

    float flowSpeed = cFlowSpeed;
#if USE_ALPHA
    float alpha = clamp( In.Alpha, 0.0, 1.0 );
    float blendSpeed = clamp( In.Alpha / 2.0f, 0.0, 1.0 );
    flowSpeed *= blendSpeed * blendSpeed;
#   if USE_GRADIENT
    flowSpeed *= tGradientTex.Sample( sGradientTex, In.UV0 / ( cFlowScale * 10.0f ) ).x;
#   endif
#else
    float alpha = 1.0f;
#endif

    float2 uv = In.UV0 / 10.0f;

    float3 flowDir = tFlowmapTex.Sample( sFlowmapTex, In.UV0 / ( cFlowScale * 10.0f ) ) * 2.0f - 1.0f;
    flowDir *= flowSpeed;

    float phase0 = frac( cTime * 0.5f + 0.5f );
    float phase1 = frac( cTime * 0.5f + 1.0f );

    float2 uv0 = uv + flowDir.xy * phase0;
    float2 uv1 = uv + flowDir.xy * phase1;

    float flowLerp = abs( ( 0.5f - phase0 ) / 0.5f );

    float MipBiasNormal = cMIPBias * 0.5;

    float n1 = tNoiseTex.Sample( sNoiseTex, uv + cTime * 0.5 * 0.005 ).x;
    float n2 = tNoiseTex.Sample( sNoiseTex, uv - cTime * 1.0 * 0.005 ).x;
    float g = tGradientTex.Sample( sGradientTex, uv * 1.5 ).x;
    float blendPower = max( saturate( lerp( n1, n2 + 1, g  ) ), pow( 1.0 - alpha, 4 ) ); 

    float3 albedo00 = tAlbedo1Tex.SampleBias( sAlbedo1Tex, uv0, cMIPBias ).xyz;
    float3 albedo01 = tAlbedo2Tex.SampleBias( sAlbedo2Tex, uv0, cMIPBias ).xyz;
    float3 albedo0 = lerp( albedo00.xyz, albedo01.xyz, fresnel * blendPower );
    float3 albedo10 = tAlbedo1Tex.SampleBias( sAlbedo1Tex, uv1, cMIPBias ).xyz;
    float3 albedo11 = tAlbedo2Tex.SampleBias( sAlbedo2Tex, uv1, cMIPBias ).xyz;
    float3 albedo1 = lerp( albedo10.xyz, albedo11.xyz, fresnel * blendPower  );
    float3 albedo = lerp( albedo0, albedo1, flowLerp );

#if TERRAIN_BLEND == 1
    float terrainBlendPower = 1.0 - pow( alpha, 2 );

    float3 albedo3 = tAlbedo3Tex.SampleBias( sAlbedo3Tex, uv0, cMIPBias ).xyz;
    albedo = lerp( albedo, albedo3, terrainBlendPower );
#endif

    Out.GBuffer0 = float4( albedo, alpha );

    float3 texNormal00 = texNormal2DBias( tNormal1Tex, sNormal1Tex, uv0, MipBiasNormal );
    float3 texNormal01 = texNormal2DBias( tNormal2Tex, sNormal2Tex, uv0, MipBiasNormal );
    float3 normal0 = lerp( texNormal00, texNormal01, fresnel * blendPower  );
    float3 texNormal10 = texNormal2DBias( tNormal1Tex, sNormal1Tex, uv1, MipBiasNormal );
    float3 texNormal11 = texNormal2DBias( tNormal2Tex, sNormal2Tex, uv1, MipBiasNormal );
    float3 normal1 = lerp( texNormal10, texNormal11, fresnel * blendPower  );
    float3 normal = lerp( normal0, normal1, flowLerp );

#if TERRAIN_BLEND == 1
    float3 normal3 = texNormal2DBias(tNormal3Tex, sNormal3Tex, uv0, MipBiasNormal ).xyz;
    normal = lerp( normal, normal3, terrainBlendPower );
#endif

    float3x3 normalRotation = float3x3( In.Tangent, In.BiNormal, In.Normal );
    Out.GBuffer1 = float4( encodeNormal( mul( normal, normalRotation ).xyz ), alpha );

    float3 packed00 = tPacked1Tex.SampleBias( sPacked1Tex, uv0, cMIPBias ).xyz;
    float3 packed01 = tPacked2Tex.SampleBias( sPacked2Tex, uv0, cMIPBias ).xyz;
    float3 packed0 = lerp( packed00.xyz, packed01.xyz, fresnel  );
    float3 packed10 = tPacked1Tex.SampleBias( sPacked1Tex, uv1, cMIPBias ).xyz;
    float3 packed11 = tPacked2Tex.SampleBias( sPacked2Tex, uv1, cMIPBias ).xyz;
    float3 packed1 = lerp( packed10.xyz, packed11.xyz, fresnel  );
    float3 packedFinal = lerp( packed0, packed1, flowLerp );

#if TERRAIN_BLEND == 1
    float3 packed3 = tPacked3Tex.SampleBias( sPacked3Tex, uv0, cMIPBias ).xyz;
    packedFinal = lerp(packedFinal, packed3, terrainBlendPower );
#endif

	Out.GBuffer2 = float4(packedFinal, alpha );

    if ( cGlowAmount > 0.0 )
    {
        float3 emissive00 = tEmissive1Tex.Sample( sEmissive1Tex, uv0 ).xyz;
        float3 emissive01 = tEmissive2Tex.Sample( sEmissive2Tex, uv0 ).xyz;
        float3 emissive0 = lerp( emissive00, emissive01, blendPower );
        float3 emissive10 = tEmissive1Tex.Sample( sEmissive1Tex, uv1 ).xyz;
        float3 emissive11 = tEmissive2Tex.Sample( sEmissive2Tex, uv1 ).xyz;
        float3 emissive1 = lerp( emissive10, emissive11, blendPower );
        float3 emissive = lerp( emissive0.xyz, emissive1.xyz, flowLerp );

    #if TERRAIN_BLEND == 1
        float3 emissive3 = tEmissive3Tex.Sample( sEmissive3Tex, uv0 ).xyz;
        emissive = lerp( emissive, emissive3, terrainBlendPower );
    #endif

        Out.GBuffer3 = float4( emissive * cGlowAmount * cGlowFactor, alpha );
    }
    else
    {
        Out.GBuffer3 = float4( 0.0f, 0.0f, 0.0f, 1.0f );
    }

    //Out.GBuffer3.x = fresnel;

    Out.GBuffer4 = 0.0f;

    return Out;
}
