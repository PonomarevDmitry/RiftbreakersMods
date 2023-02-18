cbuffer GPConstantBuffer : register(b0)
{
    matrix  cWorldViewProj;
    float2  cQuadHalfSize;
}

struct VS_OUTPUT
{
    float4 Position : SV_POSITION;
};

struct GS_OUTPUT
{
    float4 Position : SV_POSITION;
    float4 WorldPos : TEXCOORD1;
};

[maxvertexcount(4)]
void mainGP( point VS_OUTPUT In[1], inout TriangleStream<GS_OUTPUT> stream )
{

    const float2 offsets[4] =
    {
        float2(2.0 * cQuadHalfSize.x, 0),
        float2(0, 0),
        float2(2.0 * cQuadHalfSize.x, 2.0 *cQuadHalfSize.y),
        float2(0,2.0 * cQuadHalfSize.y)
    };
    
    [unroll]
    for (uint i = 0; i < 4; i++)
    {
	    GS_OUTPUT Out = (GS_OUTPUT)0;

        Out.Position = In[0].Position;
        Out.Position.x += offsets[i].x;
        Out.Position.z += offsets[i].y;

        Out.WorldPos = Out.Position;
        Out.Position = mul( cWorldViewProj, Out.Position );
        stream.Append(Out);
    }
    
    stream.RestartStrip();
}