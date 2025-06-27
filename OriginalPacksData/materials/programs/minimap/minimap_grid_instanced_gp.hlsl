struct VS_OUTPUT
{
    float4  Position    : SV_POSITION;
    int    Flags        : TEXCOORD0;
};

cbuffer GPConstantBuffer
{
    matrix  cViewProj;
    int     cExpandFlag;
}

struct GS_OUTPUT
{
    float4 Position : SV_POSITION;
    float4 Color    : TEXCOORD0;
};

[maxvertexcount(4)]
void mainGP( point VS_OUTPUT In[1], inout TriangleStream<GS_OUTPUT> stream )
{
    if ( (In[0].Flags & cExpandFlag) != 0 )
    {
        const float2 posOffsets[4] =
        {
            float2( 2.0,  -2.0),
            float2(-2.0,  -2.0),
            float2( 2.0,   2.0),
            float2(-2.0,   2.0)
        };

        [unroll]
        for (uint i = 0; i < 4; i++)
        {
            GS_OUTPUT Out = (GS_OUTPUT)0;
            Out.Position = In[0].Position;
            Out.Position.x += posOffsets[i].x;// * cos( In[0].Rotation );
            Out.Position.z += posOffsets[i].y;// * sin( In[0].Rotation );
            Out.Position = mul( cViewProj, Out.Position );

            stream.Append(Out);
        }

        stream.RestartStrip();
    }
}