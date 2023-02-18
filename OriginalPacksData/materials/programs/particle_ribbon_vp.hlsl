struct VS_INPUT
{
    float3  Position    : POSITION;
    float4  Color       : COLOR;
    float4  TexCoord    : TEXCOORD0;
    float   Width       : TEXCOORD1;
};

struct VS_OUTPUT
{
    float4  Position    : SV_POSITION;
    float4  Color       : COLOR;
    float4  TexCoord    : TEXCOORD0;
    float   Width       : TEXCOORD1;
};

VS_OUTPUT mainVP( VS_INPUT In )
{
    VS_OUTPUT Out;
    Out.Position = float4( In.Position, 1.0 );
    Out.Color = In.Color;
    Out.TexCoord = In.TexCoord;
    Out.Width = In.Width;
    return Out;
}
