cbuffer FPConstantBuffer : register(b0)
{     
    matrix                  cInvViewProjMatrix;
    float4                  cJitterOffset;
    float                   cMIPBias;
    float                   cTime;
    float                   cFlowSpeed;
    float                   cFlowPower;
    float                   cFlowPhaseScale;
    float                   cTilingFactor;
    float                   cFlowNoiseTillingFactor;
    float                   cWaterFadeDepth;
    float                   cFoamEdgePower;
    float                   cFoamEdgeGlowAmount;
    float                   cFoamGlowAmount;
};

struct VS_OUTPUT
{
    float4                  Position      : SV_POSITION;
    float2                  UV0           : TEXCOORD0;
    float3                  Normal        : TEXCOORD1;
    float3                  Tangent       : TEXCOORD2;
    float3                  BiNormal      : TEXCOORD3;
    float3                  WorldPos      : TEXCOORD4;
#if USE_VELOCITY
    float4                  CurrPos       : TEXCOORD5;
    float4                  PrevPos       : TEXCOORD6;
#endif
#if USE_LOCAL_POS
    float3                  LocalPos      : TEXCOORD7;
#endif
};

struct PS_OUTPUT
{
    float4                  GBuffer0      : SV_TARGET0; // Albedo (xyz), 
    float4                  GBuffer1      : SV_TARGET1; // World Space Normal (xyz)
    float4                  GBuffer2      : SV_TARGET2; // Occlusion (x), Roughness (y), Metalness (z)
    float4                  GBuffer3      : SV_TARGET3; // Emissive (xyz)
    float4                  GBuffer4      : SV_TARGET4; // SubsurfaceScattering (xyz)
    float2                  GBuffer5      : SV_TARGET5; // Velocity (xy)
};

Texture2D                   tDepthTex;
SamplerState                sDepthTex;

Texture2D                   tFoamAlbedoTex;
SamplerState                sFoamAlbedoTex;
Texture2D                   tFoamNormalTex;
SamplerState                sFoamNormalTex;
Texture2D                   tFoamPackedTex;
SamplerState                sFoamPackedTex;
Texture2D                   tFoamEmissiveTex;
SamplerState                sFoamEmissiveTex;

Texture2D                   tFoamEdgeAlbedoTex;
SamplerState                sFoamEdgeAlbedoTex;
Texture2D                   tFoamEdgeNormalTex;
SamplerState                sFoamEdgeNormalTex;
Texture2D                   tFoamEdgePackedTex;
SamplerState                sFoamEdgePackedTex;
Texture2D                   tFoamEdgeEmissiveTex;
SamplerState                sFoamEdgeEmissiveTex;

Texture2D                   tFlowmapTex;
SamplerState                sFlowmapTex;
Texture2D                   tNoiseTex;
SamplerState                sNoiseTex;

#include "materials/programs/utils.hlsl"
#include "materials/programs/utils_pack.hlsl"

inline float3 GetWorldPos( float2 uv, float depth )
{
    float4 projPos = float4( uv * float2( 2.0, -2.0 ) + float2( -1.0, 1.0 ), depth, 1.0 );
    float4 worldPos = mul( cInvViewProjMatrix, projPos );
    return worldPos.xyz / worldPos.w;
}

inline float3 GetDataWithFlowmap( Texture2D t, SamplerState s, float2 uv1, float2 uv2, float power )
{
    float3 x = t.SampleBias( s, uv1, cMIPBias ).xyz;
    float3 y = t.SampleBias( s, uv2, cMIPBias ).xyz;
    return lerp( x, y, power );
}

inline float3 GetNormalMapDataWithFlowmap( Texture2D t, SamplerState s, float2 uv1, float2 uv2, float power )
{
    float MipBiasNormal = cMIPBias * 0.5;
    float3 x = texNormal2DBias( t, s, uv1, MipBiasNormal ).xyz;
    float3 y = texNormal2DBias( t, s, uv2, MipBiasNormal ).xyz;
    return lerp( x, y, power );
}

PS_OUTPUT mainFP( VS_OUTPUT In )
{
    PS_OUTPUT Out;

    float2 texCoord = float2( In.WorldPos.z / cTilingFactor, -In.WorldPos.x / cTilingFactor );
    float2 screenCoords = In.CurrPos.xy / In.CurrPos.w * float2( 0.5f, -0.5f ) + float2( 0.5f, 0.5f );
    float  sceneDepth = tDepthTex.SampleLevel( sDepthTex, screenCoords, 0.0f ).r;
    float3 scenePos = GetWorldPos( screenCoords, sceneDepth );
     
    float noise = tNoiseTex.SampleLevel( sNoiseTex, texCoord * cFlowNoiseTillingFactor, 0.0f ).x;     

    float waterDepth = distance( scenePos, In.WorldPos.xyz );
    float alpha = saturate( waterDepth / ( ( cWaterFadeDepth ) / 0.5f ) );  
    float foamPower = saturate( waterDepth / cWaterFadeDepth );         
    float foamGlow = cFoamGlowAmount;
    float foamEdgeGlow = cFoamEdgeGlowAmount * ( foamPower - alpha );
    float foamEdgeBlendFactor = saturate( ( alpha - 0.5 ) * 2.0f );     

    float3 flowDir = ( tFlowmapTex.SampleLevel( sFlowmapTex, texCoord, 0.0f ).xyz * 2.0f - 1.0f ) * cFlowPower * foamEdgeBlendFactor;

    float offsetPhase = cFlowPhaseScale * noise;
    float time = cTime / ( cFlowSpeed * 2.0 );
    float2 phase = frac( offsetPhase + float2( time, time + 0.5f ) );
    float2 uv0 = ( texCoord - ( flowDir / 2.0f ) ) + ( phase.x * flowDir.xy ) + 0.5f * flowDir.xy;
    float2 uv1 = ( texCoord - ( flowDir / 2.0f ) ) + ( phase.y * flowDir.xy ) + 0.5f * flowDir.xy;

    float flowLerp = abs( ( 2.0f * phase.x ) - 1.0f );
    float3 foamAlbedo = GetDataWithFlowmap( tFoamAlbedoTex, sFoamAlbedoTex, uv0, uv1, flowLerp );
    float3 foamEmissive = GetDataWithFlowmap( tFoamEmissiveTex, sFoamEmissiveTex, uv0, uv1, flowLerp ) * foamGlow;
    float3 foamPacked = GetDataWithFlowmap( tFoamPackedTex, sFoamPackedTex, uv0, uv1, flowLerp );
    float3 foamNormal = GetNormalMapDataWithFlowmap( tFoamNormalTex, sFoamNormalTex, uv0, uv1, flowLerp );
                              
    float foamEdgeTilling = 6.0f;
    float2 foamEdgeCoord = texCoord * foamEdgeTilling;

    float3 foamEdgeAlbedo = tFoamEdgeAlbedoTex.SampleBias( sFoamEdgeAlbedoTex, foamEdgeCoord, cMIPBias );
    float3 foamEdgeEmissive = tFoamEdgeEmissiveTex.SampleBias( sFoamEdgeEmissiveTex, foamEdgeCoord, cMIPBias ) * foamEdgeGlow;
    float3 foamEdgeNormal = texNormal2D( tFoamEdgeNormalTex, sFoamEdgeNormalTex, foamEdgeCoord );
    float3 foamEdgePacked = tFoamEdgePackedTex.SampleBias( sFoamEdgePackedTex, foamEdgeCoord, cMIPBias ).xyz;

    foamAlbedo      = lerp( foamEdgeAlbedo, foamAlbedo, foamEdgeBlendFactor );
    foamEmissive    = lerp( foamEdgeEmissive, foamEmissive, foamEdgeBlendFactor );
    foamNormal      = lerp( foamEdgeNormal, foamNormal, foamEdgeBlendFactor );
    foamPacked      = lerp( foamEdgePacked, foamPacked, foamEdgeBlendFactor );    

    float3x3 normalRotation = float3x3( 1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 1.0, 0.0 );
    foamNormal = mul( foamNormal, normalRotation );
    foamNormal = encodeNormal( foamNormal );    
    
    alpha = max( alpha, foamPower ); 

    Out.GBuffer0 = float4( foamAlbedo, alpha );
    Out.GBuffer1 = float4( foamNormal, alpha );
    Out.GBuffer2 = float4( foamPacked.xyz, alpha );
    Out.GBuffer3 = float4( foamEmissive, alpha );
    Out.GBuffer4 = float4( alpha, 0.0f, 1.0f, 1.0f );            

#if USE_VELOCITY
    float2 screenPos = ( In.CurrPos.xy / In.CurrPos.w ) + cJitterOffset.xy;
    float2 prevScreenPos = ( In.PrevPos.xy / In.PrevPos.w ) + cJitterOffset.zw;
    Out.GBuffer5 = screenPos - prevScreenPos;
#else
    Out.GBuffer5 = 0.0f;
#endif

    return Out;
}
