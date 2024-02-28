## About

This is a voxel cellular automata program which runs entirely on compute shaders. It's written in C++ using D3D11 as a graphics API. Users can place 4 different types of voxels (sand, water, stone, lava), each of which behave differently. Simulation of the voxels, mesh generation, and player interaction are all handled by compute shaders. As a result the program runs very fast.

<image src="./preview/screenshot.png"></image>

## Video Preview

### Sand
<img src="./preview/falling.gif?raw=true">

### Fluid Flowing
<img src="./preview/flowing.gif?raw=true">

### Fluid Filling Space
<img src="./preview/filling.gif?raw=true">

### Water/Lava Interacting
<img src="./preview/colliding.gif?raw=true">

## How It Works

Below is a technical explanation of how the program works. Relevant code can be found in `/code/voxel.cpp`, `/code/voxel.h`, and `/shaders/`. Most relevant code is heavily commented, so please feel free to explore.

### Simulation
All voxel data is stored on the GPU in a structured buffer called `voxelBuffer`, which is then accessed like a 3D array. Every frame the simulation is stepped forward by running the `StepSimulation` dispatch thread inside `simulation.hlsl`. Each thread is assigned a voxel using its thread ID, and then checks nearby voxels to see how its voxel should be updated. Instead of having all voxels updated in one dispatch of the `StepSimulation` thread, multiple dispatches are done using an offset, meaning voxels are updated in a sort of checkerboard pattern to prevent race conditions between neighbors.

### Mesh Generation
After the simulation is stepped, the `compute` dispatch thread inside `mesh_generation.hlsl` is run to create an updated mesh for the world. Using `voxelBuffer`, all triangles for the new world mesh are generated and appended to `triangleBuffer`. Another buffer called `vertexCountBuffer` is used along with an atomic add function to keep track of the mesh vertex count. Though `triangleBuffer` should have a built in counter since it's an AppendStructuredBuffer, I was having difficulty accessing it, so I used `vertexCountBuffer` to keep track of vertex count as a workaround.

### Rendering
A DrawInstancedIndirect call is made to render the world. The call is indirect since the vertex count isn't known by the CPU. Instead, that data is copied from the `vertexCountBuffer` into an arguments buffer. This arguments buffer is then passed into the DrawInstancedIndirect method. The world mesh's vertex and pixel shaders are inside `/shaders/voxel.hlsl`. Inside the vertex function, VertexID is used to find the appropriate triangle inside `triangleBuffer`. The pixel function then colors the voxels according to type.

### Placing Voxels
If the user is clicks left mouse button, then the `pick` dispatch thread inside `picker.hlsl` is run to place voxels in the world. Relevant data like camera position, camera forward vector, and voxel type, are written into `pickBuffer` and then accessed inside `picker.hlsl`. This function casts a ray out from the camera until it hits a voxel. Then it sets any surrounding voxels within a certain radius to the user selected voxel type.

## To Build

Please note a binary is available for download under the releases section, if you wish to just run the program and want to avoid building altogether. If you do wish to build, follow the instructions below.

1. Specify desired settings in `/code/settings.h`.
2. Navigate to `/build` and run `cmake .` to generate makefile.
3. Inside `/build` run `make` to build using makefile.
4. Executable should be generated in `/build`.

Alternatively, CMake could also be used to generate a visual studio project with `cmake -B Builds -G 'Visual Studio 17 2022'`. Make sure to replace 17 and 2022 with whichever visual studio version you are using.

## Controls

- WASD + Space + Shift to move around world
- Hold down right mouse button and move mouse to look around
- Left mouse button places voxels
- 1 2 3 4 selects type of voxel to place (sand, water, stone, lava)

## Performance

Since all mesh generation and simulation steps run on the GPU, performance is very good. On a RTX 3090 at resolution of 1920 x 1080, this implementation runs at ~9,200 fps.

## Dependencies

This repo uses the DirectXMath and SimpleMath libraries. They can be found inside `/dependencies`. You will also need D3D11 installed.

## Requirements

I would recommend having at least 512MB of VRAM to run this program. If the world size is increased, more VRAM will be needed as all world data is stored in buffers on the GPU.

## Usage

Please feel free to use or modify this code as you wish. If you create your own project with it, then please cite this repo.
