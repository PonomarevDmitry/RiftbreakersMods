cbuffer FPConstantBuffer : register(b0)
{
    float4  cViewportSize;
    float   cGaussianSigma;
};

struct VS_OUTPUT
{
    float4  Position    : SV_POSITION;
    float2  TexCoord    : TEXCOORD0;
};

Texture2D       tColor       : register( t0 );
SamplerState    sColor       : register( s0 );

struct PS_OUTPUT
{
    float4  Color       : SV_TARGET;
};

PS_OUTPUT mainFP( VS_OUTPUT In ) 
{
    PS_OUTPUT Out;
    
    const int kernelWidth = 13;

    float weights = 0;
    float3 blurred = 0;

    for ( float i = -( kernelWidth - 1 ) / 2; i < ( kernelWidth - 1 ) / 2; ++i )
    {
#if STEP_X
        float2 offset = float2( In.TexCoord.x - i * cViewportSize.z, In.TexCoord.y );
#else
        float2 offset = float2( In.TexCoord.x, In.TexCoord.y - i * cViewportSize.w );
#endif

        float3 color = tColor.Sample( sColor, offset ).xyz;
        float weight = exp( -pow( abs( i ), 2 ) / ( 2 * pow( cGaussianSigma, 2 ) ) );       
        
        weights += weight;
        blurred += color * weight;
    }

    blurred /= weights;
    
    Out.Color = float4( blurred.xyz, 1.0 );
    
    return Out;
}
