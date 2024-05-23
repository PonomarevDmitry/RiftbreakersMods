struct VS_OUTPUT
{
    float4    Position         : SV_POSITION;
    float2    TexCoord         : TEXCOORD0;
};

struct PS_OUTPUT
{
    float     Color            : SV_TARGET0;
};

PS_OUTPUT mainFP( VS_OUTPUT In ) 
{
    PS_OUTPUT Out;
    Out.Color = 1.0f;
    return Out;
}
