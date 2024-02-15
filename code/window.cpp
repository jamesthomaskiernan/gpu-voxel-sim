#include "window.h"
#include "input.h"
#include "settings.h"
#include "debug.h"

void Window::Init()
{
    windowClass = {};
    windowClass.cbSize = sizeof(WNDCLASSEXW);
    windowClass.style = CS_HREDRAW | CS_VREDRAW;
    windowClass.lpfnWndProc = &Input::WindowProc;
    windowClass.hInstance = handleInstance;
    windowClass.hIcon = LoadIconW(0, IDI_APPLICATION);
    windowClass.hCursor = LoadCursorW(0, IDC_ARROW);
    windowClass.lpszClassName = L"WindowClass";
    windowClass.hIconSm = LoadIconW(0, IDI_APPLICATION);

    if(!RegisterClassExW(&windowClass))
    {
        Debug("Failed to create window");
    }

    int centerScreenX = GetSystemMetrics(SM_CXSCREEN) / 2 - WINDOW_WIDTH / 2;
    int centerScreenY = GetSystemMetrics(SM_CXSCREEN) / 2 - WINDOW_HEIGHT / 2;

    // Window rectangle    
    RECT windowRect;
    windowRect.left = 50;
    windowRect.top = 50;
    windowRect.right = windowRect.left + WINDOW_WIDTH;
    windowRect.bottom = windowRect.top + WINDOW_HEIGHT;
    AdjustWindowRect(&windowRect, WS_OVERLAPPEDWINDOW | WS_VISIBLE, FALSE);

    windowHandle = CreateWindowExW(WS_EX_OVERLAPPEDWINDOW,
                            windowClass.lpszClassName,
                            L"Voxel Sim",
                            WS_OVERLAPPEDWINDOW | WS_VISIBLE,
                            windowRect.left,
                            windowRect.top,
                            windowRect.right - windowRect.left,    // Width of the window
                            windowRect.bottom - windowRect.top,    // Height of the window
                            0,
                            0,
                            handleInstance,
                            0);

    if(!windowHandle)
    {
        Debug("Failed to create window handle");
    }
}