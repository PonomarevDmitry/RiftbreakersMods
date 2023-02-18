struct VS_INPUT
{
    float4  Position    : POSITION;
};

struct VS_OUTPUT
{
    float4  Position    : SV_POSITION;
};

VS_OUTPUT mainVP( VS_INPUT In )
{
    VS_OUTPUT Out;
    Out.Position = float4(In.Position.xyz, 1.0 );
	return Out;
}
