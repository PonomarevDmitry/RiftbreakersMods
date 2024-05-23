cbuffer GPConstantBuffer
{
    matrix  cWorld;
    matrix  cViewProj;
    float3  cCameraPos;
    float3  cCameraUp;
#if !ACCURATE_FACING && ( BBT_ORIENTED_COMMON || BBT_ORIENTED_SELF )
    float3  cCameraDir;
#endif
    float3  cCameraRight;
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

struct GS_OUTPUT
{
    float4  Position    : SV_POSITION;
    float2  TexCoord    : TEXCOORD0;
    float4  Color       : TEXCOORD1;
#if USE_FOG
    float4  ProjPos     : TEXCOORD4;
#endif
};

#if BBT_POINT && !ACCURATE_FACING
inline void getBillboardAxes( out float3 camX, out float3 camY )
#else
inline void getBillboardAxes( in VS_OUTPUT In, out float3 camX, out float3 camY )
#endif
{
#if ACCURATE_FACING && ( BBT_POINT || BBT_ORIENTED_COMMON || BBT_ORIENTED_SELF )
    float3 camDir = normalize( In.Position.xyz - cCameraPos );
#elif BBT_ORIENTED_COMMON || BBT_ORIENTED_SELF 
    float3 camDir = cCameraDir;
#endif

#if BBT_POINT

#   if ACCURATE_FACING
    camY = cCameraUp;
    camX = normalize( cross( camDir, camY ) );
    camY = cross( camX, camDir );
#   else
    camX = cCameraRight;
    camY = cCameraUp;
#   endif

#elif BBT_ORIENTED_COMMON

    camY = In.CommonDir;
    camX = normalize( cross( camDir, camY) );
    
#elif BBT_ORIENTED_SELF

    camY = In.DirRot.xyz;
    camX = normalize( cross( camDir, camY) );
    
#elif BBT_PERPENDICULAR_COMMON

    camX = cross( In.CommonUp, In.CommonDir );
    camY = cross( In.CommonDir, camX);

#elif BBT_PERPENDICULAR_SELF

    camX = normalize( cross( In.CommonUp, In.DirRot.xyz ) );
    camY = cross( In.DirRot.xyz, camX );

#endif
}

#if BBR_VERTEX
inline float3x3 rotMatrix( float3 axis, float angle )
{
    float s = sin(angle);
    float c = cos(angle);
    float oc = 1.0 - c;

    return float3x3
    (
        float3( oc * axis.x * axis.x + c,           oc * axis.x * axis.y - axis.z * s,  oc * axis.z * axis.x + axis.y * s ),
        float3( oc * axis.x * axis.y + axis.z * s,  oc * axis.y * axis.y + c,           oc * axis.y * axis.z - axis.x * s ),
        float3( oc * axis.z * axis.x - axis.y * s,  oc * axis.y * axis.z + axis.x * s,  oc * axis.z * axis.z + c )
    );
}
#elif BBR_TEXCOORD
inline float2x2 rotMatrix( float angle )
{
    float s = sin(angle);
    float c = cos(angle);

    return float2x2
    (
        float2( c, -s ),
        float2( s, c )
    );
}
#endif

inline void getBillboardOffsets( VS_OUTPUT In, float3 camX, float3 camY, out float3 offsets[ 4 ] )
{
     float3 left     = camX * ( In.Origin[ 0 ] * In.Size.x );
     float3 right    = camX * ( In.Origin[ 1 ] * In.Size.x );

     float3 top      = camY * ( In.Origin[ 2 ] * In.Size.y );
     float3 bottom   = camY * ( In.Origin[ 3 ] * In.Size.y );

     offsets[0] = right + bottom;
     offsets[1] = right + top;
     offsets[2] = left + bottom;
     offsets[3] = left + top;
}

[maxvertexcount(4)]
void mainGP( point VS_OUTPUT In[ 1 ], inout TriangleStream<GS_OUTPUT> stream )
{
    float3 camX, camY;
#if BBT_POINT && !ACCURATE_FACING
    getBillboardAxes( camX, camY );
#else
    getBillboardAxes( In[ 0 ], camX, camY );
#endif

    float3 offsets[4];
    getBillboardOffsets( In[ 0 ], camX, camY, offsets);

    float2 coords[4] =
    {
        float2( In[ 0 ].TexCoords[ 1 ],  In[ 0 ].TexCoords[ 3 ]), // right-bottom
        float2( In[ 0 ].TexCoords[ 1 ],  In[ 0 ].TexCoords[ 2 ]), // right-top
        float2( In[ 0 ].TexCoords[ 0 ],  In[ 0 ].TexCoords[ 3 ]), // left-bottom
        float2( In[ 0 ].TexCoords[ 0 ],  In[ 0 ].TexCoords[ 2 ])  // left-top
    };

#if BBR_VERTEX
    float3 axis = normalize( cross( offsets[0] - offsets[3], offsets[2] - offsets[1] ) );
    float3x3 rotation = rotMatrix( axis, In[ 0 ].DirRot.w );
#elif BBR_TEXCOORD
    float2x2 rotation = rotMatrix( In[ 0 ].DirRot.w );
    float2 origin = ( coords[ 0 ] - coords[ 3 ] ) * 0.5;
#endif

    [unroll]
    for (uint i = 0; i < 4; i++)
    {
        GS_OUTPUT Out = (GS_OUTPUT)0;

        Out.Position = In[ 0 ].Position;
#if BBR_VERTEX
        Out.Position.xyz += mul( rotation, offsets[i] );
#else
        Out.Position.xyz += offsets[i];
#endif
        float4 worldPos = mul( cWorld, Out.Position );

        Out.Position = mul( cViewProj, worldPos );

#if USE_FOG
        Out.ProjPos = Out.Position;
#endif
        Out.Color = In[ 0 ].Color;
#if BBR_TEXCOORD
        Out.TexCoord = mul( rotation, coords[ i ] - origin ) + origin;
#else
        Out.TexCoord = coords[ i ];
#endif
        stream.Append(Out);
    }

    stream.RestartStrip();
}