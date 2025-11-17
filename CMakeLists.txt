cmake_minimum_required(VERSION 3.21)
project(DatabaseCodeGenerator LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 23)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 REQUIRED COMPONENTS Core Quick QuickControls2 Qml)

set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTOUIC ON)
set(CMAKE_AUTORCC ON)

qt_add_resources(RESOURCES ${CMAKE_CURRENT_SOURCE_DIR}/resources/qml_resources.qrc)

qt_add_executable(${PROJECT_NAME} 
    src/main.cpp
    ${RESOURCES}
)

target_link_libraries(${PROJECT_NAME}
    PRIVATE Qt6::Core Qt6::Quick Qt6::QuickControls2 Qt6::Qml
)