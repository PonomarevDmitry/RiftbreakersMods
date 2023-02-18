cbuffer VPConstantBuffer : register(b0)
{
    matrix   cWorld;
    matrix   cWorldView;
    matrix   cViewProj;
    matrix   cWorldViewProj;
    matrix   cInvViewProj;

    matrix   cView;
    float3   cWorldEyePosition; 
    float    cNoiseChange;
    float4   cNoiseParams;
    float2   cGridStep;
    float2   cWaterFlowDirection;
    float    cWaterLevel;
};

struct VS_INPUT
{
    float2 Position     : POSITION;
};

struct VS_OUTPUT
{
    float4      Position      : SV_POSITION;
    float2      UV0           : TEXCOORD0;
    float3      ViewPos       : TEXCOORD1;
    float3      Normal        : TEXCOORD2;
    float3      Tangent       : TEXCOORD3;
    float3      BiNormal      : TEXCOORD4;

    float4      ProjPos       : TEXCOORD5;
    float3      WorldEyeDir   : TEXCOORD6;
};

inline float3 Transform( float3 pos )
{
    float fInvW = 1.0f / ( cInvViewProj[ 3 ][ 0 ] * pos.x + cInvViewProj[ 3 ][ 1 ] * pos.y + cInvViewProj[ 3 ][ 2 ] * pos.z + cInvViewProj[ 3 ][ 3 ] );
    return mul(cInvViewProj, float4(pos, 1.0)) * fInvW;
}

inline float3 GetProjectedPos( float2 uv )
{
    float nx = ( 2.0f * uv.x ) - 1.0f;
    float ny = 1.0f - ( 2.0f * uv.y );

    float3 rayOrigin = Transform( float3( nx, ny, -1.f ) );
    float3 rayTarget = Transform( float3( nx, ny, 0.0f ) );

    float3 rayDirection = normalize( rayTarget - rayOrigin );

    float3 normal = float3( 0.0, 1.0, 0.0 );

    float denom = dot( normal, rayDirection );
    float nom = dot( normal, rayOrigin );
    float t = -( nom / denom );

    return rayOrigin + t * rayDirection;
}

VS_OUTPUT water_vp(VS_INPUT In)
{
    VS_OUTPUT Out;

    float4 position = float4( GetProjectedPos( In.Position ), 1.0);
    position.y = cWaterLevel;
    Out.Position = mul( cViewProj, position );

    // water noise tiling
    Out.UV0.xy = position.xz / 4.0f;

    float3 normal = float3( 0.0, 1.0, 0.0 );
    float3 tangent = float3( 1.0, 0.0, 0.0 );

    float3 worldNormal = normalize( mul( cWorld, float4( normal, 0.0 ) ).xyz );

    Out.Normal = normalize( mul( cWorldView, float4( normal, 0 ) ).xyz );
    Out.Tangent = normalize( mul( cWorldView, float4( tangent, 0 ) ).xyz );
    Out.BiNormal = cross( Out.Tangent, Out.Normal );

    Out.WorldEyeDir = normalize( position.xyz - cWorldEyePosition); 
    Out.ViewPos = mul( cView, position );
    Out.ProjPos = Out.Position;

    Out.UV0.xy = Out.UV0.xy / cNoiseParams.x + cNoiseChange * cNoiseParams.y * cWaterFlowDirection;
    Out.UV0.xy *= cNoiseParams.z;

    return Out;
}
