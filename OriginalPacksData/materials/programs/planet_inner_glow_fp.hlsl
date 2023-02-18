cbuffer FPConstantBuffer : register(b0)
{
    float4    cBlendColor1;
    float4    cBlendColor2;
    float     cFresnelBias;
    float     cFresnelScale;
    float     cFresnelPower;
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
	
    float power = dot( normalize( In.ViewPos.xyz ), In.Normal );
    float3 viewDir = -normalize( In.ViewPos.xyz );
    float3 lightDir = cLightDirection;
    float n1 = dot( In.Normal, viewDir );
    float n2 = dot( In.Normal, lightDir );
    float light = saturate( n1 + 0.5 );
    float night = saturate( -0.1 - n2 );
    float fresnel = cFresnelBias + cFresnelScale * pow( 1 + power + 0.01f, cFresnelPower );
	
    Out.Color = lerp( cBlendColor1, cBlendColor2, saturate( 1 - ( fresnel ) ) );
    Out.Color.w = 1 ;
    Out.Color *= saturate( ( night - light ) ) * 7;
	Out.Color.xyz = max( float3( 0, 0, 0 ), Out.Color.xyz );
	
    return Out;
}