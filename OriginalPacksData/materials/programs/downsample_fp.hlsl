struct VS_OUTPUT
{
    float4  Position    : SV_POSITION;
    float4  TexCoord0   : TEXCOORD0;
    float4  TexCoord1   : TEXCOORD1;
};

struct PS_OUTPUT
{
    float4  Color       : SV_TARGET;
};

Texture2D       tTexture    : register( t0 );
SamplerState    sTexture    : register( s0 );

PS_OUTPUT mainFP( VS_OUTPUT In ) 
{
    PS_OUTPUT Out;
    
    float4 b0 = tTexture.Sample( sTexture, In.TexCoord0.xy );
    float4 b1 = tTexture.Sample( sTexture, In.TexCoord0.zw );
    float4 b2 = tTexture.Sample( sTexture, In.TexCoord1.xy );
    float4 b3 = tTexture.Sample( sTexture, In.TexCoord1.zw );

    Out.Color.rgb = ( b0.rgb + b1.rgb + b2.rgb + b3.rgb ) * 0.25;
    Out.Color = float4( max( Out.Color.rgb, 0.0 ), 0.0 );
    
    return Out;
} 
