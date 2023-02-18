struct VS_OUTPUT
{
    float4      Position      : SV_POSITION;
};

struct PS_OUTPUT
{
    float4      GBuffer1      : SV_TARGET0; // Octahedron Normal (xy), Roughness (z), Metalness (w)
};

PS_OUTPUT water_stencil_fp( VS_OUTPUT In )
{
    PS_OUTPUT Out;
    Out.GBuffer1.x = 1.0;
    Out.GBuffer1.y = 1.0;
    Out.GBuffer1.z = 0.7;
    Out.GBuffer1.w = 1.0;
    return Out;
}
