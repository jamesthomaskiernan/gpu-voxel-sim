#pragma once

#include "SimpleMath.h"
#include "Camera.h"
#include "input.h"
#include "settings.h"
#include "const_buffer.h"
#include "application.h"

class CameraController
{
    public:

    static void Init();

    static void Update(float &dt);

    static inline float2 oldMousePos = Input::GetMousePosition();
    
    static inline float2 newMousePos = Input::GetMousePosition();

    static inline PerspectiveCamera cam = PerspectiveCamera();

    static inline ConstBuffer<float4x4>* mvpBuffer;

    static inline float movementSpeed = 20.0f;
    
    static inline float mouseSensitivity = .01f;
};