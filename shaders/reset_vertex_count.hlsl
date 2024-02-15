// This file resets the vertexCountBuffer to 0, which is used during the indirect draw call

RWStructuredBuffer<uint> vertexCountBuffer : register (u2);

[numthreads(1, 1, 1)]
void ResetVertexCount (uint3 id : SV_DispatchThreadID)
{   
  vertexCountBuffer[0] = 0;
}