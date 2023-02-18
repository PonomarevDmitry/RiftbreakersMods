#define MAX_BONE_MATRICES 48

cbuffer VPConstantBuffer : register(b0)
{
#if USE_HW_SKINNING
    matrix   cViewProj;
    float3x4 cWorld3x4Array[ MAX_BONE_MATRICES ];
#else
    matrix   cWorld;
    matrix   cViewProj;
#endif
#if USE_FRESNEL
    float3   cWorldEyePosition;
#endif
};

struct VS_INPUT
{
    float4  Position        : POSITION;
#if USE_FRESNEL
    float3  Normal          : NORMAL;
#endif
    float2  TexCoord        : TEXCOORD0;
#if USE_COLOR
    float4  Color           : COLOR;
#endif
#if USE_HW_SKINNING
    float4  BlendWeights    : BLENDWEIGHT;
    int4    BlendIndices    : BLENDINDICES;
#endif
};

struct VS_OUTPUT
{
    float4  Position        : SV_POSITION;
    float2  TexCoord        : TEXCOORD0;
#if USE_COLOR
    float4  Color           : TEXCOORD1;
#endif
#if USE_FRESNEL
    float3 WorldEyeDir      : TEXCOORD2;
    float3 WorldNormal      : TEXCOORD3;
#endif
};

VS_OUTPUT mainVP( VS_INPUT In )
{
    VS_OUTPUT Out;

#if USE_HW_SKINNING
    float last = 1.0f;
    float3x4 world = float3x4( 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0 );

    for (int i = 0; i < 4; ++i)
    {
        float weight = ( i == 3 ) ? last : In.BlendWeights[ i ];
        world += cWorld3x4Array[ In.BlendIndices[i] ] * weight;
        last -= In.BlendWeights[ i ];
    }
    float4 worldPos = float4( mul( world, In.Position ), 1.0f );
#if USE_FRESNEL
    Out.WorldNormal = normalize( mul( world, float4( In.Normal, 0 ) ).xyz );
    Out.WorldEyeDir = normalize( worldPos.xyz - cWorldEyePosition );
#endif
    Out.Position = mul( cViewProj, worldPos );
#else
	float4 worldPos = mul( cWorld, In.Position );
    Out.Position = mul( cViewProj, worldPos );
#if USE_FRESNEL
    Out.WorldNormal = normalize( mul( cWorld, float4( In.Normal, 0 ) ).xyz );
    Out.WorldEyeDir = normalize( worldPos.xyz - cWorldEyePosition );
#endif
#endif

    Out.TexCoord = In.TexCoord;

#if USE_COLOR
    Out.Color = In.Color;
#endif

    return Out;
}
