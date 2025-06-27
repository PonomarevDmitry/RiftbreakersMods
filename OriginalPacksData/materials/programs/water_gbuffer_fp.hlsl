cbuffer FPConstantBuffer : register(b0)
{     
    matrix                  cInvViewProjMatrix;
    matrix                  cWaterViewProjMatrix;
    float4                  cJitterOffset;
    float3                  cCameraWorldPos;    
    float                   cMIPBias;
    float                   cTime;
    float                   cTilingFactor;

    float                   cWaveNormalFactor1;
    float                   cWaveNormalFactor2;
    float4                  cWaveScroll;
    float                   cWaveNormalTillingFactor1;
    float                   cWaveNormalTillingFactor2;
    float                   cWaveRefractFactor;

    float                   cFlowPhaseScale;
    float                   cFlowNoiseTillingFactor;

    float                   cWaterDeltaUv;
    float                   cWaterFadeDepth;
    float                   cWaterRefractDepth;
    float4                  cWaterTextureSize;
    float                   cWaterDepth;
    float3                  cWaterColor;
    float3                  cWaterBottomColor;
    float3                  cWaterShoreColor;
    float                   cWaterRoughness;
    float                   cWaterMetalness;

    float                   cFoamFactor;
    float                   cFoamTillingFactor;
    float                   cFoamRefractFactor;
    float4                  cFoamScroll;
    float                   cFoamFlowSpeed;
    float                   cFoamFlowPower;
    float                   cFoamWaveFlowPower;

    float                   cFoamEdgeFactor; 
    float                   cFoamEdgePower;
    float                   cFoamEdgeRefractFactor;
    float                   cFoamEdgeTillingFactor;
    float                   cFoamEdgeFlowSpeed;

    float                   cFresnelPower;
    float                   cFresnelScale;
    float                   cFresnelBias;
    
    float                   cWaterSimulationFoamEdgeScaler1; 
    float                   cWaterSimulationFoamEdgeScaler2;
    float                   cWaterSimulationFoamEdgeScaler3;
    float                   cWaterSimulationFoamEdgeScaler4;
    float                   cWaterSimulationFoamScaler;

    float                   cCausticsPower;
    float                   cCausticsDepth;
    float                   cCausticsTillingFactor;
    float                   cCausticsRefractFactor;
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
Texture2D                   tSceneTex;
SamplerState                sSceneTex;
Texture2D                   tWaterTex;
SamplerState                sWaterTex;

Texture2D                   tFoamAlbedoTex;
SamplerState                sFoamAlbedoTex;
Texture2D                   tFoamNormalTex;
SamplerState                sFoamNormalTex;
Texture2D                   tFoamPackedTex;
SamplerState                sFoamPackedTex;

Texture2D                   tFoamEdgeAlbedoTex;
SamplerState                sFoamEdgeAlbedoTex;
Texture2D                   tFoamEdgeNormalTex;
SamplerState                sFoamEdgeNormalTex;
Texture2D                   tFoamEdgePackedTex;
SamplerState                sFoamEdgePackedTex;

Texture2D                   tWaveTex1;
SamplerState                sWaveTex1;
Texture2D                   tWaveTex2;
SamplerState                sWaveTex2;

Texture2D                   tFlowmapTex;
SamplerState                sFlowmapTex;
Texture2D                   tNoiseTex;
SamplerState                sNoiseTex;
Texture2D                   tCausticsTex;
SamplerState                sCausticsTex;

#include "materials/programs/utils.hlsl"
#include "materials/programs/utils_pack.hlsl"     

float3 blend_linear( float3 n1, float3 n2 )
{
    return normalize( n1 + n2 );
} 
     
 float3 blend_pd( float3 n1, float3 n2 )
{
    return normalize( float3( n1.xy * n2.z + n2.xy * n1.z, n1.z * n2.z ) );
}
   
float3 blend_udn( float3 n1, float3 n2 )
{
    return normalize( float3( n1.xy + n2.xy, n1.z ) ); 
}

inline float3 GetWorldPos( float2 coords, float depth )
{
    float4 projPos = float4( coords * float2( 2.0, -2.0 ) + float2( -1.0, 1.0 ), depth, 1.0 );
    float4 worldPos = mul( cInvViewProjMatrix, projPos );
    return worldPos.xyz / worldPos.w;
}

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

inline float GetReflectionPower( in float3 worldPos )
{
    float3 eyeVec = normalize( worldPos - cCameraWorldPos );
    return saturate( cFresnelBias + pow( 1.0 + clamp( dot( eyeVec, float3( 0.0, 1.0, 0.0 ) ), -1.0f, 1.0f ), cFresnelPower ) * cFresnelScale );
}

inline void GetFoamData( in float2 coords, in float3 waveNormal, in float waveFoamFactor, out float4 foamAlbedo, out float3 foamNormal, out float3 foamPacked )
{
    float noise = tNoiseTex.SampleLevel( sNoiseTex, coords * cFlowNoiseTillingFactor, 0.0f ).x;    
    float x = ( cos( cTime * 1.0f ) * noise * cos( 20 * coords.x + cTime * 0.1f ) + 1.0f ) / 2.0f;       
    float z = ( cos( cTime * 1.0f ) * noise * cos( 20 * coords.y + cTime * 0.1f ) + 1.0f ) / 2.0f;  
    float2 delta = float2( x, z ) / 10.0f;  

    float2 coordsWithOffset = ( coords * cFoamTillingFactor ) + ( delta * cFoamRefractFactor );
    float2 flowDir = ( tFlowmapTex.SampleLevel( sFlowmapTex, coords, 0.0f ).xy * 2.0f - 1.0f ) * cFoamFlowPower;
    flowDir += waveNormal.xy * cFoamWaveFlowPower;

    float offsetPhase = cFlowPhaseScale * noise;
    float time = cTime / ( cFoamFlowSpeed * 2.0 );
    float2 phase = frac( offsetPhase + float2( time, time + 0.5f ) );
    float2 coords0 = ( coordsWithOffset - ( flowDir / 2.0f ) ) + ( phase.x * flowDir.xy ) + 0.5f * flowDir.xy;
    float2 coords1 = ( coordsWithOffset - ( flowDir / 2.0f ) ) + ( phase.y * flowDir.xy ) + 0.5f * flowDir.xy;

    float flowLerp = abs( ( 2.0f * phase.x ) - 1.0f );
    foamAlbedo = GetDataWithFlowmap( tFoamAlbedoTex, sFoamAlbedoTex, coords0, coords1, flowLerp );
    foamNormal = GetNormalMapDataWithFlowmap( tFoamNormalTex, sFoamNormalTex, coords0, coords1, flowLerp );
    foamPacked = GetDataWithFlowmap( tFoamPackedTex, sFoamPackedTex, coords0, coords1, flowLerp ).xyz; 
    
    foamAlbedo.w = saturate( foamAlbedo.w * cFoamFactor * waveFoamFactor );
}

inline void GetFoamEdgeData( in float2 coords, in float waterAlpha, in float waveEdgeFoamPower, out float4 foamEdgeAlbedo, out float3 foamEdgeNormal, out float3 foamEdgePacked )
{    
    float noise = tNoiseTex.SampleLevel( sNoiseTex, coords * cFlowNoiseTillingFactor, 0.0f ).x;  
    float x = ( cos( cTime * 1.0f ) * noise * cos( 20 * coords.x + cTime * 0.1f ) + 1.0f ) / 2.0f;       
    float z = ( cos( cTime * 1.0f ) * noise * cos( 20 * coords.y + cTime * 0.1f ) + 1.0f ) / 2.0f;  
    float2 delta = float2( x, z ) / 10.0f;     

    float2 coordsWithOffset = ( coords * cFoamEdgeTillingFactor ) + ( delta * cFoamEdgeRefractFactor );
    float2 flowDir = float2( 0.5, 0.5 );

    float offsetPhase = cFlowPhaseScale * noise;
    float speed = cFoamEdgeFlowSpeed;
    float time = cTime / speed;
    float2 phase = frac( offsetPhase + float2( time, time + 0.5f ) );
    float2 coords0 = ( coordsWithOffset - flowDir );
    float2 coords1 = ( coordsWithOffset );

    float flowLerp = abs( ( 2.0f * phase.x ) - 1.0f );
    foamEdgeAlbedo = GetDataWithFlowmap( tFoamEdgeAlbedoTex, sFoamEdgeAlbedoTex, coords0, coords1, flowLerp ).xyzw;
    foamEdgeNormal = GetNormalMapDataWithFlowmap( tFoamEdgeNormalTex, sFoamEdgeNormalTex, coords0, coords1, flowLerp ).xyz;
    foamEdgePacked = GetDataWithFlowmap( tFoamEdgePackedTex, sFoamEdgePackedTex, coords0, coords1, flowLerp ).xyz;

    float addEdgeAlpha =  saturate( 1 - pow( waterAlpha, 0.5 ) );
    float mulEdgeAlpha = saturate( 1 - pow( waterAlpha, 5 ) );      
    float waveEdgeAlpha = min( foamEdgeAlbedo.w * waveEdgeFoamPower, waveEdgeFoamPower / 3.0 );

    foamEdgeAlbedo.w = saturate( ( max( waveEdgeAlpha, addEdgeAlpha ) + foamEdgeAlbedo.w * mulEdgeAlpha ) * cFoamEdgeFactor );
    foamEdgeAlbedo.w += 0.2f * waveEdgeFoamPower;
    foamEdgeAlbedo.w *= pow( saturate( waterAlpha / 0.1 ), 0.5 );
}

inline void GetSimulationData( in Texture2D t, in SamplerState s, in float3 worldPos, in float2 texCoord, out float3 waveNormal, out float waveEdgeFoamPower, out float waveFoamFactor )
{
    float4 coords = mul( cWaterViewProjMatrix, float4( worldPos, 1.0f ) );
    float2 offset = cWaterDeltaUv / cWaterTextureSize.xy;
    float f  = t.SampleLevel( s, coords.xy, 0.0f ).z;
    float n  = t.SampleLevel( s, coords.xy, 0.0f ).x;
    float n0 = t.SampleLevel( s, coords.xy - float2( 0.0f, offset.y ), 0.0f ).x;
    float n1 = t.SampleLevel( s, coords.xy - float2( offset.x, 0.0f ), 0.0f ).x;
    float n2 = t.SampleLevel( s, coords.xy + float2( offset.x, 0.0f ), 0.0f ).x;
    float n3 = t.SampleLevel( s, coords.xy + float2( 0.0f, offset.y ), 0.0f ).x;    
    waveNormal = normalize( float3( n2 - n1, n3 - n0, 1.0 ) );   
    
    float noise = tNoiseTex.SampleLevel( sNoiseTex, texCoord * cFlowNoiseTillingFactor, 0.0f ).x;  
    waveFoamFactor = max( noise * 0.3, 1.0f - saturate( f / cWaterSimulationFoamScaler ) );
    waveEdgeFoamPower = max( pow( saturate( f / cWaterSimulationFoamEdgeScaler1 ), cWaterSimulationFoamEdgeScaler2 ), min( n / cWaterSimulationFoamEdgeScaler3, cWaterSimulationFoamEdgeScaler4 ) ); 
}
   
inline void GetWaterWaveData( in float2 coords, in float3 waveNormal, out float3 waterNormal )
{           
    float MipBiasNormal = cMIPBias * 0.5;

    float2 coords0 = ( coords.xy * cWaveNormalTillingFactor1 ) + cTime * cWaveScroll.xy;
    float2 coords1 = ( coords.xy * cWaveNormalTillingFactor2 ) + cTime * cWaveScroll.zw;
    float3 normal1 = texNormal2DBias( tWaveTex1, sWaveTex1, coords0, MipBiasNormal );
    float3 normal2 = texNormal2DBias( tWaveTex2, sWaveTex2, coords1, MipBiasNormal );    

    float noise = tNoiseTex.SampleLevel( sNoiseTex, coords * cFlowNoiseTillingFactor, 0.0f ).x;
    float3 w1 = lerp( float3( 0.0, 0.0, 1.0 ), normal1, saturate( cWaveNormalFactor1 - noise ) );
    float3 w2 = lerp( float3( 0.0, 0.0, 1.0 ), normal2, saturate( cWaveNormalFactor2 - noise ) ); 
     
    waterNormal = blend_linear( w1, w2 );     
    waterNormal = blend_udn( waterNormal, waveNormal );    
}

inline void GetWaterData( in float2 screenCoords, in float3 worldPos, in float3 waterNormal, out float3 waterAlbedo, out float3 waterPacked, out float3 waterRefract, out float waterRefractPower, out float waterAlpha, out float waterDepth, out float waterHeight, out float waterWet, out float waterCaustic )
{       
    float sceneDepth = tDepthTex.SampleLevel( sDepthTex, screenCoords, 0.0f ).r;
    float3 scenePos = GetWorldPos( screenCoords, sceneDepth ); 

    float2 refractCoords = screenCoords + waterNormal.xy * cWaveRefractFactor;
    float refractHeight = GetWorldPos( refractCoords, tDepthTex.SampleLevel( sDepthTex, refractCoords, 0.0f ).r ).y;
    refractCoords = ( refractHeight < worldPos.y ) ? refractCoords : screenCoords;
    float3 refractColor = tSceneTex.SampleLevel( sSceneTex, refractCoords, 0.0f ).xyz;
    refractHeight = ( refractHeight < worldPos.y ) ? refractHeight : scenePos.y;
    float refractDepth = worldPos.y - refractHeight;  
    
    float x = ( cos( 0.5 * worldPos.x + cTime ) + 1.0f ) / 2.0f;       
    float z = ( cos( 0.5 * worldPos.z + cTime ) + 1.0f ) / 2.0f;    
    float delta = ( x + z ) / 2.0f;           

    waterDepth = saturate( refractDepth / cWaterDepth ); 
    waterHeight = worldPos.y - scenePos.y - delta * cFoamEdgePower;
    waterAlpha = saturate( waterHeight / cWaterFadeDepth );            
    waterRefractPower = saturate( refractDepth / cWaterRefractDepth );
    waterAlbedo = lerp( cWaterColor, cWaterBottomColor, waterDepth );
    waterRefract = lerp( refractColor, refractColor * waterAlbedo, waterRefractPower );
    waterPacked = float3( 1.0, cWaterRoughness, cWaterMetalness );  
    waterCaustic = 1.0f - saturate( refractDepth / cCausticsDepth );  
    waterWet = saturate( abs( worldPos.y - scenePos.y ) / 0.05 );
}

PS_OUTPUT mainFP( VS_OUTPUT In )
{
    PS_OUTPUT Out;

    // Coords
    float2 coords = float2( In.WorldPos.z / cTilingFactor, -In.WorldPos.x / cTilingFactor );
    float2 screenCoords = ( In.CurrPos.xy / In.CurrPos.w ) * float2( 0.5f, -0.5f ) + float2( 0.5f, 0.5f ); 

    float noise = tNoiseTex.SampleLevel( sNoiseTex, coords * cFlowNoiseTillingFactor * 3.0, 0.0f ).x;     
    noise = max( saturate( noise - 0.2 ), 0.3 );

    // Water Simulation   
    float3 waveNormal; float waveEdgeFoamPower; float waveFoamFactor;
    GetSimulationData( tWaterTex, sWaterTex, In.WorldPos, coords, waveNormal, waveEdgeFoamPower, waveFoamFactor );

    // Water Wave
    float3 waterNormal;
    GetWaterWaveData( coords, waveNormal, waterNormal );     

    // Water Color and Refract
    float3 waterAlbedo; float3 waterPacked; float3 waterRefract; float waterRefractPower; float waterAlpha; float waterDepth; float waterHeight; float waterWet; float waterCaustic;
    GetWaterData( screenCoords, In.WorldPos, waterNormal, waterAlbedo, waterPacked, waterRefract, waterRefractPower, waterAlpha, waterDepth, waterHeight, waterWet, waterCaustic );

    if ( cCausticsPower > 0.0f )
    {

        float2 coords0 = ( coords * cCausticsTillingFactor ) + waterNormal.xy * cCausticsRefractFactor + cTime * cWaveScroll.xy;
        float2 coords1 = ( coords * cCausticsTillingFactor ) + waterNormal.xy * cCausticsRefractFactor + cTime * cWaveScroll.zw;
        float caustics0 = tCausticsTex.SampleLevel( sCausticsTex, coords0, 0.0f ).x;
        float caustics1 = tCausticsTex.SampleLevel( sCausticsTex, coords1, 0.0f ).x;   

        float causticsColor = caustics0 + caustics1;

        waterRefract = waterRefract + waterRefract * causticsColor * cCausticsPower * waterCaustic * lerp( 0.25, 1.0f, noise );
    }

    float alpha = 1.0f;  
    if ( waterHeight > 0.0 )
    {
        // Foam
        float4 foamAlbedo; float3 foamNormal; float3 foamPacked;
        GetFoamData( coords, waveNormal, waveFoamFactor, foamAlbedo, foamNormal, foamPacked );

        // Foam Edge
        float4 foamEdgeAlbedo; float3 foamEdgeNormal; float3 foamEdgePacked;
        GetFoamEdgeData( coords, waterAlpha, waveEdgeFoamPower, foamEdgeAlbedo, foamEdgeNormal, foamEdgePacked );      
        
        foamEdgeAlbedo.w *= lerp( 0.50f, 1.0f, noise );

        // Blend Foam and Water
        float3 albedo = lerp( waterAlbedo.xyz, foamAlbedo.xyz, foamAlbedo.w );  
        float3 occlusionRoughnessMetalness = lerp( waterPacked, foamPacked, foamAlbedo.w ); 
        float3 normal = lerp( waterNormal, foamNormal, saturate( foamAlbedo.w ) );
        float refract = lerp( waterDepth, 1.0, foamAlbedo.w );       
        
        // Blend Foam Edge
        refract = lerp( refract, 1.0, foamEdgeAlbedo.w ); 
        albedo = lerp( albedo.xyz, foamEdgeAlbedo.xyz, foamEdgeAlbedo.w ); 
        normal = lerp( normal.xyz, foamEdgeNormal.xyz, foamEdgeAlbedo.w );     
        occlusionRoughnessMetalness = lerp( occlusionRoughnessMetalness, foamEdgePacked, foamEdgeAlbedo.w ); 
        occlusionRoughnessMetalness.x *= GetReflectionPower( In.WorldPos );

        Out.GBuffer0 = float4( albedo, alpha );
        Out.GBuffer1 = float4( encodeNormal( mul( normal, float3x3( 1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 1.0, 0.0 ) ) ), alpha );
        Out.GBuffer2 = float4( occlusionRoughnessMetalness, alpha );
        Out.GBuffer3 = float4( waterRefract, alpha );    
        Out.GBuffer4 = float4( alpha, 1.0 - refract , 0.0f, 1.0f );   
    }
    else
    {                
        Out.GBuffer0 = float4( cWaterShoreColor.xyz, waterWet );
        Out.GBuffer1 = float4( float3( 0, 0, 0 ), 0.0f );
        Out.GBuffer2 = float4( float3( 0.0, 0.4, 0 ), waterWet );
        Out.GBuffer3 = float4( waterRefract, waterWet );    
        Out.GBuffer4 = float4( alpha, 0.0, 0.0f, 1.0 ); 
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
