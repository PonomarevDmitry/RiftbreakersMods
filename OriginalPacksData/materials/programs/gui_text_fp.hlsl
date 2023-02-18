cbuffer FPConstantBuffer : register(b0)
{
    //float   cSmooth;
    //float   cCenter;

    //float   cGlowEnabled;
    //float   cGlowSize;
    //float   cGlowSpread;

    //float   cBlurr;
    //float   cShadowSize;
	float4 	cTextureSize;
	float4  cViewportSize;
};

struct VS_OUTPUT
{
    float4  Position    : SV_POSITION;
    float4  Color       : COLOR;
    float2  TexCoord    : TEXCOORD0;
    float4  ChannelMask : BINORMAL;
};

struct PS_OUTPUT
{
    float4  Color0      : SV_TARGET;
};

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

Texture2D       tAlbedo       : register( t0 );
SamplerState    sAlbedo       : register( s0 );

float GetMaskedSample( float2 coord, float4 mask )
{
	float4 albedo = tAlbedo.SampleLevel( sAlbedo, coord.xy, 0 );
	return dot( albedo, mask );
}

float GetMaskedSample( float2 coord, float4 mask, float norm )
{
	float4 albedo = tAlbedo.SampleLevel( sAlbedo, coord.xy, 0 );
	return norm * dot( albedo, mask );
}

float GetMaskedSupSample( float2 coord, float4 mask, float norm )
{
	float dscale = 0.78 * 0.354; // #param 1 "ss_pattern_scale"
	float2 duv = dscale* ( ddx(coord) + ddy(coord) );
	duv = mul( rotMatrix(15), duv );
	float4 box = float4( coord-duv, coord+duv);
	float boxColorA = GetMaskedSample( box.xy, mask, norm )
					+ GetMaskedSample( box.zw, mask, norm )
					+ GetMaskedSample( box.xw, mask, norm )
					+ GetMaskedSample( box.zy, mask, norm );
    float b0 = GetMaskedSample( coord, mask, norm );
	float sd = 1.0/3.0 * b0 + 0.5/3.0 * boxColorA; // #param 4 "ss_profile_height"
	return sd;
}


float GetMaskedSupSampleMin( float2 coord, float4 mask, float norm )
{
	float dscale = 0.41 * 0.354; // #param 1 "ss_pattern_scale"
	float2 duv = dscale* ( ddx(coord) + ddy(coord) );
	duv = mul( rotMatrix(15), duv );
	float4 box = float4( coord-duv, coord+duv);
	float boxColorA = min( min( GetMaskedSample( box.xy, mask, norm ),
							    GetMaskedSample( box.zw, mask, norm ) ),
						   min( GetMaskedSample( box.xw, mask, norm ),
							    GetMaskedSample( box.zy, mask, norm ) ) );
    float b0 = min( GetMaskedSample( coord, mask, norm ), boxColorA );
	return b0;
}

PS_OUTPUT mainFP( VS_OUTPUT In )
{ 
    PS_OUTPUT Out;
	float dx = ddx( In.TexCoord.x ) * cTextureSize.x;
	float dy = ddy( In.TexCoord.y ) * cTextureSize.y;
	float toPixels = 6.37 * cViewportSize.y / (cViewportSize.y - 250) * rsqrt( dx * dx + dy * dy );
	float sigDist = GetMaskedSample( In.TexCoord, In.ChannelMask ) - 0.5;
	float opa = saturate( toPixels * sigDist + 0.5 );
    Out.Color0 = float4(In.Color.rgb, opa * In.Color.a);
    return Out;
	
	// float pxRange = 4.0;
	// float2 sdfUnit = pxRange / cTextureSize.xy;
	// float sigDist = GetMaskedSample( In.TexCoord, In.ChannelMask, norm ) - 0.5;
	// sigDist *= dot( sdfUnit, 0.5/fwidth(In.TexCoord) );
	// float opa = clamp( 1.0*sigDist + 0.5, 0.0, 1.0 );
    // Out.Color0 = float4(In.Color.rgb, opa * In.Color.a);
    // return Out;
	
	//float sd = GetMaskedSample( In.TexCoord, In.ChannelMask, norm );
	//float sdf = b0.a;	
	//float smoothing = 0.1;//* ddx(In.TexCoord).x;	
	//if ( cGlowEnabled != 0.0 && cBlurr != 0.0  )
    //{
	//	smoothing = (1.0 + cGlowSize * cGlowSize ) / cSmooth;
    //}
	//else if ( cBlurr != 0.0 )
	//{
	//	smoothing = (1.0 + cShadowSize * cShadowSize ) / cSmooth;
	//}
	
	//float smoothing = 0.05;//* ddx(In.TexCoord).x;
	//float gradWidth = 0.052;//* ddx(In.TexCoord).x;
	//float w = smoothstep( cCenter - smoothing, cCenter + gradWidth, sd );
	//float contr = 1.0; // #param 2 "ss_contrast_ratio"
	//float brightn = 1.0; // #param 3 "ss_brightness_ratio"
	//w = saturate( contr * (brightn*w-0.5) + 0.5 );
	//
    //float4 BaseColor = float4(In.Color.rgb, w * In.Color.a);
    //   
    //Out.Color0 = BaseColor;
    //return Out;
}
