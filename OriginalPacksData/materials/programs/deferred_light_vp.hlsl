#if FULLSCREEN 
#else
cbuffer VPConstantBuffer : register(b0)
{
    matrix cWorldViewProj;
};

struct VS_INPUT
{
    float4 Position : POSITION;
};
#endif

struct VS_OUTPUT
{
    float4 Position : SV_POSITION;
    float4 TexCoord : TEXCOORD0;
};

#if FULLSCREEN
VS_OUTPUT mainVP( uint id : SV_VERTEXID )
{
    VS_OUTPUT output;
    
    output.Position.x = (float)(id / 2) * 4.0 - 1.0;
    output.Position.y = (float)(id % 2) * 4.0 - 1.0;
    output.Position.z = 0.0;
    output.Position.w = 1.0;

    output.TexCoord.x = (float)(id / 2) * 2.0;
    output.TexCoord.y = 1.0 - (float)(id % 2) * 2.0;
    output.TexCoord.wz = 1.0;

    return output;
}
#else
VS_OUTPUT mainVP( VS_INPUT In )
{
    VS_OUTPUT output;
    output.Position = mul( cWorldViewProj, In.Position );
    output.TexCoord = output.Position.xyzw;
    return output;
}
#endif