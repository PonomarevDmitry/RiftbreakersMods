cbuffer VPConstantBuffer : register(b0)
{
    float4  cViewportSize;
};

struct VS_OUTPUT
{
    float4  Position    : SV_POSITION;
    float4  TexCoord0   : TEXCOORD0;
    float4  TexCoord1   : TEXCOORD1;
};

VS_OUTPUT mainVP( uint id : SV_VERTEXID )
{
    VS_OUTPUT Out;
    
    Out.Position.x = (float)(id / 2) * 4.0 - 1.0;
    Out.Position.y = (float)(id % 2) * 4.0 - 1.0;
    Out.Position.z = 0.0;
    Out.Position.w = 1.0;

    float2 texCord = float2( (float)(id / 2) * 2.0, 1.0 - (float)(id % 2) * 2.0 );
    float2 offset = cViewportSize.zw * 0.5;

    Out.TexCoord0.xy = texCord + offset * float2(-1, -1);
    Out.TexCoord0.zw = texCord + offset * float2( 1, -1);
    Out.TexCoord1.xy = texCord + offset * float2(-1,  1);
    Out.TexCoord1.zw = texCord + offset * float2( 1,  1);

    return Out;
}
