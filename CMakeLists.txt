cmake_minimum_required(VERSION 3.21)

project(DatabaseCodeGenerator LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 23)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTOUIC ON)
set(CMAKE_AUTORCC ON)

find_package(Qt6 REQUIRED COMPONENTS Core Quick QuickControls2 Qml)

qt_policy(SET QTP0001 NEW)

file(GLOB_RECURSE 
        SOURCES   
            src/main.cpp
            ${CMAKE_CURRENT_SOURCE_DIR}/src/app/*.cpp
)

qt_add_executable(DatabaseCodeGenerator
    ${SOURCES}
)

target_include_directories(DatabaseCodeGenerator
    PRIVATE
        ${CMAKE_CURRENT_SOURCE_DIR}/src/app
)

qt_add_qml_module(DatabaseCodeGenerator
    URI DatabaseCodeGenerator
    VERSION 1.0
    QML_FILES
        qml/Main.qml
        qml/GridBackground.qml
        qml/ZoomableCanvas.qml
        qml/DatabaseTable.qml
        qml/DatabaseTableContent.qml
        qml/DatabaseColumnItem.qml
        qml/ConnectionsLayer.qml
)

target_link_libraries(DatabaseCodeGenerator
    PRIVATE
        Qt6::Core
        Qt6::Quick
        Qt6::QuickControls2
        Qt6::Qml
)
