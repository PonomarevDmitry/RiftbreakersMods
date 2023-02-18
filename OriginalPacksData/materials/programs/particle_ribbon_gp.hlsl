cbuffer GPConstantBuffer
{
    matrix cWorldViewProj;

    float3 cCameraPos;
};

struct VS_OUTPUT
{
    float4  Position    : SV_POSITION;
    float4  Color       : COLOR;
    float4  TexCoord    : TEXCOORD0;
    float   Width       : TEXCOORD1;
};

struct GS_OUTPUT
{
    float4  Position    : SV_POSITION;
    float2  TexCoord    : TEXCOORD0;
    float4  Color       : TEXCOORD1;
#if USE_FOG
    float4  ProjPos     : TEXCOORD4;
#endif
};

[maxvertexcount(4)]
void mainGP( lineadj VS_OUTPUT In[ 4 ], inout TriangleStream<GS_OUTPUT> stream )
{
    // In[ 0 ] - prev
    // In[ 1 ] - start
    // In[ 2 ] - end
    // In[ 3 ] - next

    // 3 ---- 1
    // |      |
    // 2 ---- 0

    float3 tangent1 = normalize( In[ 2 ].Position.xyz - In[ 0 ].Position.xyz );
    float3 tangent2 = normalize( In[ 3 ].Position.xyz - In[ 1 ].Position.xyz );

    float3 dir1 = normalize( cCameraPos - In[ 1 ].Position.xyz );
    float3 dir2 = normalize( cCameraPos - In[ 2 ].Position.xyz );
    
    float3 normal1 = cross( tangent1, dir1 ) * In[ 1 ].Width * 0.5;
    float3 normal2 = cross( tangent2, dir2 ) * In[ 2 ].Width * 0.5;

    GS_OUTPUT Out[ 4 ];
    Out[ 0 ].Position = mul( cWorldViewProj, float4(In[ 1 ].Position - normal1, 1.0) );
    Out[ 0 ].TexCoord = In[ 1 ].TexCoord.xy;
    Out[ 0 ].Color = In[ 1 ].Color;
#if USE_FOG
    Out[ 0 ].ProjPos = Out[ 0 ].Position;
#endif

    Out[ 1 ].Position = mul( cWorldViewProj, float4(In[ 1 ].Position + normal1, 1.0) );
    Out[ 1 ].TexCoord = In[ 1 ].TexCoord.zw;
    Out[ 1 ].Color = In[ 1 ].Color;
#if USE_FOG
    Out[ 1 ].ProjPos = Out[ 1 ].Position;
#endif

    Out[ 2 ].Position = mul( cWorldViewProj, float4(In[ 2 ].Position - normal2, 1.0) );
    Out[ 2 ].TexCoord = In[ 2 ].TexCoord.xy;
    Out[ 2 ].Color = In[ 2 ].Color;
#if USE_FOG
    Out[ 2 ].ProjPos = Out[ 2 ].Position;
#endif

    Out[ 3 ].Position = mul( cWorldViewProj, float4(In[ 2 ].Position + normal2, 1.0) );
    Out[ 3 ].TexCoord = In[ 2 ].TexCoord.zw;
    Out[ 3 ].Color = In[ 2 ].Color;
#if USE_FOG
    Out[ 3 ].ProjPos = Out[ 3 ].Position;
#endif

    stream.Append( Out[ 0 ] );
    stream.Append( Out[ 1 ] );
    stream.Append( Out[ 2 ] );
    stream.Append( Out[ 3 ] );

    stream.RestartStrip();
}
