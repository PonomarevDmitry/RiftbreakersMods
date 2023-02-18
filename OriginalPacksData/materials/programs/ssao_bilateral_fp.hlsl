cbuffer VPConstantBuffer : register(b0)
{
#if STEP_X
    float stepX;  // inverse viewport width
#endif

#if STEP_Y
    float stepY;  // inverse viewport height
#endif
};

struct VS_OUTPUT
{
    float4 Position         : SV_POSITION;
    float2 TexCoord         : TEXCOORD0;
};

Texture2D       tAO         : register( t0 );
SamplerState    sAO         : register( s0 );

float2 mainFP( VS_OUTPUT In ) : SV_TARGET
{
    const int kernelWidth = 7;
    const float sigma = (kernelWidth - 1) / 3;

    float centerDepth = tAO.Sample( sAO, In.TexCoord ).g;

    float weights = 0;
    float blurred = 0;
    
    for ( float i = -(kernelWidth - 1) / 2; i < (kernelWidth - 1) / 2; i++ )
    {
#if STEP_X
        float2 offset = float2( In.TexCoord.x - i * stepX, In.TexCoord.y );
#endif
#if STEP_Y
        float2 offset = float2( In.TexCoord.x, In.TexCoord.y - i * stepY );
#endif

        float2 sampleValue = tAO.Sample( sAO, offset ).rg;
        float sampleDepth = sampleValue.y;
        float sampleOcclusion = sampleValue.x;

        float geometricWeight = exp( -pow( abs(i), 2) / (2 * pow(sigma, 2)) );		
        float photometricWeight = 1 / ( 1 + abs( centerDepth - sampleDepth ) );

        float weight = geometricWeight * photometricWeight;
        weights += weight;
        blurred += sampleOcclusion * weight;
    }

    blurred /= weights;
    return float2( blurred, centerDepth );
}
