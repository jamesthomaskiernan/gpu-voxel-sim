#pragma once

#include "const_buffer.h"
#include "timer.h"
#include <chrono>

class Application
{
    public:

    static void Start();
    
    static void Update();

    static void Kill();

    static bool IsRunning();

    static float GetDeltaTime();

    static void RefreshDeltaTime();

    static void PrintFPS();

    static inline auto startTime = std::chrono::system_clock::now();

    private:

    static inline Timer gameClock = Timer();

    static inline Timer fpsClock = Timer();

    static inline int fpsCount = 0;

    static inline bool running = false;

    static inline float deltaTime = 0.0f;
};