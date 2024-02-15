// This shader is called when the user wants to place voxels.

struct Voxel
{
    half type;
    float3 velocity;
    float lifeTime;
    bool updatedThisStep;
    float liquidCount;
};

RWStructuredBuffer<Voxel> voxelBuffer : register (u1);

// Width, height, and depth of world
cbuffer worldSizeBuffer : register(b1)
{
  int worldSize;
}; 

cbuffer pickBuffer : register(b4)
{
  float3 cameraPosition;
  int brushSize;
  float3 cameraForwardVec;
  int voxelType;
}; 

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

// Given a position, finds that position's index in the voxel buffer
int PositionToIndex(int3 position)
{
    return (position.y * worldSize * worldSize) + (position.z * worldSize) + position.x;
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

[numthreads(1, 1, 1)]
void Pick (uint3 id : SV_DispatchThreadID)
{
    float3 pos = cameraPosition;

    for (int i = 0; i < 200; i++)
    {
        int3 voxelPos = int3((int)pos.x, (int)pos.y, (int)pos.z);

        if (InBounds(voxelPos) && GetVoxel(voxelPos).type != 0)
        {
            float3 backup = cameraForwardVec;
            backup.x = (backup.x > 0) ? 1 : -1;
            backup.y = (backup.y > 0) ? 1 : -1;
            backup.z = (backup.z > 0) ? 1 : -1;

            voxelPos -= backup;
            Voxel voxel = (Voxel)0;
            voxel.type = voxelType;
            voxel.liquidCount = (voxelType == 2 || voxelType == 4) ? 16.0f : 0;
            voxel.updatedThisStep = true;

            for (int x = 0; x < brushSize; x++)
            {
                for (int y = 0; y < brushSize; y++)
                {
                    for (int z = 0; z < brushSize; z++)
                    {
                        if (InBounds(voxelPos + int3(x, y, z)) && GetVoxel(voxelPos + int3(x, y, z)).type == 0)
                        {
                            SetVoxel(voxelPos + int3(x, y, z), voxel);
                        }
                    }
                }
            }

            return;
        }

        pos += cameraForwardVec;
    }
}