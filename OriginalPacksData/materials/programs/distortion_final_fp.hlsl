struct VS_OUTPUT
{
    float4      Position    : SV_POSITION;
    float2      TexCoord    : TEXCOORD0;
};

struct PS_OUTPUT
{
    float4      Color       : SV_TARGET;
};

Texture2D       tMain               : register( t0 );
Texture2D       tDistortion         : register( t1 );
SamplerState    sMain               : register( s0 );
SamplerState    sDistortion         : register( s1 );

PS_OUTPUT mainFP( VS_OUTPUT In ) 
{
    PS_OUTPUT Out;
    float2 distortionVec = tDistortion.Sample( sDistortion, In.TexCoord ).xy;
    Out.Color = tMain.Sample( sMain, In.TexCoord - distortionVec ).xyzw;
    return Out;
} 
