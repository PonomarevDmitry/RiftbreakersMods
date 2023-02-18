#include "materials/programs/minimap/minimap_vp.hlsl"

cbuffer GPConstantBuffer : register(b0)
{
    matrix  cViewProj;
}

struct GS_OUTPUT
{
    float4 Position : SV_POSITION;
    float4 Color    : TEXCOORD0;
};

[maxvertexcount(4)]
void mainGP( point VS_OUTPUT In[1], inout TriangleStream<GS_OUTPUT> stream )
{
    const float2 posOffsets[4] =
    {
        float2( In[0].Size.x,  -In[0].Size.y),
        float2(-In[0].Size.x,  -In[0].Size.y),
        float2( In[0].Size.x,   In[0].Size.y),
        float2(-In[0].Size.x,   In[0].Size.y)
    };

    [unroll]
    for (uint i = 0; i < 4; i++)
    {
        GS_OUTPUT Out = (GS_OUTPUT)0;
        Out.Color = In[0].Color;
        Out.Position = In[0].Position;
        Out.Position.x += posOffsets[i].x;// * cos( In[0].Rotation );
        Out.Position.z += posOffsets[i].y;// * sin( In[0].Rotation );
        Out.Position = mul( cViewProj, Out.Position );

        stream.Append(Out);
    }

    stream.RestartStrip();
}