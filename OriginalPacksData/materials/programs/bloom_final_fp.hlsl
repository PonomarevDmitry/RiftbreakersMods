struct VS_OUTPUT
{
    float4      Position    : SV_POSITION;
    float2      TexCoord    : TEXCOORD0;
};

struct PS_OUTPUT
{
    float4      Color0      : SV_TARGET;
};

Texture2D		tRT1	: register( t0 );
Texture2D		tRT2	: register( t1 );
Texture2D		tRT3	: register( t2 );
Texture2D		tRT4	: register( t3 );

SamplerState 	sRT1 	: register( s0 );
SamplerState 	sRT2 	: register( s1 );
SamplerState 	sRT3 	: register( s2 );
SamplerState 	sRT4 	: register( s3 );

PS_OUTPUT mainFP( VS_OUTPUT In )
{
    PS_OUTPUT Out;

    Out.Color0.w = 1.0f;
    Out.Color0.xyz = (
        tRT1.Sample( sRT1, In.TexCoord ).xyz +
        tRT2.Sample( sRT2, In.TexCoord ).xyz +
        tRT3.Sample( sRT3, In.TexCoord ).xyz +
        tRT4.Sample( sRT4, In.TexCoord ).xyz ) * 0.25f;

    return Out;
}
