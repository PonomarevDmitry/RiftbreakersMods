#if VOLUMETRIC_FOG
float4 GetVolumetricFog( float2 uv, float cameraToPosLen, float volumeMaxDistance )
{
    float3 volumeUV = float3( uv, cameraToPosLen / volumeMaxDistance );
    return tLightScattering.SampleLevel( sLightScattering, volumeUV, 0 );
}
#endif

#if USE_FOG 
float3 GetFog( in float3 color, in float4 projPos )
{
    if ( cFogMaxDistance != 0.0f )
    {
        float3 volumeUV = float3( ( projPos.xy / projPos.w ) * float2( 0.5f, -0.5f ) + 0.5f, projPos.w / cFogMaxDistance );
        float4 fog = tLightScattering.SampleLevel( sLightScattering, volumeUV, 0 );
        return color * fog.a + fog.rgb;
    }
    else
    {
        return color;
    }
}
#endif