#include "materials/programs/utils.hlsl"

cbuffer FPConstantBuffer : register(b0)
{
    float3  cLightDirection;
    float3  cLightColor;
    float4  cSkyboxParams; // sunSize, sunCovergance, atmosphereThickness
    float4  cSkyboxColor; // skyTine
    float3  cWorldCameraPos;
};

struct VS_OUTPUT
{
    float4  Position    : SV_POSITION;
    float2  TexCoord    : TEXCOORD0;
    float3  WorldPos    : TEXCOORD2;
    float3  WorldNor    : TEXCOORD3;
};

struct PS_OUTPUT
{
    float4  Color       : SV_TARGET0;
};

static const float  R0 = 6375e3; //planet radius
static const float  Ra = 6380e3; //atmosphere radius
static const float3 C = float3(0., -R0, 0.); //planet center
static const float  Hr = 8000.0; //Reyleight scattering top
static const float  Hm = 100.0; //Mie scattering top
static const int    steps = 16;

void densities(in float3 pos, out float rayleigh, out float mie) {
    float h = length(pos - C) - R0;
    rayleigh = exp(-h/Hr);
    float3 d = pos;
    d.y = 0.0;
    float dist = length(d);
    float cld = 0.;
    mie = exp(-h/Hm) + cld;
}

float escape(in float3 p, in float3 d) {
    float3 v = p - C;
    float b = dot(v, d);
    float c = dot(v, v) - Ra*Ra;
    float det2 = b * b - c;
    if (det2 < 0.) return -1.;
    float det = sqrt(det2);
    float t1 = -b - det, t2 = -b + det;
    return (t1 >= 0.) ? t1 : t2;
}

void scatter(float3 o, float3 d, float3 s, out float3 mia, out float3 ray) {
    float g = 0.9 + cSkyboxParams.y * 0.1;
    float g2 = g * g;
    float L = escape(o, d);
    float3 Ds = s;
    float mu = dot(d, Ds);
    float opmu2 = 1. + mu * mu;
    float phaseR = cSkyboxParams.w * opmu2;
    float phaseM = cSkyboxParams.x * .1193662 * (1. - g2) * opmu2 / ((2. + g2) * pow(1. + g2 - 2.*g*mu, 1.5));

    float depthR = 0., depthM = 0.;
    float3 R = float3(0,0,0);
    float3 M = float3(0,0,0);

    float3 skyColor = lerp( float3( 5.8, 13.5, 33.1 ), cSkyboxColor.xyz, float3( 1, 1, 1 ) - cSkyboxColor.xyz );

    float3 sunColor = cLightColor.xyz;
    float3 bR = skyColor * 1.0e-6 * pow( cSkyboxParams.z, 2.5 ); // normal earth
    float3 bM = 1.0e-5;  //normal sun

    float dl = L / float(steps);
    for (int i = 0; i < steps; ++i) {
        float l = float(i) * dl;
        float3 p = o + d * l;

        float dR, dM;
        densities(p, dR, dM);
        dR *= dl; dM *= dl;
        depthR += dR;
        depthM += dM;

        float Ls = escape(p, Ds);
        if (Ls > 0.) {
            float dls = Ls / float(steps);
            float depthRs = 0., depthMs = 0.;
            for (int j = 0; j < steps; ++j) {
                float ls = float(j) * dls;
                float3 ps = p + Ds * ls;
                float dRs, dMs;
                densities(ps, dRs, dMs);
                depthRs += dRs * dls;
                depthMs += dMs * dls;
            }

            float3 A = exp(-(bR * (depthRs + depthR) + bM * (depthMs + depthM)));
            A = clamp( 0,50, A);
            R += A * dR;
            M += A * dM;
        }
    }

    mia = M * bM * phaseM * sunColor;
    ray = R * bR * phaseR;
}

float Noise2d( in float2 x )
{
    float xhash = cos( x.x * 37.0 );
    float yhash = cos( x.y * 57.0 );
    return frac( 415.92653 * ( xhash + yhash ) );
}

float NoisyStarField( in float2 vSamplePos, float fThreshhold )
{
    float StarVal = Noise2d( vSamplePos );
    if ( StarVal >= fThreshhold )
        StarVal = pow( (StarVal - fThreshhold)/(1.0 - fThreshhold), 6.0 );
    else
        StarVal = 0.0;
    return StarVal;
}

float StableStarField( in float2 vSamplePos, float fThreshhold )
{
    // Linear interpolation between four samples.
    // Note: This approach has some visual artifacts.
    // There must be a better way to "anti alias" the star field.
    float fractX = frac( vSamplePos.x );
    float fractY = frac( vSamplePos.y );
    float2 floorSample = floor( vSamplePos );    
    float v1 = NoisyStarField( floorSample, fThreshhold );
    float v2 = NoisyStarField( floorSample + float2( 0.0, 1.0 ), fThreshhold );
    float v3 = NoisyStarField( floorSample + float2( 1.0, 0.0 ), fThreshhold );
    float v4 = NoisyStarField( floorSample + float2( 1.0, 1.0 ), fThreshhold );

    float StarVal =   v1 * ( 1.0 - fractX ) * ( 1.0 - fractY )
                    + v2 * ( 1.0 - fractX ) * fractY
                    + v3 * fractX * ( 1.0 - fractY )
                    + v4 * fractX * fractY;
    return StarVal;
}

float getRayleighPhase( float3 light, float3 ray )
{
    float eyeCos = dot( light, ray );
    return 0.75 + 0.75 * ( eyeCos * eyeCos );
}

PS_OUTPUT mainFP( VS_OUTPUT In ) 
{
    PS_OUTPUT Out;

    float3 ray = 0.0f;
    float3 mia = 0.0f;

    float att = 1.0;
    float staratt = 0.0;

    float3 S = normalize( -cLightDirection.xyz );
    float3 V = normalize( In.WorldPos - cWorldCameraPos.xyz );
    float3 O = float3(0., V.y, 0.);
    float3 D = normalize( V.xyz );

    att = lerp( 0, 1, saturate( ( 2 + S.y ) / 2) );

    if ( S.y < 0 )
    {
        att *= 0.1;
        staratt = 1 - lerp( 0, 1, saturate( ( S.y + 1 ) / 2 ) );
        S = normalize( cLightDirection.xyz );
    }

    S.y = abs( S.y );

    if ( D.y < -0.01 )
    {
        D.y = -0.01;
    }

    scatter(O, D, S, mia, ray );
    Out.Color.xyz = att * ( ray );

    if ( D.y > -0.04 )
    {
        Out.Color.xyz += D.y * StableStarField( In.TexCoord.xy * 1500.0f, 0.99f ) * staratt;
    }

    Out.Color.xyz += att * mia;
    Out.Color.xyz = pow(Out.Color.xyz, float3(.6,.6,.6));

    return Out;
}
