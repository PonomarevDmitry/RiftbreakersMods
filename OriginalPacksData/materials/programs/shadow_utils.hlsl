#if SHADOW_MAP

#if DIRECTIONAL_LIGHT
#define SHADOW_PENUMBRA 0.1
#define SHADOW_NEAR 0.6
#elif SPOT_LIGHT
#define SHADOW_PENUMBRA 0.3
#define SHADOW_NEAR 0.7
#elif POINT_LIGHT
#define SHADOW_PENUMBRA 0.3
#define SHADOW_NEAR 0.7
#endif

#define BLOCKER_SEARCH_NUM_SAMPLES 16
#define PCF_NUM_SAMPLES 16

#if SHADOW_PCSS
static float2 poissonDisk[16] = 
{
	float2( -0.94201624,  -0.39906216 ),
	float2(  0.94558609,  -0.76890725 ),
	float2( -0.094184101, -0.92938870 ),
	float2(  0.34495938,   0.29387760 ),
	float2( -0.91588581,   0.45771432 ),
	float2( -0.81544232,  -0.87912464 ),
	float2( -0.38277543,   0.27676845 ),
	float2(  0.97484398,   0.75648379 ),
	float2(  0.44323325,  -0.97511554 ),
	float2(  0.53742981,  -0.47373420 ),
	float2( -0.26496911,  -0.41893023 ),
	float2(  0.79197514,   0.19090188 ),
	float2( -0.24188840,   0.99706507 ),
	float2( -0.81409955,   0.91437590 ),
	float2(  0.19984126,   0.78641367 ),
	float2(  0.14383161,  -0.14100790 )
};

float PenumbraSize( float zReceiver, float zBlocker )
{
    return (zReceiver - zBlocker) / zBlocker;
}

void FindBlocker( out float avgBlockerDepth, out float numBlockers, float2 uv, float zReceiver )
{
    float searchWidth = SHADOW_PENUMBRA * (zReceiver - SHADOW_NEAR) / zReceiver;
    float blockerSum = 0;
    numBlockers = 0;

    for ( int i = 0; i < BLOCKER_SEARCH_NUM_SAMPLES; ++i )
    {
        float shadowMapDepth = tShadowTex.SampleLevel( sDepthTex, uv + poissonDisk[i] * searchWidth, 0 ).x;
       
        if ( shadowMapDepth < zReceiver ) 
        {
            blockerSum += shadowMapDepth;
            numBlockers++;
        }
    }

    avgBlockerDepth = blockerSum / numBlockers;
}

float PoissonFilter( float2 uv, float zReceiver, float filterRadiusUV )
{
    float sum = 0.0f;
    for ( int i = 0; i < PCF_NUM_SAMPLES; ++i )
    {
        float2 offset = poissonDisk[i] * filterRadiusUV;
        sum += tShadowTex.SampleCmpLevelZero( sShadowTex, uv + offset, zReceiver );
    }
    return sum / PCF_NUM_SAMPLES;
}

float PCSS( float4 coords )
{
    float2 uv = coords.xy;
    float zReceiver = coords.z;

    float avgBlockerDepth = 0;
    float numBlockers = 0;
    FindBlocker( avgBlockerDepth, numBlockers, uv, zReceiver );

    if( numBlockers < 1 )
        return 1.0f;

    float penumbraRatio = PenumbraSize(zReceiver, avgBlockerDepth);
    float filterRadiusUV = penumbraRatio * cShadowParams.x * cShadowParams.y / coords.z;
    return PoissonFilter( uv, zReceiver, filterRadiusUV );
}
#endif

#if SHADOW_PCF
float PCF( float4 uv )
{
	float2 uv1 = float2( uv.x + 0.0005, uv.y );
    float2 uv2 = float2( uv.x, uv.y + 0.0005 );
    float2 uv3 = float2( uv.x + 0.0005, uv.y + 0.0005 );

    float4 inLight;
    inLight.r = tShadowTex.SampleCmpLevelZero( sShadowTex, uv.xy, uv.z ).x;
    inLight.g = tShadowTex.SampleCmpLevelZero( sShadowTex, uv1.xy, uv.z ).x;
    inLight.b = tShadowTex.SampleCmpLevelZero( sShadowTex, uv2.xy, uv.z ).x;
    inLight.a = tShadowTex.SampleCmpLevelZero( sShadowTex, uv3.xy, uv.z ).x;
    float shadowTerm = dot( inLight, float4(0.25, 0.25, 0.25, 0.25) );
    return shadowTerm;
}
#endif

float GetShadow( float4 uv )
{
	uv = uv / uv.w;
#if SHADOW_PCSS
    return PCSS( uv );
#elif SHADOW_PCF
    return PCF( uv );
#else
    float shadowDepth = tShadowTex.Sample( sShadowTex, uv.xy ).x;
    float shadowTerm = ( uv.z <= shadowDepth ) ? 1.0 : 0.0;
    return shadowTerm;
#endif
}
#endif