# Kernel sensor node (ESP-IDF v5.x, ESP32-S3, NimBLE).
#   idf.py set-target esp32s3
#   idf.py menuconfig        # Kernel sensor node -> node type, pins, key storage
#   idf.py build flash monitor
cmake_minimum_required(VERSION 3.16)

set(EXTRA_COMPONENT_DIRS "${CMAKE_CURRENT_LIST_DIR}/components")

include($ENV{IDF_PATH}/tools/cmake/project.cmake)
project(kernel_sensor_node)
