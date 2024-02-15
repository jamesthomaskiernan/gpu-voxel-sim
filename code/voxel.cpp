#include "voxel.h"
#include "camera_controller.h"

void VoxelSim::Init()
{
    simulationClock.Start();

    //-------------------Create Shaders-------------------//

    // Input format for vertex shader (required even though we're rendering indirectly)
    std::vector<D3D11_INPUT_ELEMENT_DESC> inputDesc;
    inputDesc.push_back({ "POS", 0, DXGI_FORMAT_R32G32B32_FLOAT, 0, 0, D3D11_INPUT_PER_VERTEX_DATA, 0 });

    // Vertex and Pixel shaders
    vertexShader = new VertexShader(L"../shaders/voxel.hlsl", inputDesc);
    pixelShader = new PixelShader(L"../shaders/voxel.hlsl");
    vertexShader->Bind();
    pixelShader->Bind();

    // Compute shaders
    meshGeneration = new ComputeShader(L"../shaders/mesh_generation.hlsl");
    resetVertexCount = new ComputeShader(L"../shaders/reset_vertex_count.hlsl", "ResetVertexCount");
    stepSimulation = new ComputeShader(L"../shaders/simulation.hlsl", "StepSimulation");
    resetUpdatedStatus = new ComputeShader(L"../shaders/simulation.hlsl", "ResetUpdatedStatus");
    picker = new ComputeShader(L"../shaders/picker.hlsl", "Pick");
    
    //-------------------Create Buffers-------------------//

    // argBuffer and vertexCountBuffer will be initialized to data in arr
    uint32_t arr[4] = {0, 1, 0, 0};
    argBuffer = new StructBuffer(IndirectArgs, 4, arr);
    vertexCountBuffer = new StructBuffer<uint32_t>(ReadWrite, 4, arr);
    voxelBuffer = new StructBuffer<Voxel>(ReadWrite, worldSize * worldSize * worldSize);
    triangleBuffer = new StructBuffer<Triangle>(Append, worldSize * worldSize * worldSize);
    worldSizeBuffer = new ConstBuffer<uint32_t>();
    simulationOffsetBuffer = new ConstBuffer<int3>();
    timeBuffer = new ConstBuffer<int>();
    pickBuffer = new ConstBuffer<PickInfo>();

    // Set world size
    worldSizeBuffer->SetData(worldSize);

    // Bind all buffers needed for our compute shaders
    Graphics::context->CSSetUnorderedAccessViews(0, 1, triangleBuffer->uav.GetAddressOf(), nullptr);    // u0
    Graphics::context->CSSetUnorderedAccessViews(1, 1, voxelBuffer->uav.GetAddressOf(), nullptr);       // u1
    Graphics::context->CSSetUnorderedAccessViews(2, 1, vertexCountBuffer->uav.GetAddressOf(), nullptr); // u2
    Graphics::context->CSSetConstantBuffers(1, 1, worldSizeBuffer->buffer.GetAddressOf());              // b1
    Graphics::context->CSSetConstantBuffers(2, 1, simulationOffsetBuffer->buffer.GetAddressOf());       // b2
    Graphics::context->CSSetConstantBuffers(3, 1, timeBuffer->buffer.GetAddressOf());                   // b3
    Graphics::context->CSSetConstantBuffers(4, 1, pickBuffer->buffer.GetAddressOf());                   // b4

    //------------------Initialize World-------------------//

    // Initialize world
    ComputeShader* initializeSimulation = new ComputeShader(L"../shaders/simulation.hlsl", "InitializeSimulation");
    initializeSimulation->Dispatch(worldSize / 4, worldSize / 4, worldSize / 4);
    Step();

    place = new ComputeShader(L"../shaders/simulation.hlsl", "Place");
}

void VoxelSim::Update()
{
    place->Dispatch(1, 1, 1);

    // Use the below numbers to select what type of voxel to place

    if (Input::GetKeyDown('1'))
    {
        typeToPlace = 1;
    }

    else if (Input::GetKeyDown('2'))
    {
        typeToPlace = 2;
    }

    else if (Input::GetKeyDown('3'))
    {
        typeToPlace = 3;
    }

    else if (Input::GetKeyDown('4'))
    {
        typeToPlace = 4;
    }

    // If enough time has passed and it's time to do a step
    if (simulationClock.GetMilisecondsElapsed() > 1.0 / stepsPerSecond)
    {   
        // If user is clicking mouse 1 button, then place their selected block type
        if (Input::GetMouseButton(0))
        {
            PickInfo info = {float3(0, 0, 0), 0, float3(0, 0, 0), 0};
            info.brushSize = 6;
            info.cameraPosition = CameraController::cam.GetPosition();
            float4 forward = CameraController::cam.GetForwardVector();
            info.cameraForwardVec = float3(forward.x, forward.y, forward.z);
            info.voxelType = typeToPlace;

            pickBuffer->SetData(info);
            picker->Dispatch(1, 1, 1);
        }

        // Then step simulation
        simulationClock.Stop();
        Step();
        simulationClock.Restart();
    }

    vertexShader->Bind();
    pixelShader->Bind();
    Graphics::context->DrawInstancedIndirect(argBuffer->buffer.Get(), 0);
}

void VoxelSim::Step()
{
    // Set triangle buffer as UAV for compute shaders
    ID3D11ShaderResourceView *blank1 = nullptr;
    UINT initialCounterValue = 0;
    Graphics::context->CSSetUnorderedAccessViews(0, 1, triangleBuffer->uav.GetAddressOf(), &initialCounterValue); // u0

    // Set vertex count back to 0
    resetVertexCount->Dispatch(1, 1, 1);

    // Update time buffer for simulation
    std::chrono::system_clock::time_point now = std::chrono::system_clock::now();
    std::chrono::duration<float> duration = now - Application::startTime;
    timeBuffer->SetData(std::chrono::duration_cast<std::chrono::milliseconds>(duration).count());

    int gap = 4;

    // Run simulation in checkerboard pattern
    for (int x = 0; x < gap; x++)
    {
        for (int y = 0; y < gap; y++)
        {
            for (int z = 0; z < gap; z++)
            {
                simulationOffsetBuffer->SetData({x, y, z});
                stepSimulation->Dispatch((worldSize / gap) / 4, (worldSize / gap) / 4, (worldSize / gap) / 4);
            }
        }
    }

    resetUpdatedStatus->Dispatch(worldSize / 4, worldSize / 4, worldSize / 4);

    // Generate triangles with new voxel data
    meshGeneration->Dispatch(worldSize / 4, worldSize / 4, worldSize / 4);

    // Copy new vertex count over to arg buffer
    Graphics::context->CopyResource(argBuffer->buffer.Get(), vertexCountBuffer->buffer.Get());

    // Unbind triangle buffer as UAV for later use as SRV in vertex shader
    ID3D11UnorderedAccessView *blank = nullptr;
    Graphics::context->CSSetUnorderedAccessViews(0, 1, &blank, nullptr);
    Graphics::context->VSSetShaderResources(1, 1, triangleBuffer->srv.GetAddressOf()); // t1
}