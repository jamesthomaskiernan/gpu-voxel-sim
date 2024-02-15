#include "quad.h"
#include "voxel.h"

void Quad::Init()
{
    //-------------------Create Shaders-------------------//

    // Input format for vertex shader
    std::vector<D3D11_INPUT_ELEMENT_DESC> inputDesc;
    inputDesc.push_back({ "POS", 0, DXGI_FORMAT_R32G32B32_FLOAT, 0, 0, D3D11_INPUT_PER_VERTEX_DATA, 0 });
    inputDesc.push_back({ "TEX", 0, DXGI_FORMAT_R32G32_FLOAT, 0, D3D11_APPEND_ALIGNED_ELEMENT, D3D11_INPUT_PER_VERTEX_DATA, 0 });

    // Create and bind shaders
    vertexShader = new VertexShader(L"../shaders/sprite.hlsl", inputDesc);
    vertexShader->Bind();
    pixelShader = new PixelShader(L"../shaders/sprite.hlsl");
    pixelShader->Bind();

    //-------------------Create Vertex Buffer-------------------//

    // Vertices for tilemap (just a quad, made of 2 tris)
    std::vector<Vertex2> verts = std::vector<Vertex2>();

    // Push first triangle
    verts.push_back({float3(-0.005f, -0.005f, 0), float2(0, 0)}); // bottom left
    verts.push_back({float3(-0.005f, 0.005f, 0), float2(0, 1)}); // top left
    verts.push_back({float3(0.005f, -0.005f, 0), float2(1, 0)}); // bottom right

    // Push second triangle
    verts.push_back({float3(0.005f, -0.005f, 0), float2(1, 0)}); // bottom right
    verts.push_back({float3(-0.005f, 0.005f, 0), float2(0, 1)}); // top left
    verts.push_back({float3(0.005f, 0.005f, 0), float2(1, 1)}); // top right

    // Create and bind vertex buffer
    vertexBuffer = new VertexBuffer<Vertex2>(verts);
    vertexBuffer->Bind();
}

void Quad::Update()
{
    vertexBuffer->Bind();
    vertexShader->Bind();
    pixelShader->Bind();

    // Bind picker cbuffer to sprite.hlsl
    Graphics::context->PSSetConstantBuffers(4, 1, VoxelSim::pickBuffer->buffer.GetAddressOf());                   // b1         
    Graphics::context->PSSetConstantBuffers(1, 1, VoxelSim::worldSizeBuffer->buffer.GetAddressOf());              // b4

    Graphics::context->Draw(6, 0);
}