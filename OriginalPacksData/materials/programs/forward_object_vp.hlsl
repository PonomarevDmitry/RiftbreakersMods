#define MAX_BONE_MATRICES 48

cbuffer VPConstantBuffer : register(b0)
{
#if USE_HW_SKINNING
    float3x4  cWorld3x4Array[ MAX_BONE_MATRICES ];
#else
    matrix    cWorld;
#endif
    matrix    cViewProj;
#if USE_FRESNEL
    float3    cCameraWorldPos;
#endif
};

struct VS_INPUT
{
    float4    Position         : POSITION;
#if USE_NORMAL
    float3    Normal           : NORMAL;
#endif
#if USE_TANGENT
    float4    Tangent          : TANGENT0;
#endif
#if USE_TEXTURE
    float2    TexCoord         : TEXCOORD0;
#endif
#if USE_COLOR
    float4    Color            : COLOR;
#endif
#if USE_HW_SKINNING
    float4    BlendWeights     : BLENDWEIGHT;
    int4      BlendIndices     : BLENDINDICES;
#endif
};

struct VS_OUTPUT
{
    float4    Position         : SV_POSITION;
#if USE_TEXTURE
    float2    TexCoord         : TEXCOORD0;
#endif
#if USE_COLOR
    float4    Color            : TEXCOORD1;
#endif
#if USE_NORMAL
    float3    WorldNormal      : TEXCOORD2;
#endif
#if USE_FRESNEL
    float3    WorldEyeDir      : TEXCOORD3;
#endif
#if USE_PROJ_POS
    float4    ProjPos          : TEXCOORD4;
#endif
#if USE_WORLD_POS
    float3    WorldPos         : TEXCOORD5;
#endif
#if USE_TANGENT
    float3    WorldTangent     : TEXCOORD6;
    float3    WorldBiNormal    : TEXCOORD7;
#endif
};

VS_OUTPUT mainVP( VS_INPUT In )
{
    VS_OUTPUT Output;

#if USE_HW_SKINNING
    float3x4 cWorld = In.BlendWeights.x * cWorld3x4Array[ In.BlendIndices.x ];
    cWorld += In.BlendWeights.y * cWorld3x4Array[ In.BlendIndices.y ];
    cWorld += In.BlendWeights.z * cWorld3x4Array[ In.BlendIndices.z ];
    cWorld += In.BlendWeights.w * cWorld3x4Array[ In.BlendIndices.w ];
#endif

    float4 worldPos = float4( mul( cWorld, In.Position ).xyz, 1.0f );

#if USE_FRESNEL
    Output.WorldEyeDir = normalize( worldPos.xyz - cCameraWorldPos );
#endif

#if USE_NORMAL
    Output.WorldNormal = normalize( mul( cWorld, float4( In.Normal, 0.0f ) ).xyz );
#endif

#if USE_TANGENT
    float4 tangent = ( In.Tangent.w == 0.0f ) ? float4( 1.0f, 0.0f, 0.0f, 1.0f ) : In.Tangent; // fix for old 3dsMax exports
    Output.WorldTangent = normalize( mul( cWorld, float4( tangent.xyz, 0.0f ) ).xyz );
    Output.WorldBiNormal = cross( Output.WorldTangent, Output.WorldNormal ) * tangent.w; 
#endif

#if USE_WORLD_POS
    Output.WorldPos = worldPos.xyz;
#endif 

    Output.Position = mul( cViewProj, worldPos );

#if USE_PROJ_POS
    Output.ProjPos = Output.Position;
#endif

#if USE_COLOR
    Output.Color = In.Color;
#endif

#if USE_TEXTURE
    Output.TexCoord = In.TexCoord;
#endif

    return Output;
}
