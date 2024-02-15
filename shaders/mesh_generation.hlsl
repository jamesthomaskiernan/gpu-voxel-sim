// This file generates all voxel meshes and then pushes those triangles to the triangleBuffer.
// This triangleBuffer is then accessed during an indirect draw call.

#include "noise.hlsl"

struct Voxel
{
  half type;
  float3 velocity;
  float lifeTime;
  bool updatedThisStep;
  float fluidCount;
};

struct Triangle
{
  float3 vertA;
  float3 vertB;
  float3 vertC;
  float3 normal;
  int voxelType;
  int2 padding;
};

static float3 voxelVertices[8] =
{
  float3(-.5f, -.5f,  .5f),  // p0
  float3(-.5f, -.5f, -.5f),  // p1
  float3( .5f, -.5f,  .5f),  // p2
  float3( .5f, -.5f, -.5f),  // p3
  float3(-.5f,  .5f,  .5f),  // p4
  float3(-.5f,  .5f, -.5f),  // p5
  float3( .5f,  .5f,  .5f),  // p6
  float3( .5f,  .5f, -.5f),  // p7
};

AppendStructuredBuffer<Triangle> triangleBuffer : register (u0);
RWStructuredBuffer<Voxel> voxelBuffer : register (u1);
RWStructuredBuffer<uint> vertexCountBuffer : register (u2);

cbuffer worldSizeBuffer : register(b1)
{
  int worldSize;
}; 

int PositionToIndex(int3 position)
{
  return (position.y * worldSize * worldSize) + (position.z * worldSize) + position.x;
}

void PushTriangle(int index1, int index2, int index3, float3 normal, int3 voxelPos)
{
  Voxel voxel = voxelBuffer[PositionToIndex(voxelPos)];

  Triangle T = (Triangle)0;
  T.normal = normal;
  T.voxelType = voxel.type;

  T.vertA = voxelVertices[index1] + voxelPos;
  T.vertB = voxelVertices[index2] + voxelPos;
  T.vertC = voxelVertices[index3] + voxelPos;
  
  triangleBuffer.Append(T);
  InterlockedAdd(vertexCountBuffer[0], 3);

  // NOTE: It's inefficient to use both AppendStructBuffer and
  // InterlockedAdd. Ideally, the counter value of triangleBuffer
  // would be copied into vertexCountBuffer with a call of
  // CopyStructureCount() on CPU, and then another compute shader
  // would triple that value. This works too though.
}

[numthreads(4, 4, 4)]
void Compute (uint3 id : SV_DispatchThreadID)
{   
  int3 voxelPos = int3((int)id.x, (int)id.y, (int)id.z);
  int index = PositionToIndex(voxelPos);
  int voxelType = voxelBuffer[index].type;

  if (voxelType != 0)
  {
    // Types of adjacent voxels
    int right = voxelBuffer[PositionToIndex(voxelPos + int3(1, 0, 0))].type;
    int left = voxelBuffer[PositionToIndex(voxelPos + int3(-1, 0, 0))].type;
    int up = voxelBuffer[PositionToIndex(voxelPos + int3(0, 1, 0))].type;
    int down = voxelBuffer[PositionToIndex(voxelPos + int3(0, -1, 0))].type;
    int forward = voxelBuffer[PositionToIndex(voxelPos + int3(0, 0, 1))].type;
    int backward = voxelBuffer[PositionToIndex(voxelPos + int3(0, 0, -1))].type;

    // Check to see if any sides are visible, or if any are along world edge
    if (right == 0 || voxelPos.x == worldSize - 1)
    {
      // x +
      PushTriangle(3, 7, 2, float3(1, 0, 0), voxelPos);
      PushTriangle(2, 7, 6, float3(1, 0, 0), voxelPos);
    }

    if (left == 0 || voxelPos.x == 0)
    {
      // x-
      PushTriangle(0, 4, 1, float3(0, 0, 0), voxelPos);
      PushTriangle(1, 4, 5, float3(0, 0, 0), voxelPos);
    }
      
    if (up == 0 || voxelPos.y == worldSize - 1)
    {
      // y +
      PushTriangle(4, 6, 5, float3(0, 1, 0), voxelPos);
      PushTriangle(5, 6, 7, float3(0, 1, 0), voxelPos);
    }
      
    if (down == 0 || voxelPos.y == 0)
    {
      // y -
      PushTriangle(2, 0, 3, float3(0, 0, 0), voxelPos);
      PushTriangle(3, 0, 1, float3(0, 0, 0), voxelPos);
    }
      
    if (forward == 0 || voxelPos.z == worldSize - 1)
    {
      // z +
      PushTriangle(2, 6, 0, float3(0, 0, 1), voxelPos);
      PushTriangle(0, 6, 4, float3(0, 0, 1), voxelPos);
    }

    if (backward == 0 || voxelPos.z == 0)
    {
      // z -
      PushTriangle(1, 5, 3, float3(0, 0, 0), voxelPos);
      PushTriangle(3, 5, 7, float3(0, 0, 0), voxelPos);
    }
  }
}