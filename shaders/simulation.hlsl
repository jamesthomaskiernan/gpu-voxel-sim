// This file contains the voxel simulation logic.

// Uncomment below if warning appears "X4000: use of potentially uninitialized variable (Func)"
// #pragma warning( disable : 4000 )

/////////////////////////////////// STRUCTS ///////////////////////////////////

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

// Holds a 3D array of all voxels
RWStructuredBuffer<Voxel> voxelBuffer : register (u1);

// Width, height, and depth of world
cbuffer worldSizeBuffer : register(b1)
{
  int worldSize;
}; 

// Specifies which part of checkerboard we are simulating this step
cbuffer simulationOffsetBuffer : register(b2)
{
  int3 simulationOffset;
}; 

// Holds current time
cbuffer timeBuffer : register(b3)
{
  int time;
}; 

/////////////////////////////////// CONSTANTS ///////////////////////////////////

static float MAX_LIQUID = 16;
static float MIN_LIQUID = 1.0f/16.0f;

static float VISCOSITIES[4] = 
{
    0,     // Sand
    1.0f,  // Water
    0,     // Stone
    14.0f, // Lava
};

static float DENSITIES[4] = 
{
    1,     // Sand
    .5f,   // Water
    1,     // Stone
    .8f,   // Lava
};

#define EMPTY 0
#define SAND 1
#define WATER 2
#define STONE 3
#define LAVA 4
#define CLOUD 5

/////////////////////////////////// INCLUDES ///////////////////////////////////

#include "voxel_helpers.hlsl"
#include "noise.hlsl"

/////////////////////////////////// FUNCTIONS ///////////////////////////////////

// Liquid will transfer from one voxel to another, excess liquid remains in fromPos; returns true if successful
bool Flow(int3 fromPos, int3 toPos)
{
    Voxel fromVoxel = (Voxel)0;
    fromVoxel = GetVoxel(fromPos);
    
    Voxel toVoxel = (Voxel)0;
    toVoxel = GetVoxel(toPos);

    // If either position is out of bounds, flow fails
    if (!InBounds(fromPos) || !InBounds(toPos)) {return false;}

    // If fromVoxel doesn't contain liquid, flow fails
    if (fromVoxel.liquidCount == 0) {return false;}

    // If toVoxel isn't empty, and isn't same liquid type, flow fails
    if (toVoxel.type != 0 && toVoxel.type != fromVoxel.type) {return false;}
    
    float combinedLiquid = fromVoxel.liquidCount + toVoxel.liquidCount;

    // If their combined fluid is above max allowable per voxel
    if (combinedLiquid > MAX_LIQUID)
    {
        // Put max liquid into toVoxel
        toVoxel.liquidCount = MAX_LIQUID;
        toVoxel.type = fromVoxel.type;
        
        SetVoxel(toPos, toVoxel);
        
        // Put remaining liquid into fromVoxel
        fromVoxel.liquidCount = combinedLiquid - MAX_LIQUID;
        SetVoxel(fromPos, fromVoxel);
    }

    // Otherwise, their combined fluid can fit into toVoxel
    else
    {
        // Put all liquid into toVoxel and set it
        toVoxel.liquidCount = combinedLiquid;
        SetVoxel(toPos, toVoxel);
        
        // Set voxel position to empty
        Voxel empty = (Voxel)0;
        SetVoxel(fromPos, empty);
    }

    return true;
}

// Liquid will be removed from a position and forced into its neighbors, excess goes to fromPos; returns true if successful
bool Displace(int3 fromPos, int3 toPos)
{
    Voxel fromVoxel = (Voxel)0;
    fromVoxel = GetVoxel(fromPos);

    Voxel toVoxel = (Voxel)0;
    toVoxel = GetVoxel(toPos);

    // If voxel to displace is liquid, displace fails
    if (fromVoxel.liquidCount > 0) {return false;}

    // If voxel to displace doesn't contain any liquid, displace fails
    if (toVoxel.liquidCount == 0) {return false;}

    int3 adjacent[4] = {int3(1, 0, 0), int3(-1, 0, 0), int3(0, 0, 1), int3(0, 0, -1)};

    // Have liquid flow into all adjacent neighbors from toVoxel
    for (int i = 0; i < 4; i++)
    {
        Flow(toPos, toPos + adjacent[i]);
        toVoxel = GetVoxel(toPos);

        // If no liquid left in toVoxel, no need to keep flowing
        if (toVoxel.liquidCount == 0)
        {
            break;
        }
    }

    SetVoxel(toPos, fromVoxel);
    
    // If there is still liquid left in toVoxel after all flowing,
    // force it into fromPos
    if (toVoxel.liquidCount > 0)
    {
        SetVoxel(fromPos, toVoxel);
    }

    // Otherwise, if no water left, then set fromPos to empty
    else
    {
        SetVoxel(fromPos, (Voxel)0);
    }

    return true;
}

// Liquid will spread to adjacent liquid of same type; returns true if successful
bool Spread(int3 voxelPos)
{
    Voxel voxel = GetVoxel(voxelPos);

    // If liquid level isn't sufficient, don't spread
    if (voxel.liquidCount < VISCOSITIES[voxel.type - 1]) {return false;}

    int3 neighborPositions[5] = {int3(1, 0, 0), int3(-1, 0, 0), int3(0, 0, 1), int3(0, 0, -1), int3(0, 0, 0)}; // Adjacent positions (including current position)
    float neighborLiquid = 0; // Total liquid among current and all adjacent voxels (counts air as 0 liquid)
    int validNeighbors = 0; // How many liquid and air voxels are adjacent (includes current voxel)

    // Count all liquid in current and adjacent voxels
    for (int i = 0; i < 5; i++)
    {
        // If adjacent voxel is out of bounds, ignore it
        if (!InBounds(voxelPos + neighborPositions[i])) {continue;}
        
        // Get adjacent voxel (might also be current voxel)
        Voxel curVoxel = GetVoxel(voxelPos + neighborPositions[i]);
        
        // If adjacent voxel is same liquid type, or is empty
        if (curVoxel.type == voxel.type || curVoxel.type == EMPTY)
        {
            // Increment validNeighbors and add adjacent voxel's liquid count to neighborLiquid
            validNeighbors += 1;
            neighborLiquid += curVoxel.liquidCount > 0 ? curVoxel.liquidCount : 0.0f;
        }
    }

    // Find the average liquid among current and adjacent voxel
    float averageLiquid = neighborLiquid / validNeighbors;

    // If averaged liquid is enough
    if (averageLiquid > MIN_LIQUID)
    {
        // Set that as the liquid value for all adjacent liquid voxels (and current voxel)
        for (i = 0; i < 5; i++)
        {
            // If adjacent voxel is out of bounds, ignore it
            if (!InBounds(voxelPos + neighborPositions[i])) {continue;}

            // Get adjacent voxel (might also be current voxel)
            Voxel curVoxel = GetVoxel(voxelPos + neighborPositions[i]);
            
            // If adjacent voxel is same liquid type, or is empty
            if (curVoxel.type == voxel.type || curVoxel.type == EMPTY)
            {
                curVoxel.type = voxel.type;                          // Set voxel to liquid type
                curVoxel.liquidCount = averageLiquid;                // Set average liquid
                SetVoxel(voxelPos + neighborPositions[i], curVoxel); // Set voxel
            }
        }
        return true;
    }

    return false;
}

// Voxel will drop one position down if it's empty; returns true if successful
bool Fall(int3 voxelPos)
{
    Voxel voxel = (Voxel)0;
    voxel = GetVoxel(voxelPos);
    
    Voxel below = (Voxel)0;
    below = GetVoxel(voxelPos + int3(0, -1, 0));

    // If below is out of bounds, fall fails
    if (!InBounds(voxelPos + int3(0, -1, 0))) {return false;}

    // If below is empty, voxel moves there
    if (GetVoxel(voxelPos + int3(0, -1, 0)).type == EMPTY)
    {
        SwitchVoxels(voxelPos, voxelPos + int3(0, -1, 0));
        return true;
    }

    // If below is liquid and voxel is liquid, voxel flows there
    if (Flow(voxelPos, voxelPos + int3(0, -1, 0)))
    {
        return true;
    }

    // If below is liquid and voxel is solid, voxel falls and displaces liquid
    if (Displace(voxelPos, voxelPos + int3(0, -1, 0)))
    {
        return true;
    }

    return false;
}

// Voxel will drop to a below adjacent position if it's empty and adjacent is empty; returns true if successful
bool Slide(int3 voxelPos)
{
    // Random number between 0 and 3, used to pick random position to slide to, ensures natural seeming movement
    int rand = (int)(PseudoRandom(time) * 4.0f);

    int3 belowAdjacent[4] = {int3(1, -1, 0), int3(-1, -1, 0), int3(0, -1, 1), int3(0, -1, -1)}; // Positions to slide to
    int3 adjacent[4] = {int3(1, 0, 0), int3(-1, 0, 0), int3(0, 0, 1), int3(0, 0, -1)}; // Adjacent voxel must be empty to slide

    // If belowAdjacent isn't in bounds, or adjacent isn't empty, slide fails
    if (!InBounds(voxelPos + belowAdjacent[rand]) || GetVoxel(voxelPos + adjacent[rand]).type != 0)
    {
        return false;
    }

    // If belowAdjacent is empty, move voxel there
    if (GetVoxel(voxelPos + belowAdjacent[rand]).type == EMPTY)
    {
        SwitchVoxels(voxelPos, voxelPos + belowAdjacent[rand]);
        return true;
    }

    // If belowAdjacent is liquid, try to flow there
    if (Flow(voxelPos, voxelPos + belowAdjacent[rand]))
    {
        return true;
    }

    return false;
}

/////////////////////////////////// DISPATCH THREADS ///////////////////////////////////

// Will repeatedly spawn water and sand in sandbox
[numthreads(1, 1, 1)]
void Place (uint3 id : SV_DispatchThreadID)
{   
    int3 voxelPos = int3(32, 50, 32);
    Voxel v = (Voxel)0;
    v.type = SAND;
    SetVoxel(voxelPos, v);

    voxelPos = int3(14, 50, 14);
    v.type = WATER;
    v.liquidCount = MAX_LIQUID;
    SetVoxel(voxelPos, v);
}

// Initializes the bottom 3 layers of the world to sand
[numthreads(4, 4, 4)]
void InitializeSimulation (uint3 id : SV_DispatchThreadID)
{   
    int3 voxelPos = int3((int)id.x, (int)id.y, (int)id.z);
    
    if (voxelPos.y < 3)
    {
        Voxel v = (Voxel)0;
        v.type = SAND;
        SetVoxel(voxelPos, v);
    }
}

// Resets the updated status of all voxels, runs at end of step
[numthreads(4, 4, 4)]
void ResetUpdatedStatus (uint3 id : SV_DispatchThreadID)
{   
    int3 voxelPos = int3((int)id.x, (int)id.y, (int)id.z);
    int index = PositionToIndex(voxelPos);
    voxelBuffer[index].updatedThisStep = false;
}

// Step every voxel
[numthreads(4, 4, 4)]
void StepSimulation (uint3 id : SV_DispatchThreadID)
{   
    int gap = 4;
    int3 voxelPos = int3(id.x * gap, id.y * gap, id.z * gap) + simulationOffset;
    Voxel voxel = GetVoxel(voxelPos);
    
    // If the current voxel is air or has already been updated, ignore it
    if (voxel.type == EMPTY || voxel.updatedThisStep) {return;}

    // Mark current voxel as updated
    voxel.updatedThisStep = true;
    SetVoxel(voxelPos, voxel);

    // Sand
    if (voxel.type == SAND)
    {
        if (Fall(voxelPos)) {return;}

        if (Slide(voxelPos)) {return;}
    }

    // Water
    else if (voxel.type == WATER)
    {   
        Fall(voxelPos);

        Slide(voxelPos);

        Spread(voxelPos);

        // Get updated liquid value
        voxel = GetVoxel(voxelPos);

        // Move voxel to each adjacent position and try to slide from there
        int3 adjacent[4] = {int3(1, 0, 0), int3(-1, 0, 0), int3(0, 0, 1), int3(0, 0, -1)};
        
        // Below must not be water
        if (GetVoxel(voxelPos + int3(0, -1, 0)).type != WATER)
        {
            for (int i = 0; i < 4; i++)
            {
                if (GetVoxel(voxelPos + adjacent[i]).type == EMPTY)
                {
                    SwitchVoxels(voxelPos, voxelPos + adjacent[i]);
                    if (Slide(voxelPos + adjacent[i]))
                    {
                        return;
                    }
                    
                    SwitchVoxels(voxelPos, voxelPos + adjacent[i]);
                }
            }
        }
    }

    // Stone
    else if (voxel.type == STONE)
    {
        Fall(voxelPos);
    }

    // Lava
    else if (voxel.type == LAVA)
    {

        Fall(voxelPos);

        Slide(voxelPos);

        Spread(voxelPos);

        // Get updated liquid value, stop if no liquid left
        voxel = GetVoxel(voxelPos);
        if (voxel.liquidCount == 0) {return;}

        // Move voxel to each adjacent position and try to slide from there
        int3 adjacent[4] = {int3(1, 0, 0), int3(-1, 0, 0), int3(0, 0, 1), int3(0, 0, -1)};
        
        // Bottom must not be same type
        if (GetVoxel(voxelPos + int3(0, -1, 0)).type != LAVA)
        {
            for (int i = 0; i < 4; i++)
            {
                if (GetVoxel(voxelPos + adjacent[i]).type == EMPTY)
                {
                    SwitchVoxels(voxelPos, voxelPos + adjacent[i]);
                    if (Slide(voxelPos + adjacent[i]))
                    {
                        return;
                    }
                    
                    SwitchVoxels(voxelPos, voxelPos + adjacent[i]);
                }
            }
        }

        // Get updated liquid value, stop if no liquid left
        voxel = GetVoxel(voxelPos);
        if (voxel.liquidCount == 0) {return;}

        // If a neighbor is water, solidify it into stone
        int3 adjacentAndUpDown[6] = {int3(0, 1, 0), int3(0, -1, 0), int3(1, 0, 0), int3(-1, 0, 0), int3(0, 0, 1), int3(0, 0, -1)};

        for (int i = 0; i < 6; i++)
        {
            if (GetVoxel(voxelPos + adjacentAndUpDown[i]).type == 2)
            {
                float rand = PseudoRandom(time);
                Voxel stone = (Voxel)0;
                stone.type = 3;

                // Equal chance to replace water with stone, rather than lava with stone
                if (rand < .5f) {SetVoxel(voxelPos + adjacentAndUpDown[i], stone);}
                else {SetVoxel(voxelPos, stone);}
            }
        }
    }
}