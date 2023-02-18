#include "materials/programs/utils.hlsl"
#include "materials/programs/pack_ops.hlsl"

cbuffer FPConstantBuffer : register(b0)
{
    float4      cDissolveColor;
    float       cDissolveSize;
    float       cDissolveAmount;
    float       cGlowAmount;
    float       cGlowFactor;
    float       cHealthAmount;
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
Texture2D       tAlbedo2Tex;
SamplerState    sAlbedo2Tex;
Texture2D       tNormal1Tex;
SamplerState    sNormal1Tex;
Texture2D       tNormal2Tex;
SamplerState    sNormal2Tex;
Texture2D       tPacked1Tex;
SamplerState    sPacked1Tex;
Texture2D       tPacked2Tex;
SamplerState    sPacked2Tex;
Texture2D       tEmissive1Tex;
SamplerState    sEmissive1Tex;
#if USE_BUILDINGS
Texture2D       tEmissive2Tex;
SamplerState    sEmissive2Tex;
#endif
Texture2D       tGradient1Tex;
SamplerState    sGradient1Tex;
#if USE_BUILDINGS
Texture2D       tGradient2Tex;
SamplerState    sGradient2Tex;
#endif
Texture2D       tDissolveTex;
SamplerState    sDissolveTex;

PS_OUTPUT mainFP( VS_OUTPUT In )
{
    PS_OUTPUT Out;


    float MipBiasNormal = cMIPBias * 0.5;

    float dissolve = tDissolveTex.SampleBias( sDissolveTex, In.UV0, cMIPBias).x;
    float4 albedo = tAlbedo1Tex.SampleBias( sAlbedo1Tex, In.UV0, cMIPBias).xyzw;
    float3 material = tPacked1Tex.SampleBias( sPacked1Tex, In.UV0, cMIPBias ).xyz;
    float3 emissive = tEmissive1Tex.Sample( sEmissive1Tex, In.UV0 ).xyz * tGradient1Tex.Sample( sGradient1Tex, In.UV0).x  * cGlowFactor  * cGlowAmount;
	float3 texNormal = texNormal2DBias( tNormal1Tex, sNormal1Tex, In.UV0, MipBiasNormal );

#if USE_ALPHA_TEST
    clip ( albedo.a > 0.5f ? 1:-1 );
#endif

    if ( cHealthAmount != 1.0f )
    {   
        float albedoDiff =  saturate( 1.0 - cHealthAmount - dissolve );
        albedo.xyz = lerp( albedo.xyz, tAlbedo2Tex.SampleBias( sAlbedo2Tex, In.UV0, cMIPBias).xyz, albedoDiff );
        material = lerp( material, tPacked2Tex.SampleBias( sPacked2Tex, In.UV0, cMIPBias).xyz, albedoDiff );
#if USE_BUILDINGS
        float emissiveDiff =  saturate( 0.50 - cHealthAmount - dissolve );
        emissive = lerp( emissive, tEmissive2Tex.Sample( sEmissive2Tex, In.UV0 ).xyz * tGradient2Tex.Sample( sGradient2Tex, In.UV0).x * 6, ( emissiveDiff > 0 ) ? 1 : 0 );
#else
        emissive *= min( cHealthAmount * 2.0f, 1.0f );
#endif
		texNormal = lerp( texNormal, texNormal2D( tNormal2Tex, sNormal2Tex, In.UV0).xyz, albedoDiff );
    }

    float3x3 normalRotation = float3x3( In.Tangent, In.BiNormal, In.Normal );
    Out.GBuffer1.xyz = encodeNormal( mul( texNormal, normalRotation ) );

    Out.GBuffer0 = float4( albedo.xyz, 1.0f );
    Out.GBuffer2 = float4( material, 1.0f );
    Out.GBuffer3 = float4( emissive, 1.0f );
    Out.GBuffer4 = 0.0f;

    clip( dissolve >= cDissolveAmount ? 1:-1 );
    float dissolveDiff = dissolve - cDissolveAmount;
    if ( dissolveDiff < cDissolveSize && cDissolveAmount > 0 && cDissolveAmount < 1 )
    {
        float dissolvePower = saturate( dissolveDiff / cDissolveSize );
        float3 dissolveColor = cDissolveColor.rgb;
        dissolveColor += cDissolveColor.a * dissolvePower * dissolvePower;
        dissolveColor *= cDissolveAmount * dissolvePower;
        Out.GBuffer3.xyz = dissolveColor;
    }

    return Out;
}
