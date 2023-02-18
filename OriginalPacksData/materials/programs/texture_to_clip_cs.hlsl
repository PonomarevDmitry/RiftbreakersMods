
Texture2D           InputTexture  : register(t0);
RWTexture2D<float4> OutputTexture : register(u0);

[numthreads(16, 16, 1)]
void main(uint2 gid : SV_GroupID, uint2 gtid : SV_GroupThreadID, uint2 did : SV_DispatchThreadID)
{
    OutputTexture[did.xy] = InputTexture.Load(int3(did, 0)).rgba;
}