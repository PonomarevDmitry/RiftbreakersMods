#include "materials/programs/utils.hlsl"
#include "materials/programs/utils_pack.hlsl"

cbuffer FPConstantBuffer : register(b0)
{
    float4      cDissolveColor;
    float       cDissolveSize;
    float       cDissolveAmount;
    float       cGlowAmount;
    float       cGlowFactor;
#if USE_VELOCITY
    float4      cJitterOffset;
#endif
#if USE_REFLECTION_MAP
    float2      cReflectionParams;
    float3      cWorldCameraPos;
#endif
    float       cHealthAmount;
#if USE_HEALTH_OFFSET
    float       cHealthAmountOffset;
#endif
    float       cMIPBias;
#if USE_FLOWFIELD_MAP
    float       cTime;
    float       cFlowPower;
    float       cFlowSpeed;
    float       cFlowPhaseScale;
    float       cFlowNoiseTillingFactor;
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
#if USE_BUILDINGS || USE_EMISSIVE_MAP
Texture2D       tEmissive2Tex;
SamplerState    sEmissive2Tex;
#endif
Texture2D       tGradient1Tex;
SamplerState    sGradient1Tex;
#if USE_BUILDINGS || USE_EMISSIVE_MAP
Texture2D       tGradient2Tex;
SamplerState    sGradient2Tex;
#endif
Texture2D       tDissolveTex;
SamplerState    sDissolveTex;
#if USE_REFLECTION_MAP
Texture2D       tEnvBRDF;
SamplerState    sEnvBRDF;
TextureCube     tReflectionTex;
SamplerState    sReflectionTex;
#endif
#if USE_FLOWFIELD_MAP
Texture2D       tFlowmapTex;
SamplerState    sFlowmapTex;

inline float4 GetDataWithFlowmap( Texture2D t, SamplerState s, float2 coords1, float2 coords2, float power )
{
    float4 x = t.SampleBias( s, coords1, cMIPBias );
    float4 y = t.SampleBias( s, coords2, cMIPBias );
    return lerp( x, y, power );
}

inline float3 GetNormalMapDataWithFlowmap( Texture2D t, SamplerState s, float2 coords1, float2 coords2, float power )
{
    float MipBiasNormal = cMIPBias * 0.5;

    float3 x = texNormal2DBias( t, s, coords1, MipBiasNormal ).xyz;
    float3 y = texNormal2DBias( t, s, coords2, MipBiasNormal ).xyz;
    return lerp( x, y, power );
}

inline void GetFlowFieldData( in float2 coords, out float4 albedo, out float3 normal, out float3 material, out float3 emissive )
{
    float noise = tDissolveTex.SampleLevel( sDissolveTex, coords * cFlowNoiseTillingFactor, 0.0f ).x;    
    float2 flowDir = ( tFlowmapTex.SampleLevel( sFlowmapTex, coords, 0.0f ).xy * 2.0f - 1.0f ) * cFlowPower;

    float offsetPhase = cFlowPhaseScale * noise;
    float time = cTime / ( cFlowSpeed * 2.0 );
    float2 phase = frac( offsetPhase + float2( time, time + 0.5f ) );
    float2 coords0 = ( coords - ( flowDir / 2.0f ) ) + ( phase.x * flowDir.xy ) + 0.5f * flowDir.xy;
    float2 coords1 = ( coords - ( flowDir / 2.0f ) ) + ( phase.y * flowDir.xy ) + 0.5f * flowDir.xy;

    float flowLerp = abs( ( 2.0f * phase.x ) - 1.0f );
    albedo = GetDataWithFlowmap( tAlbedo1Tex, sAlbedo1Tex, coords0, coords1, flowLerp );
    normal = GetNormalMapDataWithFlowmap( tNormal1Tex, sNormal1Tex, coords0, coords1, flowLerp ).xyz;
    material = GetDataWithFlowmap( tPacked1Tex, sPacked1Tex, coords0, coords1, flowLerp ).xyz; 
    emissive = GetDataWithFlowmap( tEmissive1Tex, sEmissive1Tex, coords0, coords1, flowLerp ).xyz; 
}

inline void GetDamageFlowFieldData( in float2 coords, out float4 albedo, out float3 normal, out float3 material )
{
    float noise = tDissolveTex.SampleLevel( sDissolveTex, coords * cFlowNoiseTillingFactor, 0.0f ).x;    
    float2 flowDir = ( tFlowmapTex.SampleLevel( sFlowmapTex, coords, 0.0f ).xy * 2.0f - 1.0f ) * cFlowPower;

    float offsetPhase = cFlowPhaseScale * noise;
    float time = cTime / ( cFlowSpeed * 2.0 );
    float2 phase = frac( offsetPhase + float2( time, time + 0.5f ) );
    float2 coords0 = ( coords - ( flowDir / 2.0f ) ) + ( phase.x * flowDir.xy ) + 0.5f * flowDir.xy;
    float2 coords1 = ( coords - ( flowDir / 2.0f ) ) + ( phase.y * flowDir.xy ) + 0.5f * flowDir.xy;

    float flowLerp = abs( ( 2.0f * phase.x ) - 1.0f );
    albedo = GetDataWithFlowmap( tAlbedo2Tex, sAlbedo2Tex, coords0, coords1, flowLerp );
    normal = GetNormalMapDataWithFlowmap( tNormal2Tex, sNormal2Tex, coords0, coords1, flowLerp );
    material = GetDataWithFlowmap( tPacked2Tex, sPacked2Tex, coords0, coords1, flowLerp ); 
}
#endif

PS_OUTPUT mainFP( VS_OUTPUT In )
{
    PS_OUTPUT Out;

    float MipBiasNormal = cMIPBias * 0.5;

    float dissolve = tDissolveTex.SampleBias( sDissolveTex, In.UV0, cMIPBias).x;

#if USE_FLOWFIELD_MAP
    float4 albedo; float3 material; float3 texNormal; float3 emissive;
    GetFlowFieldData( In.UV0, albedo, texNormal, material, emissive );
#else
    float4 albedo = tAlbedo1Tex.SampleBias( sAlbedo1Tex, In.UV0, cMIPBias).xyzw;
    float3 material = tPacked1Tex.SampleBias( sPacked1Tex, In.UV0, cMIPBias ).xyz;
    float3 texNormal = texNormal2DBias( tNormal1Tex, sNormal1Tex, In.UV0, MipBiasNormal );
    float3 emissive = tEmissive1Tex.Sample( sEmissive1Tex, In.UV0 ).xyz;
#endif

    emissive *= tGradient1Tex.Sample( sGradient1Tex, In.UV0).x  * cGlowFactor  * cGlowAmount;

#if USE_ALPHA_TEST
    clip ( albedo.a > 0.5f ? 1:-1 );
#endif

    float3x3 normalRotation = float3x3( In.Tangent, In.BiNormal, In.Normal );

#if USE_HEALTH_OFFSET
    float healthAmount = saturate( cHealthAmountOffset + cHealthAmount );
#else 
    float healthAmount = cHealthAmount;
#endif
    
    if ( healthAmount != 1.0f )
    {   

#if USE_FLOWFIELD_MAP
        float4 damageAlbedo; float3 damageMaterial; float3 damageNormal;
        GetDamageFlowFieldData( In.UV0, damageAlbedo, damageNormal, damageMaterial );
#else
        float4 damageAlbedo = tAlbedo2Tex.SampleBias( sAlbedo2Tex, In.UV0, cMIPBias).xyzw;
        float3 damageMaterial = tPacked2Tex.SampleBias( sPacked2Tex, In.UV0, cMIPBias ).xyz;
        float3 damageNormal = texNormal2DBias( tNormal2Tex, sNormal2Tex, In.UV0, MipBiasNormal );
#endif

#if USE_BUILDINGS || USE_EMISSIVE_MAP
        float damageGlowFactor = 6.0f;
        float3 damageEmissive = tEmissive2Tex.Sample( sEmissive2Tex, In.UV0 ).xyz * tGradient2Tex.Sample( sGradient2Tex, In.UV0 ).x * damageGlowFactor;
#endif

#if USE_REFLECTION_MAP
        float albedoDiff = ( healthAmount > 0.0f ) ? saturate( 1.0 - healthAmount - dissolve ) : saturate( 0.5 - dissolve );
#else 
        float albedoDiff =  saturate( 1.0 - healthAmount - dissolve );
#endif
        albedo.xyz = lerp( albedo.xyz, damageAlbedo.xyz, albedoDiff );
        material = lerp( material, damageMaterial, albedoDiff );
#if USE_BUILDINGS
        float emissiveDiff = saturate( 0.50 - healthAmount - dissolve );
        emissive = lerp( emissive, damageEmissive, ( emissiveDiff > 0 ) ? 1 : 0 );
#elif USE_EMISSIVE_MAP
        float emissiveDiff = saturate( 1.0f - healthAmount - dissolve );
        emissive = lerp( emissive, damageEmissive, emissiveDiff );
        emissive *= ( healthAmount > 0.0f ) ? 1.0f : 0.0f;
#elif USE_REFLECTION_MAP
        emissive *= ( healthAmount > 0.0f ) ? 1.0f : 0.25f;
#else
        emissive *= min( healthAmount * 2.0f, 1.0f );
#endif
		texNormal = lerp( texNormal, damageNormal, albedoDiff );
    }

    float3 normal = mul( texNormal, normalRotation );

#if USE_REFLECTION_MAP
    float roughness = material.y;
    if ( roughness < cReflectionParams.x )
    {    
        float3 N = normal;
        float3 V = normalize( cWorldCameraPos - In.WorldPos.xyz );
        float NdotV = abs( dot( N, V ) ) + 0.001;
        float occlusion = material.x;
        float metalness = material.z;
        float smoothness = 1.0f - ( roughness * roughness * roughness * roughness );
        float2 specularBRDF = tEnvBRDF.SampleLevel( sEnvBRDF, float2( NdotV, smoothness ), 0.0f ).xy;
        float3 reflectRay = normalize( reflect( -V, N ) );
        float mipLevel = roughness * 8.0f;
        float3 specularLight = tReflectionTex.SampleLevel( sReflectionTex, reflectRay, mipLevel ).xyz;
        float3 specularColor = lerp( 0.04f, albedo.xyz, metalness );
        float3 specular = specularLight * ( specularColor * specularBRDF.x + saturate( 50.0 * specularColor.g ) * specularBRDF.y ) * cReflectionParams.y * occlusion;
        specular *= ( cHealthAmount > 0.0f ) ? 1.0f : 0.25f;
        emissive.xyz += specular;
    }
#endif

    Out.GBuffer1.xyz = encodeNormal( normal );
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

#if USE_VELOCITY
    float2 screenPos = ( In.CurrPos.xy / In.CurrPos.w ) + cJitterOffset.xy;
    float2 prevScreenPos = ( In.PrevPos.xy / In.PrevPos.w ) + cJitterOffset.zw;
    Out.GBuffer5 = screenPos - prevScreenPos;
#else
    Out.GBuffer5 = 0.0f;
#endif

    return Out;
}
