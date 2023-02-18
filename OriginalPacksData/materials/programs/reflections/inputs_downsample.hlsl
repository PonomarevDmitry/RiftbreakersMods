struct VS_OUTPUT
{
    float4  Position    : SV_POSITION;
    float4  TexCoord0   : TEXCOORD0;
    float4  TexCoord1   : TEXCOORD1;
};

struct PS_OUTPUT
{
    float4  Normal      : SV_TARGET0;
    float   Depth       : SV_TARGET1;
};

Texture2D       tNormalTexture      : register( t0 );
SamplerState    sNormalTexture      : register( s0 );
Texture2D       tDepthTexture       : register( t1 );
SamplerState    sDepthTexture       : register( s1 );

PS_OUTPUT mainFP( VS_OUTPUT In ) 
{
    PS_OUTPUT Out;
    
    float4 n0 = tNormalTexture.Sample( sNormalTexture, In.TexCoord0.xy );
    float4 n1 = tNormalTexture.Sample( sNormalTexture, In.TexCoord0.zw );
    float4 n2 = tNormalTexture.Sample( sNormalTexture, In.TexCoord1.xy );
    float4 n3 = tNormalTexture.Sample( sNormalTexture, In.TexCoord1.zw );

    Out.Normal = ( n0 + n1 + n2 + n3 ) * 0.25;

    float d0 = tDepthTexture.Sample( sDepthTexture, In.TexCoord0.xy ).x;
    float d1 = tDepthTexture.Sample( sDepthTexture, In.TexCoord0.zw ).x;
    float d2 = tDepthTexture.Sample( sDepthTexture, In.TexCoord1.xy ).x;
    float d3 = tDepthTexture.Sample( sDepthTexture, In.TexCoord1.zw ).x;

    Out.Depth = ( d0 + d1 + d2 + d3 ) * 0.25;
    
    return Out;
} 
