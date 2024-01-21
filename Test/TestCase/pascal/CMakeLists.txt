cmake_minimum_required(VERSION 3.27)
project(pascal C)

set(CMAKE_C_STANDARD 11)

add_library(pascal SHARED library.c
        myformatter.h)
