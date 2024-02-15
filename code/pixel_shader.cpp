#include "pixel_shader.h"
#include "graphics.h"
#include "d3dcompiler.h"
#include "debug.h"
#include "window.h"

PixelShader::PixelShader(LPCWSTR filePath)
{
    const LPCSTR functionName = "Pixel";
    const LPCSTR featureLevel = "ps_5_0";

    // Blobs
    ID3DBlob *errorBlob = NULL;
    ID3DBlob *pixelBlob = NULL;

    // Flags
    UINT flags = D3DCOMPILE_DEBUG;
    // UINT flags = D3DCOMPILE_ENABLE_STRICTNESS; // use for release 
    
    // Compile pixel shader
    HRESULT HR = D3DCompileFromFile(
        filePath,
        nullptr, // Defines (using none for now)
        D3D_COMPILE_STANDARD_FILE_INCLUDE,
        functionName,
        featureLevel,
        flags,
        0,
        &pixelBlob,
        &errorBlob
    );

    Debug(errorBlob, "failed to compile pixel shader from file");

    // Create pixel shader
    HR = Graphics::device->CreatePixelShader(
    pixelBlob->GetBufferPointer(),
    pixelBlob->GetBufferSize(),
    NULL,
    shaderPtr.GetAddressOf());
    Debug(HR, "failed to create pixel shader");
}

void PixelShader::Bind()
{
    Graphics::context->PSSetShader(shaderPtr.Get(), NULL, 0);
}