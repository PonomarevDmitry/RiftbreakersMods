#include "materials/programs/utils.hlsl"
#include "materials/programs/pack_ops.hlsl"

struct VS_OUTPUT
{
    float4 Position     : SV_POSITION;
    float2 UV0          : TEXCOORD0;
};

Texture2D       tNormal   : register( t0 );
SamplerState    sNormal   : register( s0 );

float3 mainFP( VS_OUTPUT In ) : SV_TARGET
{
    float2 rawNormal = tNormal.Sample( sNormal, In.UV0 ).xy; 
    return unpack_normal_from_2ubyte_xy( rawNormal.xy );
}


