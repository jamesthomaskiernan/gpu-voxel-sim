#pragma once

#include <d3d11.h>
#include <vector>
#include <stdint.h>
#include <wrl.h>

namespace WRL = Microsoft::WRL;


class IndexBuffer
{    
    public:
	
    IndexBuffer(std::vector<uint32_t> &data);

    void Bind();

    private:

    WRL::ComPtr<ID3D11Buffer> buffer;
};