struct VS_OUTPUT
{
    float4 Position     : SV_POSITION;
	float4 Color        : COLOR;
    float2 TexCoord     : TEXCOORD0;
};

Texture2D       g_diffuseMap    : register( t0 );
SamplerState    g_sampler       : register( s0 );

float4 mainFP( VS_OUTPUT In ) : SV_TARGET
{
    float4 output;
    
    float3 yuv = g_diffuseMap.Sample( g_sampler, In.TexCoord ).xyz;
    float y,u,v,r,g,b;
    
    y=1.1643*(yuv.z-0.0625);
    u=yuv.y-0.5;
    v=yuv.x-0.5;
    
    r=y+1.5958*v;
    g=y-0.39173*u-0.81290*v;
    b=y+2.017*u;
    
    output = float4(r,g,b,In.Color.a);

    return output;
}


