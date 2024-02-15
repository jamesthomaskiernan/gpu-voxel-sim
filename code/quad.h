#pragma once

#include "graphics.h"
#include "application.h"
#include "window.h"
#include "input.h"
#include "graphics.h"
#include "pixel_shader.h"
#include "vertex_shader.h"
#include <vector>
#include "struct_buffer.h"
#include "vertex_buffer.h"
#include "camera_controller.h"
#include "compute_shader.h"
#include "stdint.h"
#include "compute_shader.h"
#include "struct_buffer.h"
#include "vertex_buffer.h"
#include <cstdio>

struct Vertex2
{
    float3 pos;
    float2 uv;
};

class Quad
{
    public:

    static void Init();

    static void Update();

    static inline VertexBuffer<Vertex2>* vertexBuffer = nullptr;

    static inline VertexShader* vertexShader = nullptr;

    static inline PixelShader* pixelShader = nullptr;
};