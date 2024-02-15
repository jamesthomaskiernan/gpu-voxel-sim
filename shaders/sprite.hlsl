
/////////////////////////////////// STRUCTS ///////////////////////////////////

struct VertexInput
{
  float3 position_world : POS;
  float2 uv : TEX;
};

struct VertexOutput
{
  float4 position_clip : SV_POSITION; // Required output of VS
  float2 uv : TEX;
};

// Holds all info for each voxel
struct Voxel
{
  half type;
  float3 velocity;
  float lifeTime;
  bool updatedThisStep;
  float liquidCount;
};

/////////////////////////////////// BUFFERS ///////////////////////////////////

cbuffer pickBuffer : register(b4)
{
  float3 cameraPosition;
  int brushSize;
  float3 cameraForwardVec;
  int voxelType;
}; 

cbuffer worldSizeBuffer : register(b1)
{
  int worldSize;
}; 

/////////////////////////////////// INCLUDES ///////////////////////////////////

// #include "voxel_helpers.hlsl"

/////////////////////////////////// VERTEX/PIXEL FUNCS ///////////////////////////////////

VertexOutput Vertex(VertexInput input)
{
  VertexOutput output = (VertexOutput)0; // Zero the memory first
  output.position_clip = float4(input.position_world, 1.0f);
  output.uv = input.uv;
  return output;
}

float4 Pixel(VertexOutput input) : SV_TARGET
{
  if (cameraPosition.y < 0)
  {
    return float4(1, 0, 1, 1);
  }

  return float4(1, 1, 1, 1);
}