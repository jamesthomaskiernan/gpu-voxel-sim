#include "vertex_shader.h"
#include "graphics.h"
#include "d3dcompiler.h"
#include "debug.h"
#include "window.h"

VertexShader::VertexShader(LPCWSTR filePath, std::vector<D3D11_INPUT_ELEMENT_DESC> inputDesc)
{
    const LPCSTR functionName = "Vertex";
    const LPCSTR featureLevel = "vs_5_0";

    // Blobs
    ID3DBlob *errorBlob = NULL;
    ID3DBlob *vertexBlob = NULL;

    // Flags
    UINT flags = D3DCOMPILE_DEBUG;
    // UINT flags = D3DCOMPILE_ENABLE_STRICTNESS; // Use for release 

    // Compile vertex shader
    HRESULT HR = D3DCompileFromFile(
        filePath,
        nullptr,
        D3D_COMPILE_STANDARD_FILE_INCLUDE,
        functionName,
        featureLevel,
        flags,
        0,
        &vertexBlob,
        &errorBlob
    );

    Debug(errorBlob, "failed to compile vertex shader from file");

    // Create vertex shader
    HR = Graphics::device->CreateVertexShader(
    vertexBlob->GetBufferPointer(),
    vertexBlob->GetBufferSize(),
    NULL,
    shaderPtr.GetAddressOf());
    Debug(HR, "failed to create vertex shader");
    
    // Create input layout
    HR = Graphics::device->CreateInputLayout(
        &inputDesc[0],
        inputDesc.size(),
        vertexBlob->GetBufferPointer(),
        vertexBlob->GetBufferSize(),
        inputLayoutPtr.GetAddressOf());
    Debug(HR, "failed to create input layout for vertex shader");
}

void VertexShader::Bind()
{
    Graphics::context->VSSetShader(shaderPtr.Get(), NULL, 0);
    Graphics::context->IASetInputLayout(inputLayoutPtr.Get());
}