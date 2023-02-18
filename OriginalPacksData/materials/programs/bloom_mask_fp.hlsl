struct VS_OUTPUT
{
    float4  Position        : SV_POSITION;
    float4  TexCoord0       : TEXCOORD0;
    float4  TexCoord1       : TEXCOORD1;
};

struct PS_OUTPUT
{
    float4  Color           : SV_TARGET;
};

Texture2D       tTexture    : register( t0 );
SamplerState    sTexture    : register( s0 );

cbuffer FPConstantBuffer
{
    float4 cBloomParams; // x: bloom_min_exposure, y: bloom_max_exposure, z: bloom_scale, w: bloom_threshold
    float  cBloomCenterScale;
};

float Luma( float3 c )
{
    return dot( c.rgb, float3( 0.3, 0.59, 0.11 ) );
}

PS_OUTPUT mainFP( VS_OUTPUT In ) 
{    
#ifdef BLOOMSCALE
    float4 c = tTexture.Sample(sTexture, (In.TexCoord0.xy+ In.TexCoord0.zw+ In.TexCoord1.xy+ In.TexCoord1.zw) / 4.0);
    float  w4 = (1 / (Luma(c.rgb) + 1)) * cBloomCenterScale;
#endif

    float4 b0 = tTexture.Sample( sTexture, In.TexCoord0.xy );
    float4 b1 = tTexture.Sample( sTexture, In.TexCoord0.zw );
    float4 b2 = tTexture.Sample( sTexture, In.TexCoord1.xy );
    float4 b3 = tTexture.Sample( sTexture, In.TexCoord1.zw );

    float w0 = 1 / ( Luma( b0.rgb ) + 1 );
    float w1 = 1 / ( Luma( b1.rgb ) + 1 );
    float w2 = 1 / ( Luma( b2.rgb ) + 1 );
    float w3 = 1 / ( Luma( b3.rgb ) + 1 );

#ifdef BLOOMSCALE
    float3 color = ( c.rgb * w4 + b0.rgb * w0 + b1.rgb * w1 + b2.rgb * w2 + b3.rgb * w3) / (w0 + w1 + w2 + w3 + w4);
#else
    float3 color = ( b0.rgb * w0 + b1.rgb * w1 + b2.rgb * w2 + b3.rgb * w3 ) / ( w0 + w1 + w2 + w3 );
#endif

    float totalLuminance = saturate( Luma( color ) ) - cBloomParams.w;
    float bloomLuminance = lerp( cBloomParams.x, cBloomParams.y, totalLuminance );
    float bloomAmount = bloomLuminance * cBloomParams.z;

    PS_OUTPUT Out;
    Out.Color = float4( max( bloomAmount * color, 0.0 ), 0.0 );
    return Out;
} 
