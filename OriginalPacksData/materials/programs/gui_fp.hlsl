#if USE_BLEND_2_TEXTURE || USE_AA || USE_LANCZOS || USE_UNSHARP
cbuffer FPConstantBuffer : register(b0)
{
#   if USE_AA || USE_UNSHARP
    float4  cTextureSize;
#   endif
#	if USE_LANCZOS
	float4  cInvTextureSize;
#	endif
#   if USE_BLEND_2_TEXTURE
    float   cChange;
#   endif
};
#endif

struct VS_OUTPUT
{
    float4  Position    : SV_POSITION;
    float4  Color       : COLOR;
#if USE_TEXTURE || USE_BLEND_2_TEXTURE
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
  #if USE_MASK
    Texture2D       tTex1       : register( t1 );
    SamplerState    sTex1       : register( s1 );
  #endif
#elif USE_BLEND_2_TEXTURE 
    Texture2D       tTex0       : register( t0 );
    SamplerState    sTex0       : register( s0 );
    Texture2D       tTex1       : register( t1 );
    SamplerState    sTex1       : register( s1 );
#endif

PS_OUTPUT mainFP( VS_OUTPUT In ) 
{
    PS_OUTPUT Out;

#if USE_TEXTURE

#if USE_AA
    float dscale = 4.0 * 0.354; // half of 1/sqrt2
    float2 duv = float2( dscale/cTextureSize.x, dscale/cTextureSize.y );
    float4 box = float4( In.TexCoord-duv, In.TexCoord+duv );
    float4 boxColor = tTex0.Sample( sTex0, box.xy )
                    + tTex0.Sample( sTex0, box.zw )
                    + tTex0.Sample( sTex0, box.xw )
                    + tTex0.Sample( sTex0, box.zy );
    Out.Color = ( tTex0.Sample( sTex0, In.TexCoord ) + 0.5 * boxColor ) / 3.0 * In.Color;
#elif USE_LANCZOS
    float2 step = cInvTextureSize;
    Out.Color = tTex0.Sample( sTex0, In.TexCoord ) * 0.38026 
		+ tTex0.Sample( sTex0, In.TexCoord - 1.0 * step ) * 0.27667 
		+ tTex0.Sample( sTex0, In.TexCoord + 1.0 * step ) * 0.27667 
		+ tTex0.Sample( sTex0, In.TexCoord - 2.0 * step ) * 0.08074
		+ tTex0.Sample( sTex0, In.TexCoord + 2.0 * step ) * 0.08074
		+ tTex0.Sample( sTex0, In.TexCoord - 3.0 * step ) * 0.02612
		+ tTex0.Sample( sTex0, In.TexCoord + 3.0 * step ) * 0.02612
		+ tTex0.Sample( sTex0, In.TexCoord - 4.0 * step ) * 0.02143 
		+ tTex0.Sample( sTex0, In.TexCoord + 4.0 * step ) * 0.02143;
#elif USE_UNSHARP
	float dx = ddx( In.TexCoord.x ) * cTextureSize.x;
	float dy = ddy( In.TexCoord.y ) * cTextureSize.y;
	float2 ddiag = dx + dy;
	float scaleFactor = 2.0 * rsqrt( dot(ddiag,ddiag)/2.0 );
	const float forceFactor = 1.0;
	float force = clamp( 2.0 * (1.0 - scaleFactor) * forceFactor, 0.0, 2.0 );
	float w1 = -0.0625 * force;
	float w2 = -0.125 * force;
	float w0 = 1.0 + 0.75 * force;
	//float2 step = cInvTextureSize;
	float2 step = ddx( In.TexCoord.x ) +  ddy( In.TexCoord.y );
	float4 un = tTex0.Sample( sTex0, In.TexCoord + float2(-step.x,-step.y) ) * w1
              + tTex0.Sample( sTex0, In.TexCoord + float2(      0,-step.y) ) * w2
              + tTex0.Sample( sTex0, In.TexCoord + float2( step.x,-step.y) ) * w1
              + tTex0.Sample( sTex0, In.TexCoord + float2(-step.x,      0) ) * w2
              + tTex0.Sample( sTex0, In.TexCoord + float2(      0,      0) ) * w0
              + tTex0.Sample( sTex0, In.TexCoord + float2( step.x,      0) ) * w2
              + tTex0.Sample( sTex0, In.TexCoord + float2(-step.x, step.y) ) * w1
              + tTex0.Sample( sTex0, In.TexCoord + float2(      0, step.y) ) * w2
              + tTex0.Sample( sTex0, In.TexCoord + float2( step.x, step.y) ) * w1;
    Out.Color = un * In.Color;
	//Out.Color = float4(force,force,force,1);
#else
	Out.Color = tTex0.Sample( sTex0, In.TexCoord ) * In.Color;
#endif

#if USE_MASK
    float4 c2 = tTex1.Sample( sTex1, In.TexCoord );
    Out.Color = Out.Color * c2;
#endif

#elif USE_BLEND_2_TEXTURE
    float4 c1 = tTex0.Sample( sTex0, In.TexCoord );
    float4 c2 = tTex1.Sample( sTex1, In.TexCoord );
    Out.Color = lerp( c1, c2, ( 1.0 + cChange ) / 2.0 ) * In.Color;
#else
    Out.Color = In.Color;
#endif

#if USE_STENCIL && USE_TEXTURE
    clip ( Out.Color.x > 0 ? 1:-1 );
#endif

    return Out;
}
