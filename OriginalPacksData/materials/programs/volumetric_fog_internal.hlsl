#define PI 3.1415926535897932384626433832795f

float GetExponentialDepth( in float linearDepth )
{
#if INVERTED_DEPTH_RANGE
    float clipFactor = cNearFarClip.x / cNearFarClip.y;
#else 
    float clipFactor = cNearFarClip.y / cNearFarClip.x;
#endif
    return ( 1.0f / linearDepth - clipFactor ) / ( 1.0f - clipFactor );
}

float3 GetWorldPos( float2 uv, float depth )
{
    float4 projPos = float4( uv * float2( 2.0, -2.0 ) + float2( -1.0, 1.0 ), depth, 1.0 );
    float4 worldPos = mul( cInvViewProjMatrix, projPos );
    return worldPos.xyz / worldPos.w;
}

float3 GetVolumeWorldPos( in uint3 texCoord, in uint3 volumeSize, in float3 jitter )
{
    const float3 volumeCoords = ( texCoord + jitter ) / volumeSize;
#if INVERTED_DEPTH_RANGE
    const float viewDepth = volumeCoords.z * cVolumetricFogParams1.z / cNearFarClip.x;
#else 
    const float viewDepth = volumeCoords.z * cVolumetricFogParams1.z / cNearFarClip.y;
#endif
    const float depth = GetExponentialDepth( viewDepth );
    return GetWorldPos( volumeCoords.xy, depth );
}

float3 GetVolumeUV( float3 worldPos, float4x4 viewProjMatrix )
{
    float4 projPos = mul( viewProjMatrix, float4( worldPos, 1.0f ) );
    projPos.xy /= projPos.w;
    return float3( projPos.xy * float2( 0.5f, -0.5f ) + 0.5f, projPos.w / cVolumetricFogParams1.z );
}

float Luminance( float3 color )
{
    return dot( color, float3( 0.3, 0.59, 0.11 ) );
}

float HenyeyGreensteinPhase( float g, float cosTheta )
{
    return ( 1 - g * g ) / ( 4 * PI * pow( 1 + g * g + 2 * g * cosTheta, 1.5f ) );
}