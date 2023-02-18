#include "materials/programs/minimap/minimap_quad_gp.hlsl"

struct PS_OUTPUT
{
    float4      Color       : SV_TARGET0;
};

PS_OUTPUT mainFP( GS_OUTPUT In ) 
{
    PS_OUTPUT Out;
    Out.Color = In.Color;
    return Out;
}
