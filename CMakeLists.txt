cmake_minimum_required(VERSION 3.21)

project(DatabaseCodeGenerator LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 23)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Enable Qt automatic processing tools
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTOUIC ON)
set(CMAKE_AUTORCC ON)

# 1) Find Qt modules
find_package(Qt6 REQUIRED COMPONENTS Core Quick QuickControls2 Qml)

# 2) Now we can safely use qt_policy (Qt has defined it)
qt_policy(SET QTP0001 NEW)

# 3) App executable target
qt_add_executable(DatabaseCodeGenerator
    src/main.cpp
)

# 4) QML module attached to the same target
qt_add_qml_module(DatabaseCodeGenerator
    URI DatabaseCodeGenerator        # import DatabaseCodeGenerator 1.0
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

# 5) Link Qt libraries
target_link_libraries(DatabaseCodeGenerator
    PRIVATE
        Qt6::Core
        Qt6::Quick
        Qt6::QuickControls2
        Qt6::Qml
)
