#if USE_FOG 
#define EXPONENTIAL_FOG 1
#define VOLUMETRIC_FOG 1
#endif

#if EXPONENTIAL_FOG
float4 GetExponentialFog( float cameraToPosLen, float4 fogParams, float3 fogColor )
{
    float fogFactor = max( ( cameraToPosLen - fogParams.y ) * fogParams.z, 0.0 );
    float expFogFactor = saturate( ( 1 - exp2( -fogFactor * fogFactor ) ) * fogParams.x );
    return float4( fogColor.xyz * expFogFactor, ( 1.0f - expFogFactor ) );
}
#endif

#if VOLUMETRIC_FOG
float4 GetVolumetricFog( float2 uv, float cameraToPosLen, float volumeMaxDistance )
{
    float3 volumeUV = float3( uv, cameraToPosLen / volumeMaxDistance );
    return tLightScattering.SampleLevel( sLightScattering, volumeUV, 0 );
}
#endif

#if EXPONENTIAL_HEIGHT_FOG
float4 GetExponentialHeightFog( float3 cameraToPos, float skipDistance )
{
    float cameraToPosSqr = dot( cameraToPos, cameraToPos );
    float cameraToPosLenInv = rsqrt( max( cameraToPosSqr, 0.00000001f ) );
    float cameraToPosLen = cameraToPosSqr * cameraToPosLenInv;

    float rayOriginTerms = cFogParams3.x;
    float rayLength = cameraToPosLen;
    float rayDirectionY = cameraToPos.y;

    skipDistance = max( skipDistance, cFogParams1.w );
    if ( skipDistance > 0 )
    {
        float excludeIntersectionTime = skipDistance * cameraToPosLenInv;
        float cameraToExclusionIntersectionY = excludeIntersectionTime * cameraToPos.y;
        float exclusionIntersectionY = cCameraWorldPos.y + cameraToExclusionIntersectionY;
        rayLength = ( 1.0f - excludeIntersectionTime ) * cameraToPosLen;
        rayDirectionY = cameraToPos.y - cameraToExclusionIntersectionY;
        float exponent = max( -127.0f, cFogParams1.y * ( exclusionIntersectionY - cFogParams1.x ) );
        rayOriginTerms = cFogParams2.w * exp2( -exponent );
    }

    float falloff = max( -127.0f, cFogParams1.y * rayDirectionY );
    float lineIntegral = ( 1.0f - exp2( -falloff ) ) / falloff;
    float lineIntegralTaylor = log( 2.0f ) - ( 0.5f * Pow2( log( 2.0f ) ) ) * falloff;
    float exponentialHeightLineIntegralCalc = rayOriginTerms * ( abs( falloff ) > 0.01f ? lineIntegral : lineIntegralTaylor );
    float exponentialHeightLineIntegral = exponentialHeightLineIntegralCalc * rayLength;

    float expFogFactor = max( saturate( exp2( -exponentialHeightLineIntegral ) ), cFogParams3.y );
    return float4( cFogParams2.xyz * ( 1.0f - expFogFactor ), expFogFactor);
}
#endif

#if USE_FOG 
float3 GetFog( in float3 color, in float4 projPos )
{
    if ( cFogParams.w != 0.0f )
    {
        float3 volumeUV = float3( ( projPos.xy / projPos.w ) * float2( 0.5f, -0.5f ) + 0.5f, projPos.w / cFogParams.w );
        float4 fog = tLightScattering.SampleLevel( sLightScattering, volumeUV, 0 );
        return color * fog.a + fog.rgb;
    }
    else
    {
        float4 fog = GetExponentialFog( projPos.w, cFogParams, cFogColor );
        return color * fog.a + fog.rgb;
    }
}
#endif