cbuffer FPConstantBuffer : register(b0)
{    
    float4    cLightDirection;
    float     cFresnelBias;
    float     cFresnelScale;
    float     cFresnelPower;
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

Texture2D       tColorTex   : register( t0 );
SamplerState    sColorTex   : register( s0 );

PS_OUTPUT mainFP( VS_OUTPUT In ) 
{
    PS_OUTPUT Out;

    float4 color = tColorTex.Sample( sColorTex, In.TexCoord ).xyzx;
    float3 viewDir = -normalize( In.ViewPos.xyz );
    float3 lightDir = cLightDirection;
    float n2 = dot( In.Normal, lightDir );
    float night = saturate( 1.0 - n2 );
    float power = dot( normalize( In.ViewPos.xyz ), In.Normal );
    float fresnel = cFresnelBias + cFresnelScale * pow( 1 + power, cFresnelPower * 1.7 );
    Out.Color = lerp( float4( 0,0,0,0 ), color.xyzw, fresnel );
    Out.Color.xyzw *= night * night * night * night;
    Out.Color.xyz = max( float3( 0, 0, 0 ), Out.Color.xyz );
    return Out;
}