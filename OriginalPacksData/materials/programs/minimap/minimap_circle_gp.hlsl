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

[maxvertexcount(128)]
void mainGP( point VS_OUTPUT In[1], inout TriangleStream<GS_OUTPUT> stream )
{
    const int CIRCLE_SEGMENTS = 21;

    const float ANGLE_STEP = 3.14159265 * 2.0 / CIRCLE_SEGMENTS;
    [unroll]
    for( int i = 0; i < CIRCLE_SEGMENTS; ++i )
    {
        float angle = i * ANGLE_STEP;

        GS_OUTPUT Out = (GS_OUTPUT)0;
        Out.Color = In[0].Color;
        Out.Position = In[0].Position;
        Out.Position.x += cos( angle + ANGLE_STEP ) * In[0].Size.x;
        Out.Position.z += sin( angle + ANGLE_STEP ) * In[0].Size.x;
        Out.Position = mul( cViewProj, Out.Position );
        stream.Append(Out);

        Out.Position = In[0].Position;
        Out.Color = In[0].Color;
        Out.Position.x += cos( angle + ANGLE_STEP ) * In[0].Size.y;
        Out.Position.z += sin( angle + ANGLE_STEP ) * In[0].Size.y;
        Out.Position = mul( cViewProj, Out.Position );
        stream.Append(Out);

        Out.Position = In[0].Position;
        Out.Color = In[0].Color;
        Out.Position.x += cos( angle ) * In[0].Size.y;
        Out.Position.z += sin( angle ) * In[0].Size.y;
        Out.Position = mul( cViewProj, Out.Position );
        stream.Append(Out);

        if ( In[0].Size.x > 0.01f )
        {
            stream.RestartStrip();

            Out.Color = In[0].Color;
            Out.Position = In[0].Position;
            Out.Position.x += cos( angle ) * In[0].Size.x;
            Out.Position.z += sin( angle ) * In[0].Size.x;
            Out.Position = mul( cViewProj, Out.Position );
            stream.Append(Out);

            Out.Color = In[0].Color;
            Out.Position = In[0].Position;
            Out.Position.x += cos( angle + ANGLE_STEP ) * In[0].Size.x;
            Out.Position.z += sin( angle + ANGLE_STEP ) * In[0].Size.x;
            Out.Position = mul( cViewProj, Out.Position );
            stream.Append(Out);

            Out.Position = In[0].Position;
            Out.Color = In[0].Color;
            Out.Position.x += cos( angle ) * In[0].Size.y;
            Out.Position.z += sin( angle ) * In[0].Size.y;
            Out.Position = mul( cViewProj, Out.Position );
            stream.Append(Out);
        }

        stream.RestartStrip();
    }
}