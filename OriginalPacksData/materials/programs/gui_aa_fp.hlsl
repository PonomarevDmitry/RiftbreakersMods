struct VS_OUTPUT
{
    float4  Position    : SV_POSITION;
    float4  Color       : COLOR;
#if USE_TEXTURE
    float2  TexCoord    : TEXCOORD0;
#endif
};

struct PS_OUTPUT
{
    float4  Color       : SV_TARGET;
};

#if USE_TEXTURE
    Texture2D       tTex0       : register( t0 );
    SamplerState    sTex0       : register( s0 );
#endif

inline float2x2 rotMatrix( float angle )
{
	float rad = radians( angle );
    float s = sin(rad);
    float c = cos(rad);

    return float2x2
    (
        float2( c, -s ),
        float2( s, c )
    );
}

PS_OUTPUT mainFP( VS_OUTPUT In ) 
{
    PS_OUTPUT Out;

#if USE_TEXTURE
	float dscale = 0.5* 0.7 * 0.25; // #param 1 "ss_pattern_scale"
	float2 duv = dscale * ( ddx(In.TexCoord) + ddy(In.TexCoord) );
	duv = mul( rotMatrix(15), duv );
	float4 box = float4( In.TexCoord-duv, In.TexCoord+duv);
	float boxColorA = tTex0.SampleLevel( sTex0, box.xy, 0 ).w
					+ tTex0.SampleLevel( sTex0, box.zw, 0 ).w
					+ tTex0.SampleLevel( sTex0, box.xw, 0 ).w
					+ tTex0.SampleLevel( sTex0, box.zy, 0 ).w;
	float contr = 1.0; // #param 2 "ss_contrast_ratio"
	float brightn = 1.0; // #param 3 "ss_brightness_ratio"
	float alpha = 1.0/3.0 * tTex0.SampleLevel( sTex0, In.TexCoord, 0 ).w + 0.5/3.0 * boxColorA; // #param 4 "ss_profile_height"
	//alpha = 0.25 * boxColorA;
	alpha = saturate( contr * (brightn*alpha-0.5) + 0.5 );
	
	float4 color = tTex0.SampleLevel( sTex0, In.TexCoord, 0 ) * In.Color;

	// OUTPUT:
    Out.Color = float4( color.xyz, alpha * In.Color.w );
    //Out.Color = tTex0.SampleLevel( sTex0, In.TexCoord, 0 ) * In.Color;
#else
    Out.Color = In.Color;
#endif

#if USE_STENCIL && USE_TEXTURE
    clip ( Out.Color.x > 0 ? 1:-1 );
#endif

    return Out;
}
