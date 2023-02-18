#define MAX_BONE_MATRICES 48
#define PI 3.1415926535897932384626433832795f
#define GAMMA_CORRECTION 1
#define GAMMA 2.2f

inline float3 accurateSRGBToLinear(in float3 sRGBCol )
{
    float3 linearRGBLo = sRGBCol / 12.92;
    float3 linearRGBHi = pow (( sRGBCol + 0.055) / 1.055 , 2.4) ;
    float3 linearRGB = ( sRGBCol <= 0.04045) ? linearRGBLo : linearRGBHi ;
    return linearRGB;
}

inline float3 accurateLinearToSRGB(in float3 linearCol )
{
    float3 sRGBLo = linearCol * 12.92;
    float3 sRGBHi = ( pow( abs ( linearCol ) , 1.0/2.4) * 1.055) - 0.055;
    float3 sRGB = ( linearCol <= 0.0031308) ? sRGBLo : sRGBHi ;
    return sRGB;
} 

inline float3 SRGBToLinear( float3 color )
{
#if GAMMA_CORRECTION == 1
    color = pow( color, GAMMA );
#endif
#if GAMMA_CORRECTION == 2
    color = accurateSRGBToLinear( color );
#endif
    return color;
}

inline float3 LinearToSRGB( float3 color )
{
#if GAMMA_CORRECTION == 1
    color = pow( color, 1.0f / GAMMA );
#endif
#if GAMMA_CORRECTION == 2
    color = accurateLinearToSRGB( color );
#endif
    return color;
}

float4 tex2D( Texture2D t, SamplerState s, float2 uv )
{    
    return t.Sample(s, uv);
}

float4 texLinear2D( Texture2D t, SamplerState s, float2 uv )
{
    float4 color = t.Sample(s, uv);
#if GAMMA_CORRECTION
    return float4( SRGBToLinear(color.xyz), color.w );
#else 
    return color.xyzw;
#endif
}

inline float3 texNormal2D( Texture2D tex, SamplerState texSampler, float2 uv )
{
#if USE_DXT5NM
    float2 n = tex.Sample( texSampler, uv ).xy;
    n.xy = n.xy * 2.0 - 1.0;
    return float3( n.xy, sqrt( 1 - saturate( dot( n.xy, n.xy ) ) ) );
#else
    float3 n = tex.Sample( texSampler, uv ).xyz;
    return n.xyz * 2.0 - 1.0;
#endif
}

inline float3 texNormal2D( Texture2D tex, SamplerState texSampler, float2 uv, float2 dx, float2 dy )
{
#if USE_DXT5NM
    float2 n = tex.SampleGrad( texSampler, uv, dx, dy ).xy;
    n.xy = n.xy * 2.0 - 1.0;
    return float3( n.xy, sqrt( 1 - saturate( dot( n.xy, n.xy ) ) ) );
#else
    float3 n = tex.SampleGrad( texSampler, uv, dx, dy ).xyz;
    return n.xyz * 2.0 - 1.0;
#endif
}

inline float3 texNormal2DBias(Texture2D tex, SamplerState texSampler, float2 uv, float bias)
{
#if USE_DXT5NM
    float2 n = tex.SampleBias(texSampler, uv, bias).xy;
    n.xy = n.xy * 2.0 - 1.0;
    return float3(n.xy, sqrt(1 - saturate(dot(n.xy, n.xy))));
#else
    float3 n = tex.SampleBias(texSampler, uv, bias).xyz;
    return n.xyz * 2.0 - 1.0;
#endif
}

inline float3 texNormal2DArray( Texture2DArray tex, SamplerState texSampler, float3 uv )
{
    float2 n = tex.Sample( texSampler, uv ).xy;
    return float3( n.xy * 2.0 - 1.0, sqrt( 1 - saturate( dot( n.xy, n.xy ) ) ) );
}

inline float3 texNormal2DArray( Texture2DArray tex, SamplerState texSampler, float3 uv, float2 dx, float2 dy )
{
    float2 n = tex.SampleGrad( texSampler, uv, dx, dy ).xy;
    n.xy = n.xy * 2.0 - 1.0;
    return float3( n.xy, sqrt( 1 - saturate( dot( n.xy, n.xy ) ) ) );
}

inline void addFog( inout float3 albedo, float3 fogCol, float d, float4 fogParams )
{
    if ( fogParams.y == fogParams.z )
        return;

    // Fog params: density, linear start, linear end, 1/(end-start)
    float fogFactor = max( ( d - fogParams.y ) * fogParams.w, 0.0 );
    fogFactor = 1 - exp2( -fogFactor * fogFactor );
    fogFactor *= fogParams.x;
    albedo = lerp( albedo.rgb, fogCol.rgb, saturate( fogFactor ) );
}

inline float calcFresnel( float bias, float scale, float power, float3 eyeVec, float3 normal )
{
    return bias + scale * pow( 1.0 + clamp( dot( eyeVec, normal ), -1.0f, 1.0f ), power );
}
