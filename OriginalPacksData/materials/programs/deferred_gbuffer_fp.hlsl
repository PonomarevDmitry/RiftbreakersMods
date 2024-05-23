#include "materials/programs/utils.hlsl"
#include "materials/programs/utils_pack.hlsl"

cbuffer FPConstantBuffer : register(b0)
{
#if USE_DISSOLVE_MAP  
    float4      cDissolveColor;
    float       cDissolveAmount;
    float       cDissolveSize;
#endif
#if USE_REFLECTION_MAP
    float2      cReflectionParams;
#endif
    float       cGlowAmount;
    float       cGlowFactor;
    float       cGradientUvScale;
#if USE_REFLECTION_MAP
    float3      cWorldCameraPos;
#endif
    float       cMIPBias;
#if USE_VELOCITY
    float4      cJitterOffset;
#endif
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
#if USE_DISSOLVE_MAP
Texture2D       tDissolveTex;
SamplerState    sDissolveTex;
#endif
#if USE_REFLECTION_MAP
Texture2D       tEnvBRDF;
SamplerState    sEnvBRDF;
TextureCube     tReflectionTex;
SamplerState    sReflectionTex;
#endif
#if USE_SUBSURFACE_MAP
Texture2D       tSubSurfaceTex;
SamplerState    sSubSurfaceTex;
#endif
#if USE_MIPMAP_CHECKER
Texture2D       tMipMapCheckerTex;
SamplerState    sMipMapCheckerTex;
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
    float3 x = texNormal2D( t, s, coords1 ).xyz;
    float3 y = texNormal2D( t, s, coords2 ).xyz;
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
    albedo = GetDataWithFlowmap( tAlbedoTex, sAlbedoTex, coords0, coords1, flowLerp );
    normal = GetNormalMapDataWithFlowmap( tNormalTex, sNormalTex, coords0, coords1, flowLerp );
    material = GetDataWithFlowmap( tPackedTex, sPackedTex, coords0, coords1, flowLerp ); 
    emissive = GetDataWithFlowmap( tEmissiveTex, sEmissiveTex, coords0, coords1, flowLerp ); 
}
#endif 

PS_OUTPUT mainFP( VS_OUTPUT In )
{
    PS_OUTPUT Out;

#if USE_FLOWFIELD_MAP
    float4 albedo; float3 material; float3 N; float3 emissive;
    GetFlowFieldData( In.UV0, albedo, N, material, emissive );
#else
    float4 albedo = tAlbedoTex.SampleBias( sAlbedoTex, In.UV0, cMIPBias).xyzw;
    float3 material = tPackedTex.SampleBias( sPackedTex, In.UV0, cMIPBias ).xyz;
    float3 N = texNormal2D( tNormalTex, sNormalTex, In.UV0 );
    float3 emissive = tEmissiveTex.Sample( sEmissiveTex, In.UV0 ).xyz;
#endif

#if USE_MIPMAP_CHECKER
    float lod = max( 0.0, tAlbedoTex.CalculateLevelOfDetail(sAlbedoTex,In.UV0) + cMIPBias );
    float4 mipmapChecker = tMipMapCheckerTex.SampleLevel( sMipMapCheckerTex, In.UV0, lod).xyzw;
    albedo.xyz = lerp( albedo.xyz, mipmapChecker.rgb, mipmapChecker.a );
#endif

#if USE_ALPHA_TEST
    clip ( albedo.a > 0.5f ? 1:-1 );
#endif

    Out.GBuffer0.xyzw = float4( albedo.xyz, 1.0f );
    Out.GBuffer2.xyzw = float4( material, 1.0f );

    N = mul( N, float3x3( In.Tangent, In.BiNormal, In.Normal ) );
    Out.GBuffer1.xyz = float4( encodeNormal( N ), 1.0f );

    emissive *= tGradientTex.SampleBias( sGradientTex, In.UV0 * cGradientUvScale, cMIPBias).x * cGlowAmount * cGlowFactor;

#if USE_REFLECTION_MAP  
    float roughness = Out.GBuffer2.y;
    if ( roughness < cReflectionParams.x )
    {    
        float3 V = normalize( cWorldCameraPos - In.WorldPos.xyz );
        float NdotV = abs( dot( N, V ) ) + 0.001;
        float occlusion = Out.GBuffer2.x;
        float metalness = Out.GBuffer2.z;
        float smoothness = 1.0f - ( roughness * roughness * roughness * roughness );
        float2 specularBRDF = tEnvBRDF.SampleLevel( sEnvBRDF, float2( NdotV, smoothness ), 0.0f ).xy;
        float3 reflectRay = normalize( reflect( -V, N ) );
        float mipLevel = roughness * 8.0f;
        float3 specularLight = tReflectionTex.SampleLevel( sReflectionTex, reflectRay, mipLevel ).xyz;
        float3 specularColor = lerp( 0.04f, albedo.xyz, metalness );
        float3 specular = specularLight * ( specularColor * specularBRDF.x + saturate( 50.0 * specularColor.g ) * specularBRDF.y ) * cReflectionParams.y * occlusion;
        emissive.xyz += specular;
    }
#endif

#if USE_DISSOLVE_MAP
    float dissolveAmount = saturate( cDissolveAmount );
    if ( dissolveAmount > 0.0f )
    {
        float dissolve = tDissolveTex.SampleBias( sDissolveTex, In.UV0, cMIPBias).x;
        clip( dissolve >= dissolveAmount ? 1:-1 );
        float dissolveDiff = dissolve - dissolveAmount;
        if ( dissolveDiff < cDissolveSize && dissolveAmount > 0 && dissolveAmount < 1 )
        {
            float dissolvePower = saturate( dissolveDiff / cDissolveSize );
            float3 dissolveColor = cDissolveColor.rgb;
            dissolveColor += cDissolveColor.a * dissolvePower * dissolvePower;
            dissolveColor *= dissolveAmount * dissolvePower;
            emissive.xyz = dissolveColor;
        }
    }
#endif

    Out.GBuffer3 = float4( emissive.xyz, 1.0f );

#if USE_SUBSURFACE_MAP
    Out.GBuffer4 = float4( tSubSurfaceTex.Sample( sSubSurfaceTex, In.UV0.xy ).xyz, 1.0 );
#else
    Out.GBuffer4 = 0.0f;
#endif

#if USE_VELOCITY
    float2 screenPos = ( In.CurrPos.xy / In.CurrPos.w ) + cJitterOffset.xy;
    float2 prevScreenPos = ( In.PrevPos.xy / In.PrevPos.w ) + cJitterOffset.zw;
    Out.GBuffer5 = screenPos - prevScreenPos;
#else
    Out.GBuffer5 = 0.0f;
#endif

    return Out;
}
