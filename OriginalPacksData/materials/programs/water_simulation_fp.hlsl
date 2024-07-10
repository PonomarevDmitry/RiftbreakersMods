cbuffer FPConstantBuffer : register(b0)
{
#if USE_REPROJECTION
    matrix              cInvViewProjMatrix;
    matrix              cPrevViewProjMatrix;
#endif 
#if USE_RAIN
    float               cTime;
    float               cRainIntensity;
#endif
    int2                cViewportSize;
    float 				cWaterPhase;                  
    float 				cWaterAttenuation;             
    float 				cWaterDeltaUv;
#if USE_COLLISION
    float               cWaterFoamAttenuation;
#endif
};

Texture2D               tPreviousTex;
SamplerState            sPreviousTex;

#if USE_COLLISION
    Texture2D<float>        tCollisionTex;
    SamplerState            sCollisionTex;
    Texture2D<float>        tPrevCollisionTex;
    SamplerState            sPrevCollisionTex;
#endif

#if USE_REPROJECTION
inline float3 GetWorldPos( float2 uv )
{
    float4 projPos = float4( uv * float2( 2.0, -2.0 ) + float2( -1.0, 1.0 ), 0.0, 1.0 );
    float4 worldPos = mul( cInvViewProjMatrix, projPos );
    return worldPos.xyz / worldPos.w;
}

inline float2 GetPrevUV( float3 worldPos )
{
    float4 projPos = mul( cPrevViewProjMatrix, float4( worldPos, 1.0f ) );
    projPos.xy /= projPos.w;
    return float2( projPos.xy * float2( 0.5f, -0.5f ) + 0.5f );
}
#endif

#if USE_RAIN
inline float AddRain( float2 uv )
{
    float t = cTime * cRainIntensity;
	float2 pos = frac( floor( t ) * float2( 0.456665, 0.708618 ) ) * ( float2 ) cViewportSize.xy;
	float amp = 1.0f - step( 0.05, frac( t ) );
	return -amp * smoothstep( 2.5f, 0.5f, length( pos - ( uv.xy * ( float2 ) cViewportSize.xy ) ) );
}
#endif

struct VS_OUTPUT
{
    float4      Position    : SV_POSITION;
    float2      TexCoord    : TEXCOORD0;
};

struct PS_OUTPUT
{
    float3      Color0      : SV_TARGET;
};

PS_OUTPUT mainFP( VS_OUTPUT In )
{
    PS_OUTPUT Out;

    float2 uv = In.TexCoord.xy;

#if USE_REPROJECTION
    float3 worldPos = GetWorldPos( uv );
    float2 prevUv = GetPrevUV( worldPos );    
#else 
    float2 prevUv = uv;
#endif

    float4 prev = tPreviousTex.SampleLevel( sPreviousTex, prevUv.xy, 0.0f ).xyzw;
    float collisionFade = tPreviousTex.Load( int3( saturate( prevUv.xy ) * cViewportSize.xy, 0 ) ).z;
    float2 offset = float2( cWaterDeltaUv, cWaterDeltaUv ) / cViewportSize.xy;

    float c1 = tPreviousTex.SampleLevel( sPreviousTex, prevUv.xy + float2( offset.x, 0 ), 0.0f ).x;
    float c2 = tPreviousTex.SampleLevel( sPreviousTex, prevUv.xy + float2( 0, offset.y ), 0.0f ).x;
    float c3 = tPreviousTex.SampleLevel( sPreviousTex, prevUv.xy - float2( offset.x, 0 ), 0.0f ).x;
    float c4 = tPreviousTex.SampleLevel( sPreviousTex, prevUv.xy - float2( 0, offset.y ), 0.0f ).x;

    float ripple = ( prev.x * 2.0f ) - prev.y + cWaterPhase * ( ( c1 + c2 + c3 + c4 ) - ( 4.0f * prev.x ) ) * cWaterAttenuation;
    
#if USE_RAIN
    if ( cRainIntensity > 0.0f )
    {    
        ripple += AddRain( uv );     
    }
#endif

#if USE_COLLISION
    float collision = tCollisionTex.SampleLevel( sCollisionTex, uv, 0.0f ).r;
    float prevCollision = tPrevCollisionTex.SampleLevel( sPrevCollisionTex, prevUv, 0.0f ).r;

    if ( collision > 0.0f && prevCollision == 0.0f ) 
    {
        ripple += collision * 0.5f;
    }
    
    if ( prevCollision > 0.0f && collision == 0.0f ) 
    {
        ripple -= prevCollision * 0.5f;
    }

    ripple = min( ripple, 13.5 );

    collisionFade = max( 2.0f * ripple, collisionFade * cWaterFoamAttenuation );
#endif

    Out.Color0 = float3( ripple, prev.x, collisionFade );
    return Out;
}