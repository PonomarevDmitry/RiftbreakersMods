struct VS_INPUT
{
    float3  Position    : POSITION;
    float4  Color       : COLOR;
    float4  TexCoords   : TEXCOORD0;
    float4  DirRot      : TEXCOORD1;
    float2  Size        : TEXCOORD2;
    float4  Origin      : TEXCOORD3;
    float3  CommonUp    : TEXCOORD4;
    float3  CommonDir   : TEXCOORD5;
};

struct VS_OUTPUT
{
    float4  Position    : SV_POSITION;
    float4  Color       : COLOR;
    float4  TexCoords   : TEXCOORD0;
    float4  DirRot      : TEXCOORD1;
    float2  Size        : TEXCOORD2;
    float4  Origin      : TEXCOORD3;
    float3  CommonUp    : TEXCOORD4;
    float3  CommonDir   : TEXCOORD5;
};

VS_OUTPUT mainVP( VS_INPUT In )
{
    VS_OUTPUT Out;
    Out.Position = float4( In.Position, 1.0 );
    Out.Color = In.Color;
    Out.TexCoords = In.TexCoords;
    Out.DirRot = In.DirRot;
    Out.Size = In.Size;
    Out.Origin = In.Origin;
    Out.CommonUp = In.CommonUp;
    Out.CommonDir = In.CommonDir;
    return Out;
}