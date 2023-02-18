#define MAX_BONE_MATRICES 10

cbuffer VPConstantBuffer : register(b0)
{
#if USE_HW_SKINNING
    float3x4 cWorld3x4Array[ MAX_BONE_MATRICES ];
    matrix   cViewProj;
#else
    matrix   cWorld;
    matrix   cWorldViewProj;
#endif
    float3   cWorldEyePosition;
};

struct VS_INPUT
{
    float4 Position     : POSITION;
    float3 Normal       : NORMAL;
    float2 TexCoord     : TEXCOORD0;
#if USE_HW_SKINNING
    float4 BlendWeights : BLENDWEIGHT;
    int4  BlendIndices : BLENDINDICES;
#endif
};

struct VS_OUTPUT
{
    float4 Position       : SV_POSITION;
    float2 TexCoord       : TEXCOORD0;
    float3 WorldNormal    : TEXCOORD1;
    float3 WorldEyeDir    : TEXCOORD2;
};

VS_OUTPUT mainVP( VS_INPUT In )
{
    VS_OUTPUT Output;

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
     float3 worldNormal = mul( world, float4( In.Normal, 0.0f ) );
     Output.Position = mul( cViewProj, worldPos );
#else
     Output.Position = mul( cWorldViewProj, In.Position );
     float3 worldPos = mul( cWorld, In.Position ).xyz;
     float3 worldNormal = normalize( mul( cWorld, float4( In.Normal, 0 ) ).xyz );
#endif

    Output.WorldEyeDir = normalize( worldPos.xyz - cWorldEyePosition);
    Output.WorldNormal = normalize( worldNormal );
    Output.TexCoord = In.TexCoord;

    return Output;
}
