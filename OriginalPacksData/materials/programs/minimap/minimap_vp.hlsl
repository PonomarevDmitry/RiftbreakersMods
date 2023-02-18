struct VS_INPUT
{
    float3  Position    : POSITION;
    float4  Color       : TEXCOORD0;
    float2  Size        : TEXCOORD1;
    float   Rotation    : TEXCOORD2;
};

struct VS_OUTPUT
{
    float4  Position    : SV_POSITION;
    float4  Color       : TEXCOORD0;
    float2  Size        : TEXCOORD1;
    float   Rotation    : TEXCOORD2;
};

VS_OUTPUT mainVP( VS_INPUT In )
{
    VS_OUTPUT Out;
    Out.Position = float4( In.Position.xyz, 1.0 );
    Out.Color = In.Color;
    Out.Size = In.Size;
    Out.Rotation = In.Rotation;

    return Out;
}