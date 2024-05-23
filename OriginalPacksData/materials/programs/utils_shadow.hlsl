#if SHADOW_MAP
#if SHADOW_PCSS

#if defined( POISSON_64 )
#define BLOCKER_SEARCH_NUM_SAMPLES 64
#define PCF_NUM_SAMPLES 64
#define SPOTLIGHT_BLOCKER_SEARCH_NUM_SAMPLES 32
#define SPOTLIGHT_PCF_NUM_SAMPLES 32
#elif defined( POISSON_32 )
#define BLOCKER_SEARCH_NUM_SAMPLES 32
#define PCF_NUM_SAMPLES 32
#define SPOTLIGHT_BLOCKER_SEARCH_NUM_SAMPLES 32
#define SPOTLIGHT_PCF_NUM_SAMPLES 32
#else
#define BLOCKER_SEARCH_NUM_SAMPLES 16
#define PCF_NUM_SAMPLES 16
#define SPOTLIGHT_BLOCKER_SEARCH_NUM_SAMPLES 16
#define SPOTLIGHT_PCF_NUM_SAMPLES 16
#endif

static const float2 poissonDisk64[64] = {
    float2(  0.0617981,    0.07294159),
    float2(  0.6470215,    0.7474022),
    float2( -0.5987766,   -0.7512833),
    float2( -0.693034,     0.6913887),
    float2(  0.6987045,   -0.6843052),
    float2( -0.9402866,    0.04474335),
    float2(  0.8934509,    0.07369385),
    float2(  0.1592735,   -0.9686295),
    float2( -0.05664673,   0.995282),
    float2( -0.1203411,   -0.1301079),
    float2(  0.1741608,   -0.1682285),
    float2( -0.09369049,   0.3196758),
    float2(  0.185363,     0.3213367),
    float2( -0.1493771,   -0.3147511),
    float2(  0.4452095,    0.2580113),
    float2( -0.1080467,   -0.5329178),
    float2(  0.1604507,    0.5460774),
    float2( -0.4037193,   -0.2611179),
    float2(  0.5947998,   -0.2146744),
    float2(  0.3276062,    0.9244621),
    float2( -0.6518704,   -0.2503952),
    float2( -0.3580975,    0.2806469),
    float2(  0.8587891,    0.4838005),
    float2( -0.1596546,   -0.8791054),
    float2( -0.3096867,    0.5588146),
    float2( -0.5128918,    0.1448544),
    float2(  0.8581337,   -0.424046),
    float2(  0.1562584,   -0.5610626),
    float2( -0.7647934,    0.2709858),
    float2( -0.3090832,    0.9020988),
    float2(  0.3935608,    0.4609676),
    float2(  0.3929337,   -0.5010948),
    float2( -0.8682281,   -0.1990303),
    float2( -0.01973724,   0.6478714),
    float2( -0.3897587,   -0.4665619),
    float2( -0.7416366,   -0.4377831),
    float2( -0.5523247,    0.4272514),
    float2( -0.5325066,    0.8410385),
    float2(  0.3085465,   -0.7842533),
    float2(  0.8400612,   -0.200119),
    float2(  0.6632416,    0.3067062),
    float2( -0.4462856,   -0.04265022),
    float2(  0.06892014,   0.812484),
    float2(  0.5149567,   -0.7502338),
    float2(  0.6464897,   -0.4666451),
    float2( -0.159861,     0.1038342),
    float2(  0.6455986,    0.04419327),
    float2( -0.7445076,    0.5035095),
    float2(  0.9430245,    0.3139912),
    float2(  0.0349884,   -0.7968109),
    float2( -0.9517487,    0.2963554),
    float2( -0.7304786,   -0.01006928),
    float2( -0.5862702,   -0.5531025),
    float2(  0.3029106,    0.09497032),
    float2(  0.09025345,  -0.3503742),
    float2(  0.4356628,   -0.0710125),
    float2(  0.4112572,    0.7500054),
    float2(  0.3401214,   -0.3047142),
    float2( -0.2192158,   -0.6911137),
    float2( -0.4676369,    0.6570358),
    float2(  0.6295372,    0.5629555),
    float2(  0.1253822,    0.9892166),
    float2( -0.1154335,    0.8248222),
    float2( -0.4230408,   -0.7129914),
};

static const float2 poissonDisk32[32] = {
    float2(  0.06407013,   0.05409927),
    float2(  0.7366577,    0.5789394),
    float2( -0.6270542,   -0.5320278),
    float2( -0.4096107,    0.8411095),
    float2(  0.6849564,   -0.4990818),
    float2( -0.874181,    -0.04579735),
    float2(  0.9989998,    0.0009880066),
    float2( -0.004920578, -0.9151649),
    float2(  0.1805763,    0.9747483),
    float2( -0.2138451,    0.2635818),
    float2(  0.109845,     0.3884785),
    float2(  0.06876755,  -0.3581074),
    float2(  0.374073,    -0.7661266),
    float2(  0.3079132,   -0.1216763),
    float2( -0.3794335,   -0.8271583),
    float2( -0.203878,    -0.07715034),
    float2(  0.5912697,    0.1469799),
    float2( -0.88069,      0.3031784),
    float2(  0.5040108,    0.8283722),
    float2( -0.5844124,    0.5494877),
    float2(  0.6017799,   -0.1726654),
    float2( -0.5554981,    0.1559997),
    float2( -0.3016369,   -0.3900928),
    float2( -0.5550632,   -0.1723762),
    float2(  0.925029,     0.2995041),
    float2( -0.2473137,    0.5538505),
    float2(  0.9183037,   -0.2862392),
    float2(  0.2469421,    0.6718712),
    float2(  0.3916397,   -0.4328209),
    float2( -0.03576927,  -0.6220032),
    float2( -0.04661255,   0.7995201),
    float2(  0.4402924,    0.3640312),
};

static const float2 poissonDisk16[16] = 
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

float2 PenumbraRadius( float2 lightSize, float zReceiver, float zBlocker )
{
    return lightSize * ( ( zReceiver - zBlocker ) / zBlocker );
}

float2 ProjectToLight( float2 penumbraSize, float nearClip, float zReceiver )
{
    return penumbraSize * ( nearClip / zReceiver );
}

float2 SearchRegionRadius( float2 lightSize, float nearClip, float zReceiver )
{
    return lightSize * ( ( zReceiver - nearClip ) / zReceiver );
}

float2 SpotlightSearchRegionRadius( float2 lightSize, float nearClip, float zReceiver )
{
    return lightSize * ( saturate( zReceiver - nearClip ) / zReceiver );
}

float SpotlightZClipToZEye( float zClip, float nearClip, float farClip )
{
    return farClip * nearClip / ( farClip - zClip * ( farClip - nearClip ) );
}

float PoissonFilter( in float2 uv, in float biasedDepth, in float2 filterRadiusUV, in float4 shadowViewportClamp )
{    
    float sum = 0.0f;
    for ( int i = 0; i < PCF_NUM_SAMPLES; ++i )
    {
#if PCF_NUM_SAMPLES == 16
        float2 shadowUV = clamp( uv + poissonDisk16[ i ] * filterRadiusUV, shadowViewportClamp.xy, shadowViewportClamp.zw );
#elif PCF_NUM_SAMPLES == 32
        float2 shadowUV = clamp( uv + poissonDisk32[ i ] * filterRadiusUV, shadowViewportClamp.xy, shadowViewportClamp.zw );
#elif PCF_NUM_SAMPLES == 64
        float2 shadowUV = clamp( uv + poissonDisk64[ i ] * filterRadiusUV, shadowViewportClamp.xy, shadowViewportClamp.zw );
#endif
        sum += tShadowTex.SampleCmpLevelZero( sShadowComparisonSampler, shadowUV, biasedDepth );
    }
    return sum / PCF_NUM_SAMPLES;
}

float SpotlightPoissonFilter( in float2 uv, in float biasedDepth, in float2 filterRadiusUV, in float4 shadowViewportClamp )
{    
    float sum = 0.0f;
    for ( int i = 0; i < SPOTLIGHT_PCF_NUM_SAMPLES; ++i )
    {
#if SPOTLIGHT_PCF_NUM_SAMPLES == 16
        float2 shadowUV = clamp( uv + poissonDisk16[ i ] * filterRadiusUV, shadowViewportClamp.xy, shadowViewportClamp.zw );
#elif SPOTLIGHT_PCF_NUM_SAMPLES == 32
        float2 shadowUV = clamp( uv + poissonDisk32[ i ] * filterRadiusUV, shadowViewportClamp.xy, shadowViewportClamp.zw );
#elif SPOTLIGHT_PCF_NUM_SAMPLES == 64
        float2 shadowUV = clamp( uv + poissonDisk64[ i ] * filterRadiusUV, shadowViewportClamp.xy, shadowViewportClamp.zw );
#endif
        sum += tShadowTex.SampleCmpLevelZero( sShadowComparisonSampler, shadowUV, biasedDepth );
    }
    return sum / SPOTLIGHT_PCF_NUM_SAMPLES;
}

void FindBlocker( out float blockerSum, out float numBlockers, in float2 uv, in float biasedDepth, in float2 searchWidth, in float4 shadowViewportClamp )
{             
    blockerSum = 0;
    numBlockers = 0;

    for ( int i = 0; i < BLOCKER_SEARCH_NUM_SAMPLES; ++i )
    {
#if BLOCKER_SEARCH_NUM_SAMPLES == 16
        float2 shadowUV = clamp( uv + poissonDisk16[ i ] * searchWidth, shadowViewportClamp.xy, shadowViewportClamp.zw );
#elif BLOCKER_SEARCH_NUM_SAMPLES == 32
        float2 shadowUV = clamp( uv + poissonDisk32[ i ] * searchWidth, shadowViewportClamp.xy, shadowViewportClamp.zw );
#elif BLOCKER_SEARCH_NUM_SAMPLES == 64
        float2 shadowUV = clamp( uv + poissonDisk64[ i ] * searchWidth, shadowViewportClamp.xy, shadowViewportClamp.zw );
#endif

        float shadowMapDepth = tShadowTex.SampleLevel( sBilinearClamp, shadowUV, 0 ).x;

#ifdef INVERTED_DEPTH_RANGE
        if ( shadowMapDepth > biasedDepth ) 
#else
        if ( shadowMapDepth < biasedDepth ) 
#endif
        {
            blockerSum += shadowMapDepth;
            numBlockers++;
        }
    }
}

void SpotlightFindBlocker( out float blockerSum, out float numBlockers, in float2 uv, in float biasedDepth, in float2 searchWidth, in float4 shadowViewportClamp )
{             
    blockerSum = 0;
    numBlockers = 0;

    for ( int i = 0; i < SPOTLIGHT_BLOCKER_SEARCH_NUM_SAMPLES; ++i )
    {
#if SPOTLIGHT_BLOCKER_SEARCH_NUM_SAMPLES == 16
        float2 shadowUV = clamp( uv + poissonDisk16[ i ] * searchWidth, shadowViewportClamp.xy, shadowViewportClamp.zw );
#elif SPOTLIGHT_BLOCKER_SEARCH_NUM_SAMPLES == 32
        float2 shadowUV = clamp( uv + poissonDisk32[ i ] * searchWidth, shadowViewportClamp.xy, shadowViewportClamp.zw );
#elif SPOTLIGHT_BLOCKER_SEARCH_NUM_SAMPLES == 64
        float2 shadowUV = clamp( uv + poissonDisk64[ i ] * searchWidth, shadowViewportClamp.xy, shadowViewportClamp.zw );
#endif

        float shadowMapDepth = tShadowTex.SampleLevel( sBilinearClamp, shadowUV, 0 ).x;

#ifdef INVERTED_DEPTH_RANGE
        if ( shadowMapDepth > biasedDepth ) 
#else
        if ( shadowMapDepth < biasedDepth ) 
#endif
        {
            blockerSum += shadowMapDepth;
            numBlockers++;
        }
    }
}

float GetShadowPCSS( float2 uv, float depth, in float2 shadowNearFar, in float2 lightSize, in float shadowBias, in float4 shadowViewportClamp, in float2 shadowViewportSize )
{
    float z = depth;                     
#ifdef INVERTED_DEPTH_RANGE
    float zEye = 1.0f - z;
#else
    float zEye = z;
#endif 

#ifdef INVERTED_DEPTH_RANGE
    float biasedDepth = z + shadowBias;
#else
    float biasedDepth = z - shadowBias;
#endif

    float2 searchRegionRadius = SearchRegionRadius( lightSize, shadowNearFar.x, zEye ); 
    searchRegionRadius *= shadowViewportSize;

    float blockerSum = 0;
    float numBlockers = 0;
    FindBlocker( blockerSum, numBlockers, uv, biasedDepth, searchRegionRadius, shadowViewportClamp );

    if ( numBlockers < 1 )
        return 1.0f;           
        
    float avgBlockerZ = blockerSum / numBlockers;          

#ifdef INVERTED_DEPTH_RANGE
    float avgBlockerZEye = 1.0f - avgBlockerZ;
#else
    float avgBlockerZEye = avgBlockerZ;
#endif  

    float2 penumbraRadius = PenumbraRadius( lightSize, zEye, avgBlockerZEye ); 
    float2 filterRadiusUV = ProjectToLight( penumbraRadius, shadowNearFar.x, zEye );
    filterRadiusUV *= shadowViewportSize;
    return PoissonFilter( uv, biasedDepth, filterRadiusUV, shadowViewportClamp );
}

float GetSpotLightShadowPCSS( float2 uv, float depth, in float2 shadowNearFar, in float2 lightSize, in float shadowBias, in float4 shadowViewportClamp, in float2 shadowViewportSize )
{
    float z = depth;                     
#ifdef INVERTED_DEPTH_RANGE
    float zEye = 1.0f - z;
#else
    float zEye = z;
#endif 

    zEye = SpotlightZClipToZEye( zEye, shadowNearFar.x, shadowNearFar.y );

#ifdef INVERTED_DEPTH_RANGE
    float biasedDepth = z + shadowBias;
#else
    float biasedDepth = z - shadowBias;
#endif

    float2 searchRegionRadius = SpotlightSearchRegionRadius( lightSize, shadowNearFar.x, zEye ); 
    searchRegionRadius *= shadowViewportSize;

    float blockerSum = 0;
    float numBlockers = 0;
    SpotlightFindBlocker( blockerSum, numBlockers, uv, biasedDepth, searchRegionRadius, shadowViewportClamp );

    if ( numBlockers < 1 )
        return 1.0f;           
        
    float avgBlockerZ = blockerSum / numBlockers;          

#ifdef INVERTED_DEPTH_RANGE
    float avgBlockerZEye = 1.0f - avgBlockerZ;
#else
    float avgBlockerZEye = avgBlockerZ;
#endif  

    avgBlockerZEye = SpotlightZClipToZEye( avgBlockerZEye, shadowNearFar.x, shadowNearFar.y );

    float2 penumbraRadius = PenumbraRadius( lightSize, zEye, avgBlockerZEye ); 
    float2 filterRadiusUV = ProjectToLight( penumbraRadius, shadowNearFar.x, zEye );
    filterRadiusUV *= shadowViewportSize;
    return SpotlightPoissonFilter( uv, biasedDepth, filterRadiusUV, shadowViewportClamp );
}
#endif

#if SHADOW_PCF
float GetShadowPCF( in float2 uv, in float depth, in float shadowBias, in float4 shadowViewportClamp, in float2 shadowViewportTexel )
{        
    float2 uv0 = clamp( uv,                                         shadowViewportClamp.xy, shadowViewportClamp.zw );
    float2 uv1 = clamp( uv + float2( shadowViewportTexel.x, 0.0f ), shadowViewportClamp.xy, shadowViewportClamp.zw );
    float2 uv2 = clamp( uv + float2( 0.0f, shadowViewportTexel.y ), shadowViewportClamp.xy, shadowViewportClamp.zw );
    float2 uv3 = clamp( uv + shadowViewportTexel.xy,                shadowViewportClamp.xy, shadowViewportClamp.zw );

#ifdef INVERTED_DEPTH_RANGE
    float biasedDepth = depth + shadowBias;
#else
    float biasedDepth = depth - shadowBias;
#endif

    float4 inLight;
    inLight.r = tShadowTex.SampleCmpLevelZero( sShadowComparisonSampler, uv0, biasedDepth ).x;
    inLight.g = tShadowTex.SampleCmpLevelZero( sShadowComparisonSampler, uv1, biasedDepth ).x;
    inLight.b = tShadowTex.SampleCmpLevelZero( sShadowComparisonSampler, uv2, biasedDepth ).x;
    inLight.a = tShadowTex.SampleCmpLevelZero( sShadowComparisonSampler, uv3, biasedDepth ).x;
    float shadowTerm = dot( inLight, float4( 0.25, 0.25, 0.25, 0.25 ) );
    return shadowTerm;
}
#endif 

float GetShadowSimple( float2 uv, float depth )
{
#if INVERTED_DEPTH_RANGE
    return ( depth >= tShadowTex.SampleLevel( sBilinearClamp, uv, 0.0f ).x ) ? 1.0 : 0.0;
#else 
    return ( depth <= tShadowTex.SampleLevel( sBilinearClamp, uv, 0.0f ).x ) ? 1.0 : 0.0;
#endif
}
#endif