#define __XBOX_DISABLE_SC_UNROLL 1
#include "materials/programs/pack_ops.hlsl"

cbuffer FPConstantBuffer : register(b0)
{    
    float4              cFocalParams;
    float4              cViewportSize;
    matrix              cView;
    float               cFov;
};

struct VS_OUTPUT
{
    float4  Position    : SV_POSITION;
    float2  UV0         : TEXCOORD0;
};

Texture2D       g_MRT1          : register( t0 ); // fragment normal
Texture2D       g_MRT2          : register( t1 ); // fragment depth
Texture2D       g_RAND          : register( t2 ); // cos(a), sin(a), jitter

SamplerState    g_MRT1Sampler   : register( s0 );
SamplerState    g_MRT2Sampler   : register( s1 );
SamplerState    g_RANDSampler   : register( s2 );

#define M_PI 3.14159265f
#define NUM_DIRECTIONS 4
#define NUM_STEPS 7
#define RANDOM_TEXTURE_WIDTH 4.0f

float3 getViewPos(float2 uv, float eye_z)
{
    uv = (uv * float2(2.0, -2.0) - float2(1.0, -1.0));
    return float3(uv * cFocalParams.zw * -eye_z, eye_z);
}

float3 getViewPosFromDepth( float2 vScreenPosition )
{
    float fPixelDepth = g_MRT2.SampleLevel( g_MRT2Sampler, vScreenPosition.xy, 0 ).r;
    float3 viewPos = getViewPos( vScreenPosition, fPixelDepth );
    return viewPos;
}

float2 mainFP( VS_OUTPUT In ) : SV_TARGET
{
    float4 cSSAOParams = float4( 0.4, 0.13, 9.0, 0.0 );

    float fPixelDepth = g_MRT2.SampleLevel( g_MRT2Sampler, In.UV0, 0 ).r;
    float3 pointPos = getViewPos( In.UV0, fPixelDepth );

    float2x2 directionMatrix;
    directionMatrix._m00 =   cos( ( 2 * M_PI ) / NUM_DIRECTIONS );
    directionMatrix._m01 =   sin( ( 2 * M_PI ) / NUM_DIRECTIONS );
    directionMatrix._m10 = - sin( ( 2 * M_PI ) / NUM_DIRECTIONS );
    directionMatrix._m11 =   cos( ( 2 * M_PI ) / NUM_DIRECTIONS );
    float2 deltaUV = float2( 1, 0 ) * ( cSSAOParams.y / ( NUM_STEPS + 1 ) );

    float3 randomValues = g_RAND.Sample( g_RANDSampler, In.UV0 * cViewportSize.xy / RANDOM_TEXTURE_WIDTH ).xyz;
    randomValues.xy = randomValues.xy * 2.0f - 1.0f;
    float2x2 rotationMatrix = float2x2( randomValues.x, randomValues.y, -randomValues.y, randomValues.x );
    float jitter = randomValues.z;

    float3 pointNormal = decodeNormal( g_MRT1.Sample( g_MRT1Sampler, In.UV0 ).xyz );
    pointNormal = mul( cView, float4( pointNormal, 0.0f ) );

    float R = tan( cSSAOParams.y * cFov) * -pointPos.z;

    float occlusion = 0;
    [loop]
    for ( int i = 0; i < NUM_DIRECTIONS; i++ )
    {
        deltaUV = mul( deltaUV, directionMatrix );
        float2 sampleDirection = mul( deltaUV, rotationMatrix );

        float oldAngle = cSSAOParams.x;

        [loop]
        for ( int j = 1; j <= NUM_STEPS; j++ )
        {
            float2 sampleUV = In.UV0 + ((jitter + j) * sampleDirection);

            float3 posSample = getViewPosFromDepth( sampleUV );
            float3 sampleVector = ( posSample - pointPos.xyz );
            float dotVector = dot(sampleVector,sampleVector);
            float rcpVectorlength = rsqrt(dotVector);
            float3 normalVector = sampleVector * rcpVectorlength;
            float vectorLength = rcpVectorlength * dotVector;  

            float gamma = (M_PI / 2) - acos( dot( pointNormal.xyz, normalVector ) );

            [branch]
            if ( gamma > oldAngle )
            {
                float attenuation = saturate( 1 - ( pow( ( vectorLength / R ), 2 ) ) );
                occlusion += attenuation * ( sin( gamma ) - sin( oldAngle ) );
                oldAngle = gamma;
            }
        }
    }

    occlusion = occlusion * ( cSSAOParams.z * M_PI ) / ( NUM_DIRECTIONS * NUM_STEPS );
    occlusion = saturate( 1.0f - occlusion );
    return float2( occlusion, fPixelDepth );
}


