cmake_minimum_required(VERSION 3.21)
project(remarkable_east_asian_ime LANGUAGES C CXX)

set(CMAKE_AUTOMOC ON)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 REQUIRED COMPONENTS Core Qml)
find_package(Threads REQUIRED)

set(THIRD_PARTY "${CMAKE_CURRENT_SOURCE_DIR}/../../third_party")
set(OPENWNN "${THIRD_PARTY}/openwnn")
set(PINYIN "${THIRD_PARTY}/pinyin")

file(GLOB OPENWNN_C_SOURCES CONFIGURE_DEPENDS
    "${OPENWNN}/wnnDictionary/engine/*.c"
    "${OPENWNN}/wnnEngine/*.c"
)
file(GLOB OPENWNN_CPP_SOURCES CONFIGURE_DEPENDS
    "${OPENWNN}/wnnEngine/*.cpp"
)
file(GLOB OPENWNN_HEADERS CONFIGURE_DEPENDS
    "${OPENWNN}/wnnDictionary/include/*.h"
    "${OPENWNN}/wnnEngine/include/*.h"
)
file(GLOB PINYIN_SOURCES CONFIGURE_DEPENDS "${PINYIN}/share/*.cpp")
file(GLOB PINYIN_HEADERS CONFIGURE_DEPENDS "${PINYIN}/include/*.h")

add_library(eastasianime SHARED
    eastasianime.cpp
    eastasianime.h
    plugin.cpp
    ${OPENWNN_C_SOURCES}
    ${OPENWNN_CPP_SOURCES}
    ${OPENWNN_HEADERS}
    ${PINYIN_SOURCES}
    ${PINYIN_HEADERS}
)

target_include_directories(eastasianime PUBLIC
    "${CMAKE_CURRENT_SOURCE_DIR}"
    "${OPENWNN}/wnnDictionary/include"
    "${OPENWNN}/wnnEngine/include"
    "${PINYIN}/include"
)

target_link_libraries(eastasianime PRIVATE
    Qt6::Core
    Qt6::CorePrivate
    Qt6::Qml
    Threads::Threads
)

set_target_properties(eastasianime PROPERTIES
    OUTPUT_NAME eastasianime
    PREFIX "lib"
)

set(QML_TEST_MODULE_DIR
    "${CMAKE_BINARY_DIR}/qml-root/io/codex/EastAsianIme")
add_custom_command(TARGET eastasianime POST_BUILD
    COMMAND "${CMAKE_COMMAND}" -E make_directory "${QML_TEST_MODULE_DIR}"
    COMMAND "${CMAKE_COMMAND}" -E copy_if_different
        "$<TARGET_FILE:eastasianime>"
        "${QML_TEST_MODULE_DIR}/libeastasianime.so"
    COMMAND "${CMAKE_COMMAND}" -E copy_if_different
        "${CMAKE_CURRENT_SOURCE_DIR}/qmldir"
        "${QML_TEST_MODULE_DIR}/qmldir"
)

add_executable(eastasianime_test test_eastasianime.cpp)
target_link_libraries(eastasianime_test PRIVATE eastasianime Qt6::Core Qt6::Qml)

add_executable(eastasianime_qml_test test_qml_import.cpp)
target_compile_definitions(eastasianime_qml_test PRIVATE
    EASTASIAN_IME_TEST_IMPORT_PATH="${CMAKE_BINARY_DIR}/qml-root")
target_link_libraries(eastasianime_qml_test PRIVATE Qt6::Core Qt6::Qml)
add_dependencies(eastasianime_qml_test eastasianime)
