#pragma once

#include "graphics.h"
#include "application.h"
#include "window.h"
#include "input.h"
#include "graphics.h"
#include "pixel_shader.h"
#include "vertex_shader.h"
#include <vector>
#include "struct_buffer.h"
#include "vertex_buffer.h"
#include "camera_controller.h"
#include "compute_shader.h"
#include "stdint.h"
#include "compute_shader.h"
#include "struct_buffer.h"
#include "vertex_buffer.h"
#include <cstdio>
#include <chrono>

struct Triangle
{
  float3 vertA;
  float3 vertB;
  float3 vertC;
  float3 normal;
  int voxelType;
  int padding;
  int padding2;
};

struct int3
{
  int32_t x;
  int32_t y;
  int32_t z;
};

struct Voxel
{
  int16_t type;
  float3 velocity;
  float lifeTime;
  bool updatedThisFrame;
  float fluidCount;
};

struct PickInfo
{
  float3 cameraPosition;
  int brushSize;
  float3 cameraForwardVec;
  int voxelType;
};

class VoxelSim
{
  public:

  // Runs once on startup
  static void Init();

  // Runs once every frame
  static void Update();

  // Advances voxel simulation forward once
  static void Step();

  static inline int typeToPlace = 1;

  // Width, height, and depth of world
  static const inline uint32_t worldSize = 128;

  // How many times voxels will update per second (vsync will limit this to 60 or 120)
  static inline uint32_t stepsPerSecond = 120; 

  // Keeps track of when to update simulation
  static inline Timer simulationClock = Timer();

  // Generates triangles for each voxel and places them in the trianglesBuffer (mesh_generation.hlsl)
  static inline ComputeShader* meshGeneration = nullptr;

  // Resets the vertex count inside the vertexCountBuffer (reset_vertex_count.hlsl)
  static inline ComputeShader* resetVertexCount = nullptr;

  // Calculates new voxel values from the old values (simulation.hlsl)
  static inline ComputeShader* stepSimulation = nullptr;

  // Resets the updated status for all voxels (changes them all back to updated=false)
  static inline ComputeShader* resetUpdatedStatus = nullptr;

  // Runs when user wants to place down voxels
  static inline ComputeShader* picker = nullptr;

  // Runs continuously, 
  static inline ComputeShader* place = nullptr;
  
  // Renders using the triangles inside the triangleBuffer below (voxel.hlsl)
  static inline VertexShader* vertexShader = nullptr;

  // Fairly simple lighting shader (voxel.hlsl)
  static inline PixelShader* pixelShader = nullptr;

  // Holds required info for every voxel
  static inline StructBuffer<Voxel>* voxelBuffer = nullptr;

  // Holds triangles created from voxelGenerator compute shader; these are later read by vertex shader
  static inline StructBuffer<Triangle>* triangleBuffer = nullptr;

  // Keeps track of total vertices for the DrawInstancedIndirect() call later
  static inline StructBuffer<uint32_t>* vertexCountBuffer = nullptr;

  // Holds info passed to the DrawInstancedIndirect call:
  // argBuffer[0] = vertex count per instance (comes from vertexCountBuffer)
  // argBuffer[1] = instance count (# of times to draw our verts; will always be 1)
  // argBuffer[2] = start vertex location (will always be 0)
  // argBuffer[3] = start instance location (will always be 0)
  static inline StructBuffer<uint32_t>* argBuffer = nullptr;

  // Holds worldsize integer, required for all compute shaders
  static inline ConstBuffer<uint32_t>* worldSizeBuffer = nullptr;

  static inline ConstBuffer<int3>* simulationOffsetBuffer = nullptr;

  // Holds a time value used for random numbers in the simulation
  static inline ConstBuffer<int>* timeBuffer = nullptr;

  static inline ConstBuffer<PickInfo>* pickBuffer = nullptr;
};