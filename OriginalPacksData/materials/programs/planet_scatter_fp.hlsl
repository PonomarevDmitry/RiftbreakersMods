cbuffer FPConstantBuffer : register(b0)
{
    float4    cLightDirection;
};

struct VS_OUTPUT
{
    float4 Position         : SV_POSITION;
    float2 TexCoord         : TEXCOORD0;
    float3 Normal           : TEXCOORD1;
    float4 ViewPos          : TEXCOORD2;
};

struct PS_OUTPUT
{
    float4      Color       : SV_TARGET0;
};

PS_OUTPUT mainFP( VS_OUTPUT In ) 
{
    PS_OUTPUT Out;

    float3 lightDir = cLightDirection;
    float night = dot( In.Normal, lightDir );
    night = saturate( -0.85 - night );

    Out.Color.xyz =  float3( 2000, 1000, 0 ) * ( night );
    Out.Color.xyz = max( float3( 0, 0, 0 ), Out.Color.xyz );
    Out.Color.w = night;
    return Out;
}