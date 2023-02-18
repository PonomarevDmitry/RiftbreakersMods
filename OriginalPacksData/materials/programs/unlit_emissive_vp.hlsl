#define MAX_BONE_MATRICES 48

cbuffer VPConstantBuffer : register(b0)
{
#if USE_HW_SKINNING
    float3x4 cWorld3x4Array[ MAX_BONE_MATRICES ];
    matrix   cViewProj;
#else
    matrix   cWorldViewProj;
#endif
#if USE_FRESNEL
    matrix   cWorld;
    float3   cWorldEyePosition;
#endif
};

struct VS_INPUT
{
    float4 Position         : POSITION;
#if USE_FRESNEL
    float3 Normal           : NORMAL;
#endif
    float2 TexCoord         : TEXCOORD0;
#if USE_COLOR
    float4 Color            : COLOR;
#endif
#if USE_HW_SKINNING
    float4 BlendWeights     : BLENDWEIGHT;
    int4  BlendIndices     : BLENDINDICES;
#endif
};

struct VS_OUTPUT
{
    float4 Position         : SV_POSITION;
    float2 TexCoord         : TEXCOORD0;
#if USE_COLOR
    float4 Color            : TEXCOORD1;
#endif
#if USE_FRESNEL
    float3 WorldNormal      : TEXCOORD2;
    float3 WorldEyeDir      : TEXCOORD3;
#endif
#if USE_FOG
    float4  ProjPos         : TEXCOORD4;
#endif
#if USE_WORLD_POS
    float3  WorldPos        : TEXCOORD5;
#endif
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
     #if USE_FRESNEL
     float3 worldNormal = mul( world, float4( In.Normal, 0.0f ) );
     #endif
     float4 worldPos = float4( mul( world, In.Position ), 1.0f );
     Output.Position = mul( cViewProj, worldPos );
#else
     Output.Position = mul( cWorldViewProj, In.Position );
     #if USE_FRESNEL
     float3 worldPos = mul( cWorld, In.Position ).xyz;
     float3 worldNormal = normalize( mul( cWorld, float4( In.Normal, 0 ) ).xyz );
     #endif
#endif

#if USE_WORLD_POS
    Output.WorldPos = worldPos.xyz;
#endif

#if USE_FOG
    Output.ProjPos = Output.Position;
#endif

#if USE_COLOR
    Output.Color = In.Color;
#endif

#if USE_FRESNEL
    Output.WorldNormal = normalize( worldNormal );
    Output.WorldEyeDir = normalize( worldPos.xyz - cWorldEyePosition);
#endif
    Output.TexCoord = In.TexCoord;

    return Output;
}
