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

    float3 viewDir = -normalize( In.ViewPos.xyz );
    float n0 = saturate( 0.5f - dot( In.Normal, viewDir ) );
    float n1 = dot( In.Normal, viewDir );

    float3 lightDir = cLightDirection;
    float night = dot( In.Normal, lightDir );
    night = saturate( 0.3 - night );

    n0 = pow( n0, 1 );
    n1 = pow( n1, 3 );

    Out.Color.xyzw = float4( 0.0f, 0.0f, 0.0f, 1.0f );

    //Out.Color.x = n0;
    //Out.Color.y = n1;

    Out.Color.xyz =  float3( 12, 80, 160 ) * ( n0 * n1 * night );
    Out.Color.w = ( n0 * n1 * night ) * 100;
    return Out;
}