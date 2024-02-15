#pragma once

#include <d3d11.h>
#include <wrl.h>
namespace WRL = Microsoft::WRL;

template<typename T>
class ConstBuffer
{
    public:
	
    ConstBuffer();

    void SetData(T data);

    WRL::ComPtr<ID3D11Buffer> buffer;
};

#include "./const_buffer.cpp"