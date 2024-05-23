struct VS_OUTPUT
{
    float4      Position    : SV_POSITION;
    float2      TexCoord    : TEXCOORD0;
    float4      ProjPos     : TEXCOORD1;
};

Texture2D       tNoise    : register( t0 );
SamplerState    sNoise    : register( s0 );

cbuffer FPConstantBuffer : register(b0)
{
    float4      cViewportSize;
}

void mainFP( VS_OUTPUT In )
{    
    float2 uv = In.TexCoord.xy;
    uv.x = lerp( -1.5f, 1.5f, uv.x );
    uv.y = lerp( -1.0f, 1.0f, uv.y );
    
    int2 noiseUv = ( ( 0.5 * In.ProjPos.xy ) + 0.5f ) * cViewportSize.xy;
    float distanceUv = distance( uv, float2( 0,0 ) );
    //distanceUv = max( distanceUv, 0.70 );
    float value = 0.3 / pow( distanceUv, 6.5f );
    value = value * ( ( distanceUv > 0.5 ) ? tNoise.Sample( sNoise, ( fmod( noiseUv.xy, 8.0 ) / 8.0 ) ).x : 1.0f );
    value = floor( value );

    if ( value < 0.5 )
        discard;
}
