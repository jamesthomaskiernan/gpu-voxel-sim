cmake_minimum_required(VERSION 3.5.1)
project (gpu-voxel-sim)
set (CMAKE_CXX_STANDARD 17)

add_executable (gpu-voxel-sim

../code/voxel.cpp
../code/quad.cpp

# core
../code/main.cpp
../code/application.cpp
../code/window.cpp
../code/input.cpp
../code/graphics.cpp
../code/debug.cpp
../code/camera.cpp
../code/camera_controller.cpp
../code/timer.cpp

# shaders
../code/vertex_shader.cpp
../code/pixel_shader.cpp
../code/compute_shader.cpp

# buffers
../code/vertex_buffer.cpp
../code/const_buffer.cpp
../code/struct_buffer.cpp
../code/index_buffer.cpp
)

# include project files
target_include_directories(${PROJECT_NAME} PUBLIC "../code/")

# include dependencies
target_include_directories(${PROJECT_NAME} PUBLIC "../dependencies/directx_math/include")
target_include_directories(${PROJECT_NAME} PUBLIC "../dependencies/simple_math/include")

# link d3d11 libraries
target_link_libraries(${PROJECT_NAME}
    d3d11.lib d3dcompiler.lib libucrt.lib
)