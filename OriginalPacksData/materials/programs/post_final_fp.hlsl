#include "materials/programs/utils.hlsl"

struct VS_OUTPUT
{
    float4  Position    : SV_POSITION;
    float2  TexCoord    : TEXCOORD0;
};

struct PS_OUTPUT
{
    float4  Color0      : SV_TARGET0;
};

cbuffer FPConstantBuffer : register(b0)
{
#if POSTPROCESS 
    float4          cPostParams;        // x - desaturation, y - brightness, z - contrast, w - red tone
#endif
#if FOG
    matrix          cInvProjMatrix;
    float4          cFogParams;
    float4          cFogColour;
#endif
};

    Texture2D       tIlluminance       : register( t0 );
    SamplerState    sIlluminance       : register( s0 );
#if SSAO
    Texture2D       tOcclusion         : register( t1 );
    SamplerState    sOcclusion         : register( s1 );
#endif
#if FOG
    Texture2D       tDepth             : register( t2 );
    SamplerState    sDepth             : register( s2 );
#endif

PS_OUTPUT mainFP( VS_OUTPUT In ) 
{
    PS_OUTPUT output;

    output.Color0 = float4( tIlluminance.Sample( sIlluminance, In.TexCoord ).xyz, 1.0f );

#if SSAO     
    output.Color0.xyz *= tOcclusion.Sample( sOcclusion, In.TexCoord ).x;
#endif 

#if FOG
    float x = In.TexCoord.x * 2.0f - 1.0f;
    float y = (1.0f - In.TexCoord.y) * 2.0f - 1.0f;
    float z = tDepth.Sample( sDepth, In.TexCoord ).r;

    float4 projPos = float4( x, y, z, 1.0f );
    float4 viewPos = mul( cInvProjMatrix, projPos );
    viewPos = viewPos.xyzw / viewPos.w;
    addFog( output.Color0.rgb, cFogColour.rgb, -viewPos.z, cFogParams );
#endif

#if POSTPROCESS
    float3 greyscale = dot( output.Color0.xyz, float3( 0.3f, 0.59f, 0.11f ) ).xxx; 
    greyscale.yz *= 1.0f - cPostParams.w;
    output.Color0.xyz = lerp( output.Color0.xyz, greyscale, cPostParams.x );
    output.Color0.xyz *= cPostParams.z;
    output.Color0.xyz = max( float3(0.0f, 0.0f, 0.0f), output.Color0.xyz + cPostParams.yyy ); 
#endif

    return output;
}
