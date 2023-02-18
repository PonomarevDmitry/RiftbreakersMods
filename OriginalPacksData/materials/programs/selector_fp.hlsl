#include "materials/programs/utils.hlsl"

cbuffer FPConstantBuffer : register(b0)
{
    float4  cSelectorPosition;
    float4  cEmissiveColor;
};

struct VS_OUTPUT
{
    float4  Position        : SV_POSITION;
    float3  TexCoord        : TEXCOORD0;
    float3  IconTexCoord    : TEXCOORD1;
    float3  WorldPos        : TEXCOORD2;
};

struct PS_OUTPUT
{
    float4      Color       : SV_TARGET0;
};

Texture2D       tAlbedo         : register( t0 );
SamplerState    sAlbedo         : register( s0 );
Texture2D       tEmissive       : register( t1 );
SamplerState    sEmissive       : register( s1 );
Texture2D       tGradient       : register( t2 );
SamplerState    sGradient       : register( s2 );
Texture2D       tIcon           : register( t3 );
SamplerState    sIcon           : register( s3 );

PS_OUTPUT mainFP( VS_OUTPUT In ) 
{
    PS_OUTPUT Out;
    
    float hDistance = length( cSelectorPosition.xz - In.WorldPos.xz );
    float vDistance = ( cSelectorPosition.y - In.WorldPos.y );
    float hAlpha = smoothstep( 0, 9, 18 - hDistance );
    float vAlpha = clamp( ( vDistance / 20.0 ), 0.0, 1.0 );

    float focusDistance = abs( cSelectorPosition.w - In.WorldPos.y );
    float focusAlpha = clamp( 1.0 - ( focusDistance / 8.0 ), 1.0, 1.0 );

    float2 uv = In.TexCoord.xy;

    bool emissive = true;

    if ( In.TexCoord.z < 0.5f )
    {
        Out.Color = tex2D( tAlbedo, sAlbedo, In.TexCoord.xy );
        Out.Color.xyz = Out.Color.xyz + float3( 0.8, 0.8, 0.8 ) * ( Out.Color.a );
        emissive = false;
    }
    else if ( In.TexCoord.z < 1.5f )
    {
        uv = In.TexCoord.xy / float2( 4.0, 2.0 );
        Out.Color = tex2D( tAlbedo, sAlbedo, uv );
    }
    else if ( In.TexCoord.z < 2.5f )
    {
        uv = In.TexCoord.xy / float2( 4.0, 2.0 ) + float2( 0.25, 0.0 );
        Out.Color = tex2D( tAlbedo, sAlbedo, uv );
    }
    else if ( In.TexCoord.z < 3.5f )
    {
        uv = In.TexCoord.xy / float2( 4.0, 2.0 ) + float2( 0.0, 0.5 );
        Out.Color = tex2D( tAlbedo, sAlbedo, uv );
    }
    else if ( In.TexCoord.z < 4.5f )
    {
        uv = In.TexCoord.xy / float2( 4.0, 2.0 ) + float2( 0.25, 0.5 );
        Out.Color = tex2D( tAlbedo, sAlbedo, uv );
        focusAlpha = 1.0f;
    }
    else if ( In.TexCoord.z < 5.5f )
    {
        uv = In.TexCoord.xy / float2( 4.0, 2.0 ) + float2( 0.5, 0.0 );
        Out.Color = tex2D( tAlbedo, sAlbedo, uv );
        focusAlpha = 1.0f;
    }
	else if ( In.TexCoord.z < 6.5f )
    {
        uv = In.TexCoord.xy / float2( 4.0, 2.0 );
        Out.Color = tex2D( tAlbedo, sAlbedo, uv );
		Out.Color.xzw /= 2.0f;
        focusAlpha = 1.0f;
    }
    else if ( In.TexCoord.z < 7.5f )
    {
        uv = In.TexCoord.xy / float2( 4.0, 2.0 );
        Out.Color = tex2D( tAlbedo, sAlbedo, uv );
        float totalLuminance = saturate( dot( Out.Color.xyz, float3( 0.3, 0.59, 0.11 ) ) );
        Out.Color.xyz = totalLuminance * 0.7 * float3( 10.0/255.0, 128.0/255.0, 255.0/255.0 );   
        Out.Color.w *= 1.1;
        emissive = false;
    }
    else if ( In.TexCoord.z < 8.5f )
    {
        uv = In.TexCoord.xy / float2( 4.0, 2.0 );
        Out.Color = tex2D( tAlbedo, sAlbedo, uv );
        float totalLuminance = saturate( dot( Out.Color.xyz, float3( 0.3, 0.59, 0.11 ) ) );
        Out.Color.xyz = totalLuminance * float3( 555.0/255.0, 30.0/255.0, 0.0/255.0 );   
        Out.Color.w *= 0.8f;
        emissive = false;
    }
    else if ( In.TexCoord.z < 9.5f )
    {
        uv = In.TexCoord.xy / float2( 4.0, 2.0 );
        Out.Color = tex2D( tAlbedo, sAlbedo, uv );
        float totalLuminance = saturate( dot( Out.Color.xyz, float3( 0.3, 0.59, 0.11 ) ) );
        Out.Color.xyz = totalLuminance * float3( 755.0/255.0, 150.0/255.0, 0.0/255.0 );   
        Out.Color.w *= 1.0f;
    }

    if ( In.IconTexCoord.z > 0 )
    {
        float iconNumber = round(In.IconTexCoord.z);
        iconNumber = iconNumber -  1.0;
        float column = round(fmod(iconNumber, 3));
        float row = floor(iconNumber / 3.0);
        float2 iconUv = (In.IconTexCoord.xy / float2( 3.0, 3.0 )) + float2( ( 1.0 / 3.0 ) * column, ( 1.0 / 3.0 ) * row );
        float4 iconColor = tex2D( tIcon, sIcon , iconUv );
        Out.Color = lerp( Out.Color, iconColor, iconColor.a);
    }

    if ( emissive  )
    {
        Out.Color.a *= focusAlpha;
        float emissivePower = tEmissive.Sample( sEmissive, uv ).x;
        emissivePower *= tGradient.Sample( sGradient, In.TexCoord ).x;
        Out.Color.xyz += float3( cEmissiveColor.rgb + cEmissiveColor.a * emissivePower * emissivePower ) * emissivePower;
    }
    
    Out.Color.a *= min( hAlpha, vAlpha );

    return Out;
}
