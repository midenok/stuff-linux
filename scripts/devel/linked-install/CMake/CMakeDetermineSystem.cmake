include(${CMAKE_ROOT}/Modules/CMakeDetermineSystem.cmake)
file(APPEND
    ${CMAKE_PLATFORM_INFO_DIR}/CMakeSystem.cmake
    "install(CODE \"SET(CMAKE_MODULE_PATH \\\"${CMAKE_MODULE_PATH}\\\")
        INCLUDE(linked_install)\")")
