#include "materials/programs/utils.hlsl"

cbuffer FPConstantBuffer : register(b0)
{
#if USE_PROJECTED_POS
    matrix      cInvProjMatrix;
    matrix      cInvWorldViewMatrix;
#endif
    float4      cEmissiveColor;
    float       cGlowAmount;
    float       cGlowFactor;
    float       cProgress;
    float       cAngle;
};

struct VS_OUTPUT
{
    float4      Position    : SV_POSITION;
    float4      ProjPos     : TEXCOORD0;
    float2      TexCoord    : TEXCOORD1;
};

struct PS_OUTPUT
{
    float4      Color       : SV_TARGET;
};

Texture2D       tColorMap;
SamplerState    sColorMap;

#if USE_PROJECTED_POS
Texture2D       tDepthTex;
SamplerState    sDepthTex;
#endif

#if USE_PROJECTED_POS
float4 getViewPosFromDepth( float2 screenPos )
{
    float x = screenPos.x * 2.0f - 1.0f;
    float y = (1.0f - screenPos.y) * 2.0f - 1.0f;
    float z = tDepthTex.Sample( sDepthTex, screenPos.xy ).r;

    float4 projPos = float4( x, y, z, 1.0f );
    float4 viewPos = mul( cInvProjMatrix, projPos );
    viewPos = viewPos.xyzw / viewPos.w;
    return viewPos;
}
#endif

PS_OUTPUT mainFP( VS_OUTPUT In ) 
{
    PS_OUTPUT Out;

#if USE_PROJECTED_POS
    float2 screenPos = In.ProjPos.xy / In.ProjPos.w;
    screenPos = screenPos * float2( 0.5f, -0.5f ) + float2( 0.5f, 0.5f );

    float4 viewPos = getViewPosFromDepth( screenPos.xy );
    float4 localPos = mul( cInvWorldViewMatrix, viewPos );

    clip( 0.5f - abs( localPos.xyz ) );
    float2 texCoord = localPos.xz + 0.5f;
#else
    float2 texCoord = In.TexCoord;
#endif
     
    float distance = length( ( texCoord.xy * 2.0f ) - 1.0f );
    if ( distance > cProgress )
        discard;

    float2 centeredTexCoord = texCoord - float2( 0.5f, 0.5f );
    float pixelAngle = atan2( centeredTexCoord.y, centeredTexCoord.x );

    float angleInRadians = radians( cAngle );

    if ( abs( pixelAngle ) > angleInRadians / 2.0f )
    {
        discard;
    }
    
    float4 color = texLinear2D( tColorMap, sColorMap, texCoord );

    color *= cEmissiveColor * ( distance / cProgress ) * cGlowAmount * cGlowFactor;

#if USE_PROJECTED_POS && USE_SOFT_BLEND
    color.a *= saturate( pow( abs( 1.0f - ( 2.0 * localPos.y ) ), 3 ) );
#endif

    Out.Color = color;
    return Out;
}


