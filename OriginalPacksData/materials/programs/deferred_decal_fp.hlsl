#include "materials/programs/utils.hlsl"
#include "materials/programs/utils_pack.hlsl"

cbuffer FPConstantBuffer : register(b0)
{
#if USE_PROJECTED_POS
    matrix      cInvProjMatrix;
    matrix      cInvWorldViewMatrix;
#endif
#if USE_TEXTURE_ATLAS
    float4      cTextureAtlas;
#endif
#if USE_VELOCITY
    float4      cJitterOffset;
#endif
    float       cGlowAmount;
    float       cGlowFactor;
	float       cDissolveAmount;
    float       cMIPBias;
};

struct VS_OUTPUT
{
    float4      Position      : SV_POSITION;
    float4      ProjPos       : TEXCOORD0;
    float3      Normal        : TEXCOORD1;
    float3      Tangent       : TEXCOORD2;
    float3      BiNormal      : TEXCOORD3;
    float2      TexCoord      : TEXCOORD4;
#if USE_VELOCITY
    float4      PrevPos       : TEXCOORD5;
#endif
};

struct PS_OUTPUT
{
    float4      GBuffer0      : SV_TARGET0; // Albedo (xyz), Opacity (w)
    float4      GBuffer1      : SV_TARGET1; // Normal (xyz), Opacity (w)
    float4      GBuffer2      : SV_TARGET2; // Roughness (x), Metalness (y), Occlusion (z)
    float4      GBuffer3      : SV_TARGET3; // Emissive (xyz)
    float4      GBuffer4      : SV_TARGET4; // SubsurfaceScattering (xyz)
    float4      GBuffer5      : SV_TARGET5; // Velocity (xy)
};

Texture2D       tAlbedoTex;
SamplerState    sAlbedoTex;
Texture2D       tNormalTex;
SamplerState    sNormalTex;
Texture2D       tPackedTex;
SamplerState    sPackedTex;
Texture2D       tEmissiveTex;
SamplerState    sEmissiveTex;

#if USE_PROJECTED_POS
Texture2D       tDepthTex;
SamplerState    sDepthTex;
#endif

#if USE_PROJECTED_POS
float4 getViewPosFromDepth( float2 screenPos )
{
    float x = screenPos.x * 2.0f - 1.0f;
    float y = (1.0f - screenPos.y) * 2.0f - 1.0f;
    float z = tDepthTex.Sample( sDepthTex, screenPos.xy ).r;

    float4 projPos = float4( x, y, z, 1.0f );
    float4 viewPos = mul( cInvProjMatrix, projPos );
    viewPos = viewPos.xyzw / viewPos.w;
    return viewPos;
}
#endif

PS_OUTPUT mainFP( VS_OUTPUT In )
{
    PS_OUTPUT Out;

    float MipBiasNormal = cMIPBias * 0.5;

#if USE_PROJECTED_POS
    float2 screenCoord = In.ProjPos.xy / In.ProjPos.w;
	screenCoord = screenCoord * float2( 0.5f, -0.5f ) + float2( 0.5f, 0.5f );

	float4 viewPos = getViewPosFromDepth( screenCoord.xy );
	float4 localPos = mul( cInvWorldViewMatrix, viewPos );

	clip( 0.5f - abs( localPos.xyz ) );
	float2 texCoord = localPos.xz + 0.5f;
#else
    float2 texCoord = In.TexCoord;
#endif

#if USE_TEXTURE_ATLAS
	texCoord = cTextureAtlas.xy + ( texCoord * cTextureAtlas.zw );
	float2 dx = ddx( texCoord * cTextureAtlas.zw );
    float2 dy = ddy( texCoord * cTextureAtlas.zw );
#endif

#if USE_TEXTURE_ATLAS
	float4 albedo = tAlbedoTex.SampleGrad( sAlbedoTex, texCoord, dx, dy );
#else
	float4 albedo = tAlbedoTex.SampleBias( sAlbedoTex, texCoord, cMIPBias);
#endif

    albedo.w *= ( 1.0f - cDissolveAmount );
    
    Out.GBuffer0.xyzw = albedo.xyzw;

#if USE_TEXTURE_ATLAS
    float3 texNormal = texNormal2D( tNormalTex, sNormalTex, texCoord, dx, dy );
#else
    float3 texNormal = texNormal2DBias( tNormalTex, sNormalTex, texCoord, MipBiasNormal).xyz;
#endif

    float3x3 normalRotation = float3x3( In.Tangent, In.BiNormal, In.Normal );
    Out.GBuffer1.xyz = encodeNormal( mul( texNormal, normalRotation ) );
    Out.GBuffer1.w = albedo.w;

#if USE_TEXTURE_ATLAS
    float3 material = tPackedTex.SampleGrad( sPackedTex, texCoord, dx, dy ).xyz;
#else
    float3 material = tPackedTex.SampleBias( sPackedTex, texCoord, cMIPBias).xyz;
#endif
    Out.GBuffer2 = float4( material, albedo.w );

#if USE_TEXTURE_ATLAS
    float3 emissive = tEmissiveTex.SampleGrad( sEmissiveTex, texCoord, dx, dy ).rgb;
#else
    float3 emissive = tEmissiveTex.SampleBias( sEmissiveTex, texCoord, cMIPBias).rgb;
#endif
    Out.GBuffer3 = float4( emissive * cGlowAmount * cGlowFactor, albedo.w );
    Out.GBuffer4 = 0.0f;

#if USE_VELOCITY
    float2 screenPos = ( In.ProjPos.xy / In.ProjPos.w ) + cJitterOffset.xy;
    float2 prevScreenPos = ( In.PrevPos.xy / In.PrevPos.w ) + cJitterOffset.zw;
    Out.GBuffer5 = float4( screenPos - prevScreenPos, 0.0f, albedo.w );
#else
    Out.GBuffer5 = 0.0f;
#endif
    
    return Out;
}
