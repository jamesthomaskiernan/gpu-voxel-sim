// This file contains helper functions for simulation.hlsl

#ifndef VOXEL_HELPERS
#define VOXEL_HELPERS

// Given a position, finds that position's index in the voxel buffer
int PositionToIndex(int3 position)
{
    return (position.y * worldSize * worldSize) + (position.z * worldSize) + position.x;
}

// Indicates if a given position is inside the game world
bool InBounds(int3 position)
{
    return !(
        position.x > worldSize - 1 ||
        position.x < 0 ||
        position.y > worldSize - 1 ||
        position.y < 0 ||
        position.z > worldSize - 1 ||
        position.z < 0
    );
}

// Sets a voxel at a given position
void SetVoxel(int3 voxelPos, Voxel voxel)
{
    int index = PositionToIndex(voxelPos);
    voxelBuffer[index] = voxel;
}

// Returns a voxel at a given position
Voxel GetVoxel(int3 position)
{
    int index = PositionToIndex(position);
    return voxelBuffer[index];
}

// Switches voxels at two positions
void SwitchVoxels(int3 position1, int3 position2)
{
    // Get both voxels
    Voxel voxel1 = GetVoxel(position1);
    Voxel voxel2 = GetVoxel(position2);
    
    // Set both voxels
    SetVoxel(position2, voxel1);
    SetVoxel(position1, voxel2);
}

#endif