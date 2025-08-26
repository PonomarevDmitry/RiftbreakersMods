#include "materials/programs/utils.hlsl"

cbuffer CSConstantBuffer : register(b0)
{
    float4      cPostProcessParams; // x - desaturationVignette, y - darkVignette
    float       cTime;
};

struct VS_OUTPUT
{
    float4      Position    : SV_POSITION;
    float2      TexCoord    : TEXCOORD0;
};

struct PS_OUTPUT
{
    float4      Color0      : SV_TARGET;
};

Texture2D       tTex0       : register( t0 );
SamplerState    sTex0       : register( s0 );


PS_OUTPUT mainFP( VS_OUTPUT In )
{
    PS_OUTPUT Out;

    float4 output = tTex0.Sample( sTex0, In.TexCoord );

    if ( any( cPostProcessParams.xy > 0 ) )
    {      
        float power = lerp( 0.0f, 1.0f, distance( In.TexCoord.xy, float2( 0.5, 0.5 ) ) );
        float3 greyscale = dot( output.xyz, float3( 0.3f, 0.59f, 0.11f ) ).xxx; 
        output.xyz = lerp( output.xyz, greyscale, saturate( power * cPostProcessParams.x ) );      
        output.xyz = max( float3( 0, 0, 0 ), output.xyz * saturate( 1.0 - power * cPostProcessParams.y ) );
        //float redPower = pow( power, red ) * ( ( sin( frequency * cTime ) + 1.0f ) / 2.0f );
        //output.xyz = lerp( output.xyz, float3( 1.0, 0.0, 0.0 ), redPower );
    }

    Out.Color0 = output;
    return Out;
}
