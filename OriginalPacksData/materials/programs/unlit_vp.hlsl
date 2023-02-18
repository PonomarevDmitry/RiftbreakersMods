#define MAX_BONE_MATRICES 48

cbuffer VPConstantBuffer : register(b0)
{
#if USE_UNIFORM
    float4  cColor;
#endif
#if USE_HW_SKINNING
    matrix  cViewProj;
    float3x4  cWorld3x4Array[ MAX_BONE_MATRICES ];
#else
#   if USE_ENVIRONMENT
    matrix  cWorld;
#   endif
    matrix  cWorldViewProj;
#endif
};

struct VS_INPUT
{
    float3  Position      : POSITION;
#if USE_ENVIRONMENT
    float3  Normal        : NORMAL;
#endif
#if USE_TEXTURE || USE_2_TEXTURE
    float2  TexCoord      : TEXCOORD0;
#endif
#if USE_COLOR
    float4  Color         : COLOR;
#endif
#if USE_HW_SKINNING
    float4  BlendWeights  : BLENDWEIGHT;
    int4    BlendIndices  : BLENDINDICES;
#endif
};

struct VS_OUTPUT
{
    float4  Position    : SV_POSITION;
#if USE_TEXTURE || USE_2_TEXTURE
    float2  TexCoord    : TEXCOORD0;
#endif
#if USE_COLOR || USE_UNIFORM
    float4  Color       : TEXCOORD1;
#endif
#if USE_ENVIRONMENT
    float3  WorldPos    : TEXCOORD2;
    float3  WorldNor    : TEXCOORD3;
#endif
#if USE_FOG
    float4  ProjPos     : TEXCOORD4;
#endif
};

VS_OUTPUT mainVP( VS_INPUT In )
{
    VS_OUTPUT Out;

    float4 position = float4( In.Position, 1.0 );

#if USE_HW_SKINNING
    float last = 1.0f;
    float3x4 world = float3x4( 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0 );

    for (int i = 0; i < 4; ++i)
    {
        float weight = ( i == 3 ) ? last : In.BlendWeights[ i ];
        world += cWorld3x4Array[ In.BlendIndices[i] ] * weight;
        last -= In.BlendWeights[ i ];
    }
    float4 worldPos = float4( mul( world, position ), 1.0f );
    Out.Position = mul( cViewProj, worldPos );
#   if USE_ENVIRONMENT
    Out.WorldPos = worldPos.xyz;
    Out.WorldNor = mul( world, float4( In.Normal, 0.0f ) ).xyz;
    Out.WorldNor = normalize( Out.WorldNor );
#   endif
#else
    Out.Position = mul( cWorldViewProj, position );
#   if USE_ENVIRONMENT
    Out.WorldPos = mul( cWorld, position ).xyz;
    Out.WorldNor = mul( cWorld, float4( In.Normal, 0.0f ) ).xyz;
    Out.WorldNor = normalize( Out.WorldNor );
#   endif
#endif

#if USE_FOG
    Out.ProjPos = Out.Position;
#endif

#if USE_COLOR
    Out.Color = In.Color;
#endif

#if USE_UNIFORM
    Out.Color = cColor;
#endif

#if USE_TEXTURE || USE_2_TEXTURE
    Out.TexCoord = In.TexCoord;
#endif
    return Out;
}