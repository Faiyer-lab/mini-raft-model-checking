cmake_minimum_required(VERSION 3.16)

project(mini_raft_cpp LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

add_executable(mini_raft_cpp
    src/main.cpp
)
