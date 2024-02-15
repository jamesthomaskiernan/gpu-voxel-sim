// This file contains the vertex and fragment shaders which run on the voxel meshes

struct Triangle
{
  float3 vertA;
  float3 vertB;
  float3 vertC;
  float3 normal;
  int voxelType;
  int2 padding;
};

struct VertexOutput
{
  float4 position_clip : SV_POSITION;
  float3 normal : NORMAL;
  int voxelType : TEXCOORD0;
  int voxelHeight : TEXCOORD1;
};

cbuffer mvpBuffer : register(b0)
{
  float4x4 mvp;
}; 

cbuffer worldSizeBuffer : register(b1)
{
  int worldSize;
}; 

static float4 voxelColors[5] = 
{
  float4(1, 1, 0, 1),
  float4(0, .2f, .8f, .3f),
  float4(.2f, .2f, .2f, 1),
  float4(1, .2f, .2f, 1),
  float4(.8, .8, .8, 1),
};

StructuredBuffer<Triangle> trianglesBuffer : register(t1);

VertexOutput Vertex(uint vertexID : SV_VertexID)
{
  VertexOutput output = (VertexOutput)0;

  // Read the triangle data from the buffer using the vertexID
  Triangle tri = trianglesBuffer[vertexID / 3];

  // Determine the vertex index within the current triangle
  uint vertexIndex = vertexID % 3;

  // Assign the position and normal based on the vertex index
  if (vertexIndex == 0)
  {
    output.position_clip = mul(float4(tri.vertA, 1.0f), mvp);
  }
  else if (vertexIndex == 1)
  {
    output.position_clip = mul(float4(tri.vertB, 1.0f), mvp);
  }
  else
  {
    output.position_clip = mul(float4(tri.vertC, 1.0f), mvp);
  }

  output.normal = tri.normal;
  output.voxelType = tri.voxelType;
  output.voxelHeight = max(tri.vertA.y, max(tri.vertB.y, tri.vertC.y));

  return output;
}

float4 Pixel(VertexOutput input) : SV_TARGET
{
  float3 lightDirection = normalize(float3(.5f, .8f, 1)); // Assuming a directional light from (1, 1, 1)
  float intensity = max(0, dot(input.normal, lightDirection)); // Calculate the dot product between the normal and light direction

  float4 diffuseColor = voxelColors[max(0, input.voxelType - 1)]; // Fetch the original color

  float ambientIntensity = 0.3; // Adjust the ambient intensity as desired (0.0 - 1.0)

  float4 finalColor = diffuseColor * intensity + diffuseColor * ambientIntensity; // Combine diffuse and ambient lighting

  finalColor += sin(input.voxelHeight) * .2f;

  return finalColor;
}