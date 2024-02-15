#include "camera_controller.h"

void CameraController::Init()
{
    // Create cam
    cam.SetPosition(0, 0, -5);
    cam.SetProjectionValues(60, 1920.0f / 1080.0f, .1f, 5000.0f);

	// Update constant Buffer
	float4x4 world = DirectX::XMMatrixIdentity();
	float4x4 mvp = world * cam.GetViewMatrix() * cam.GetProjectionMatrix();
	float4x4 mvpTransposed = DirectX::XMMatrixTranspose(mvp);

    // Create const buffer for MVP matrix
    mvpBuffer = new ConstBuffer<float4x4>();
    mvpBuffer->SetData(mvpTransposed);
    Graphics::context->VSSetConstantBuffers(0, 1, mvpBuffer->buffer.GetAddressOf());
}

void CameraController::Update(float &dt)
{
    bool updateMVP = false;

    if (Input::GetKey('W'))
    {
        float4 forwardVec = cam.GetForwardVector() * movementSpeed * dt;
        float3 fw = float3(forwardVec.x, forwardVec.y, forwardVec.z);
        cam.AdjustPosition(fw);
        updateMVP = true;
    }

    if (Input::GetKey('S'))
    {
        float4 backwardVec = cam.GetBackwardVector() * movementSpeed * dt;
        float3 bw = float3(backwardVec.x, backwardVec.y, backwardVec.z);
        cam.AdjustPosition(bw);
        updateMVP = true;
    }

    if (Input::GetKey('D'))
    {
        float4 rightVec = cam.GetRightVector() * movementSpeed * dt;
        float3 r = float3(rightVec.x, rightVec.y, rightVec.z);
        cam.AdjustPosition(r);
        updateMVP = true;
    }

    if (Input::GetKey('A'))
    {
        float4 leftVec = cam.GetLeftVector() * movementSpeed * dt;
        float3 l = float3(leftVec.x, leftVec.y, leftVec.z);
        cam.AdjustPosition(l);
        updateMVP = true;
    }

    if (Input::GetKey(Space))
    {
        cam.AdjustPosition(0, movementSpeed * dt, 0);
        updateMVP = true;
    }

    if (Input::GetKey(Shift))
    {
        cam.AdjustPosition(0, -movementSpeed * dt, 0);
        updateMVP = true;
    }

    // Swap mouse positions
    oldMousePos = newMousePos;
    newMousePos = Input::GetMousePosition();

    if (Input::GetKey(Esc))
    {
        Application::Kill();
    }

    // Rotate camera with mouse
    if (Input::GetMouseButton(2))
    {
        float2 mouseChange = (newMousePos - oldMousePos) * float2(.2, .2);
        cam.AdjustRotation(mouseChange.y * mouseSensitivity, mouseChange.x * mouseSensitivity, 0);
        updateMVP = true;
    }

    // Update MVP buffer
    if (updateMVP)
    {
        float4x4 world = DirectX::XMMatrixIdentity();
        float4x4 mvp = world * cam.GetViewMatrix() * cam.GetProjectionMatrix();
        float4x4 mvpTransposed = DirectX::XMMatrixTranspose(mvp);

        mvpBuffer->SetData(mvpTransposed);
    }
}