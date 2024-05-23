#if WORLD_POS
cbuffer CSConstantBuffer : register(b0)
{
    matrix cInvViewProjMatrix;
};
#endif

struct VS_OUTPUT
{
    float4  Position    : SV_POSITION;
    float2  TexCoord    : TEXCOORD0;
#if WORLD_POS
    float4  WorldPos    : TEXCOORD1;
#endif
};

VS_OUTPUT mainVP( uint id : SV_VERTEXID )
{
    VS_OUTPUT Out;
    
    Out.Position.x = (float)(id / 2) * 4.0 - 1.0;
    Out.Position.y = (float)(id % 2) * 4.0 - 1.0;
    Out.Position.z = 0.0;
    Out.Position.w = 1.0;

    Out.TexCoord.x = (float)(id / 2) * 2.0;
    Out.TexCoord.y = 1.0 - (float)(id % 2) * 2.0;

#if WORLD_POS
    Out.WorldPos = mul( cInvViewProjMatrix, Out.Position );
#endif

    return Out;
}