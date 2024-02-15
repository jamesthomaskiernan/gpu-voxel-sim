#include "compute_shader.h"
#include "d3dcompiler.h"
#include "debug.h"

ComputeShader::ComputeShader(LPCWSTR filePath, LPCSTR functionName)
{
    const LPCSTR featureLevel = "cs_5_0";

    // Blobs
    ID3DBlob* errorBlob = nullptr;
    ID3DBlob* computeBlob = nullptr;
    
    // Flags
    UINT flags = D3DCOMPILE_DEBUG;
    // UINT flags = D3DCOMPILE_ENABLE_STRICTNESS; // use for release 

    // Compile compute shader
    HRESULT HR = D3DCompileFromFile(
        filePath,
        nullptr, // Defines (using none for now)
        D3D_COMPILE_STANDARD_FILE_INCLUDE,
        functionName,
        featureLevel,
        flags,
        0,
        &computeBlob,
        &errorBlob);
    Debug(errorBlob, "failed to compile compute shader from file");

    // Create shader
    HR = Graphics::device->CreateComputeShader(computeBlob->GetBufferPointer(), computeBlob->GetBufferSize(), nullptr, &shaderPtr);
    Debug(HR, "failed to create compute shader");

    // Set private data
    shaderPtr->SetPrivateData(WKPDID_D3DDebugObjectName, lstrlenA(functionName), functionName);
};

void ComputeShader::Dispatch(UINT x, UINT y, UINT z)
{
    Graphics::context->CSSetShader(shaderPtr, nullptr, 0);
    Graphics::context->Dispatch(x, y, z);
    Graphics::context->CSSetShader(nullptr, nullptr, 0);
}
