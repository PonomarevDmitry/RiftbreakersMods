
struct Sampler2D { SamplerState smpl; Texture2D tex; };

float4 Tex2D( Sampler2D tex, float2 uv ) 
{
    return tex.tex.Sample( tex.smpl, uv.xy );
}
