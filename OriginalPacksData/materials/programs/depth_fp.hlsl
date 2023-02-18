#if DISSOLVE || BURNING
    cbuffer FPConstantBuffer : register(b0)
    {
#   if DISSOLVE
        float  cDissolveAmount;
#   endif
#   if BURNING
        float4 cBurningAmount;
#   endif
    };
#endif

struct VS_OUTPUT
{
    float4  Position    : SV_POSITION;
#if ALPHA_TEST || BURNING || DISSOLVE
    float2  TexCoord    : TEXCOORD0;
#endif
};

#if ALPHA_TEST || BURNING
    Texture2D       tTexture;
    SamplerState    sTexture;
#endif
#if DISSOLVE || BURNING
    Texture2D       tDissolve;
    SamplerState    sDissolve;
#endif

void mainFP( VS_OUTPUT In )
{
#if BURNING
    float alpha =  tTexture.Sample( sTexture, In.TexCoord ).w;
    float dissolve = tDissolve.Sample( sDissolve, In.TexCoord ).x;
#   if DISSOLVE
    if ( dissolve < cDissolveAmount ) 
        discard;
#   endif
    float alphaReject = ( dissolve > cBurningAmount.x ) ? 0.25f : 0.75f;
    if ( alpha < alphaReject ) 
        discard;
#else
#   if DISSOLVE
    float dissolve = tDissolve.Sample( sDissolve, In.TexCoord ).x;
    if ( dissolve < cDissolveAmount ) 
        discard;
#   endif
#   if ALPHA_TEST
    float alpha = tTexture.Sample( sTexture, In.TexCoord ).w;
    if ( alpha <= 0.5 ) 
        discard;
#   endif
#endif  
}
