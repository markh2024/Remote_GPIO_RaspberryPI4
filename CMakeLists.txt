cmake_minimum_required(VERSION 3.10)
project(RemoteGPIO CXX)

set(CMAKE_CXX_STANDARD 11)

# Check for pigpio library
find_path(PIGPIO_INCLUDE_DIR pigpiod_if2.h)
find_library(PIGPIO_LIB pigpiod_if2)

if(NOT PIGPIO_INCLUDE_DIR OR NOT PIGPIO_LIB)
    message(FATAL_ERROR "pigpio library not found. Please install with: sudo apt install pigpio")
endif()

include_directories(${PIGPIO_INCLUDE_DIR})

add_executable(remote_gpio main.cpp)
target_link_libraries(remote_gpio ${PIGPIO_LIB})

