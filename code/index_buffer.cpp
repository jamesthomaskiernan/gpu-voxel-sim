#include "index_buffer.h"
#include "debug.h"
#include "graphics.h"

IndexBuffer::IndexBuffer(std::vector<uint32_t> &data)
{
	uint32_t bufferSize = data.size();

    // Create buffer description
    D3D11_BUFFER_DESC indexBufferDesc;
    ZeroMemory(&indexBufferDesc, sizeof(indexBufferDesc));
    indexBufferDesc.Usage = D3D11_USAGE_DEFAULT;
    indexBufferDesc.ByteWidth = sizeof(uint32_t) * bufferSize;
    indexBufferDesc.BindFlags = D3D11_BIND_INDEX_BUFFER;
    indexBufferDesc.CPUAccessFlags = 0;
    indexBufferDesc.MiscFlags = 0;

    // Create index data resource
    D3D11_SUBRESOURCE_DATA indexBufferData;
    ZeroMemory(&indexBufferData, sizeof(indexBufferData));
    indexBufferData.pSysMem = &data[0];
    
    // Create buffer
    HRESULT hr = Graphics::device->CreateBuffer(&indexBufferDesc, &indexBufferData, buffer.GetAddressOf());
    Debug(hr, "failed to create index buffer");
}

void IndexBuffer::Bind()
{
    Graphics::context->IASetIndexBuffer(buffer.Get(), DXGI_FORMAT_R32_UINT, 0);
}