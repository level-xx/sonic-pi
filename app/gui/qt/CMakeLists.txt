cmake_minimum_required(VERSION 3.2)

message(STATUS " CMakeLists: Sonic Pi")

project("Sonic Pi"
    LANGUAGES CXX C
  DESCRIPTION "A code-based music creation and performance tool"
  VERSION 3.3.0
  HOMEPAGE_URL "https://sonic-pi.net"
    )

set(CMAKE_CXX_STANDARD 14)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)
set(CMAKE_MODULE_PATH ${APP_ROOT}/cmake)

if(APPLE)
  set(CMAKE_OSX_DEPLOYMENT_TARGET '10.13')
endif()

set_property(GLOBAL PROPERTY USE_FOLDERS ON)

set(APP_ROOT ${CMAKE_CURRENT_LIST_DIR})
set(SONIC_PI_ROOT ${CMAKE_CURRENT_LIST_DIR}/../../..)

# Set cmake prefix path so it can find the Qt libraries
if((${BUILD_32BIT}) AND (DEFINED ENV{QT_INSTALL_LOCATION32}))
  message(STATUS "Setting up a 32 bit Qt Build")
  message(STATUS "Setting prefix to user-defined Qt (32-bit) install location: $ENV{QT_INSTALL_LOCATION32}")
  set(CMAKE_PREFIX_PATH $ENV{QT_INSTALL_LOCATION32})
elseif(DEFINED ENV{QT_INSTALL_LOCATION})
  message(STATUS "Setting prefix to user-defined Qt install location: $ENV{QT_INSTALL_LOCATION}")
  set(CMAKE_PREFIX_PATH $ENV{QT_INSTALL_LOCATION})
elseif(APPLE AND EXISTS /usr/local/opt/qt5)
  # Homebrew installs Qt into/usr/local/qt5
  message(STATUS "Setting prefix to Homebrew's Qt install location: /usr/local/opt/qt5")
  set(CMAKE_PREFIX_PATH /usr/local/opt/qt5)
endif()

CONFIGURE_FILE(${CMAKE_CURRENT_LIST_DIR}/cmake/config.h.cmake ${CMAKE_BINARY_DIR}/config.h)

# Qt Setup
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)

set(QT_TOOLS_DIR ${CMAKE_PREFIX_PATH}/bin)

set_property(GLOBAL PROPERTY AUTOMOC_FOLDER Automoc)
set_property(GLOBAL PROPERTY AUTOGEN_TARGETS_FOLDER Automoc)

find_package(Qt5 COMPONENTS Core Widgets Gui Concurrent Network OpenGL PrintSupport Xml Svg REQUIRED)
find_package(Threads REQUIRED)

# We build scintilla as part of the main project to make it easy to debug/fix
add_subdirectory(external/QScintilla-2.11.6)

set(APP_NAME sonic-pi)
set(MACOS_APP_NAME "Sonic Pi")

set(OSC_SOURCES
    ${APP_ROOT}/osc/oschandler.cpp
    ${APP_ROOT}/osc/oscsender.cpp
    ${APP_ROOT}/osc/sonic_pi_osc_server.cpp
    ${APP_ROOT}/osc/sonic_pi_udp_osc_server.cpp
    ${APP_ROOT}/osc/sonic_pi_tcp_osc_server.cpp
    ${APP_ROOT}/osc/oscpkt.hh
    ${APP_ROOT}/osc/udp.hh
    ${APP_ROOT}/osc/oschandler.h
    ${APP_ROOT}/osc/oscsender.h
    ${APP_ROOT}/osc/sonic_pi_osc_server.h
    ${APP_ROOT}/osc/sonic_pi_udp_osc_server.h
    ${APP_ROOT}/osc/sonic_pi_tcp_osc_server.h
    )

set(EDITOR_SOURCES
    ${APP_ROOT}/widgets/sonicpiscintilla.cpp
    ${APP_ROOT}/widgets/sonicpilexer.cpp
    ${APP_ROOT}/widgets/sonicpilexer.h
    ${APP_ROOT}/widgets/sonicpiscintilla.h
    )

set(QT_SOURCES
    ${APP_ROOT}/widgets/infowidget.cpp
    ${APP_ROOT}/widgets/settingswidget.cpp
    ${APP_ROOT}/mainwindow.cpp
    ${APP_ROOT}/mainwindow.h
    ${APP_ROOT}/model/sonicpitheme.cpp
    ${APP_ROOT}/model/sonicpitheme.h
    ${APP_ROOT}/widgets/infowidget.h
    ${APP_ROOT}/widgets/settingswidget.h
    )

set(SOURCES
    ${APP_ROOT}/external/kiss_fft/kiss_fft.c
    ${APP_ROOT}/external/kiss_fft/kiss_fft.h
    ${APP_ROOT}/visualizer/scope.cpp
    ${APP_ROOT}/visualizer/scope.h
    ${APP_ROOT}/visualizer/scope_buffer.hpp
    ${APP_ROOT}/visualizer/server_shm.hpp
    ${APP_ROOT}/main.cpp
    ${APP_ROOT}/utils/sonicpiapis.cpp
    ${APP_ROOT}/widgets/sonicpilog.cpp
    ${APP_ROOT}/widgets/sonicpilog.h
    ${APP_ROOT}/widgets/sonicpicontext.cpp
    ${APP_ROOT}/widgets/sonicpicontext.h
    ${APP_ROOT}/utils/sonicpiapis.h
    ${APP_ROOT}/utils/ruby_help.h
    ${APP_ROOT}/model/settings.h
    )

SET(RESOURCES
    ${APP_ROOT}/SonicPi.qrc
    ${APP_ROOT}/help_files.qrc
    ${APP_ROOT}/info_files.qrc
    ${APP_ROOT}/SonicPi.rc
    ${APP_ROOT}/images/app.icns
    )

# Enable tracy profiler on debug and rel with debug builds
if(WIN32)
SET (SOURCES ${SOURCES} ${APP_ROOT}/external/tracy/TracyClient.cpp)
elseif(APPLE)
  SET (SOURCES ${SOURCES} ${APP_ROOT}/platform/macos.mm)
  SET (SOURCES ${SOURCES} ${APP_ROOT}/platform/macos.h)
endif()

set(ALL_SOURCES ${OSC_SOURCES} ${QT_SOURCES} ${SOURCES} ${EDITOR_SOURCES})

# Create the Qt version of the app
if (APPLE)
  add_executable(${APP_NAME} MACOSX_BUNDLE ${ALL_SOURCES} ${RESOURCES} )
else()
  add_executable(${APP_NAME} WIN32 ${ALL_SOURCES} ${RESOURCES}) # Win32 ignored on non-windows
endif()

if (APPLE)
  set_target_properties(
    ${APP_NAME} PROPERTIES
    OUTPUT_NAME "Sonic Pi"
    MACOSX_RPATH TRUE
    XCODE_ATTRIBUTE_ENABLE_HARDENED_RUNTIME TRUE
    MACOSX_BUNDLE_BUNDLE_NAME ${PROJECT_NAME}
    MACOSX_BUNDLE_GUI_IDENTIFIER "net.sonic-pi.app"
    MACOSX_BUNDLE_INFO_STRING "A code-based music creation and performance tool"
    MACOSX_BUNDLE_ICON_FILE "app.icns"
    MACOSX_BUNDLE_LONG_VERSION_STRING ${PROJECT_VERSION}
    MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION}
    MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
    RESOURCE "images/app.icns"
    LINK_FLAGS "-framework AppKit"
    OUTPUT_NAME ${MACOS_APP_NAME}
    )
  file(
    GENERATE OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/run-macdeployqt.sh"
    CONTENT "PATH=$PATH:/usr/local/opt/qt5/bin macdeployqt \"$1\""
    )

  add_custom_command(
    TARGET ${APP_NAME}
    POST_BUILD
    COMMAND bash "${CMAKE_CURRENT_BINARY_DIR}/run-macdeployqt.sh" ${MACOS_APP_NAME}.app
    )
  add_custom_command(
    TARGET ${APP_NAME}
    POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E create_symlink ../../../../../../../app app
    POST_BUILD
    WORKING_DIRECTORY ${MACOS_APP_NAME}.app/Contents/Resources
    )
  add_custom_command(
    TARGET ${APP_NAME}
    POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E create_symlink ../../../../../../server server
    POST_BUILD
    WORKING_DIRECTORY ${MACOS_APP_NAME}.app/Contents/Resources
    )
  add_custom_command(
    TARGET ${APP_NAME}
    POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E create_symlink ../../../../../../../etc etc
    POST_BUILD
    WORKING_DIRECTORY ${MACOS_APP_NAME}.app/Contents/Resources
    )
  add_custom_command(
    TARGET ${APP_NAME}
    POST_BUILD
    COMMAND plutil -replace NSHighResolutionCapable -bool true ${MACOS_APP_NAME}.app/Contents/Info.plist
  )
endif()


set_property(TARGET ${APP_NAME} PROPERTY POSITION_INDEPENDENT_CODE ON) # Qt requires this?
target_include_directories(${APP_NAME}
    PRIVATE
    ${APP_ROOT}
    ${APP_ROOT}/external/scsynth-boost-1.74.0
    ${APP_ROOT}/external/TLSF-2.4.6/src
    ${APP_ROOT}/external
    ${APP_ROOT}/osc
    ${APP_ROOT}/model
    ${APP_ROOT}/visualizer
    ${APP_ROOT}/widgets
    ${APP_ROOT}/Utils
    ${Qt5Widgets_INCLUDE_DIRS}
    ${Qt5Gui_INCLUDE_DIRS}
    ${Qt5Core_INCLUDE_DIRS}
    ${CMAKE_BINARY_DIR}
    include)

target_link_libraries(${APP_NAME}
    PRIVATE
    QScintilla
    Qt5::Core
    Qt5::Gui
    Qt5::Widgets
    Qt5::OpenGL
    Qt5::Concurrent
    Qt5::Network
    Threads::Threads)

# Compile options and OS specific libraries
if(WIN32)
    # Workaround Qt + MSVC 19 compile issue in release build.
    target_compile_options(${APP_NAME} PRIVATE $<$<CXX_COMPILER_ID:MSVC>:/wd4005 /W3 /D_CRT_SECURE_NO_WARNINGS /D_WINSOCK_DEPRECATED_NO_WARNINGS /DBOOST_DATE_TIME_NO_LIB>)
    target_compile_options(${APP_NAME} PRIVATE "$<$<CONFIG:DEBUG>:-DTRACY_ENABLE=1>")
    target_compile_options(${APP_NAME} PRIVATE "$<$<CONFIG:RELWITHDEBINFO>:-DTRACY_ENABLE=1>")
elseif(${CMAKE_SYSTEM_NAME} MATCHES Linux)
    # Link librt
    target_link_libraries(${APP_NAME} PRIVATE rt)
endif()

# Deploy Qt binaries to the output on windows, and copy the CRT to the release folder
if(WIN32)
    # Visual Studio
    set(CMAKE_INSTALL_SYSTEM_RUNTIME_LIBS_SKIP true)
    include(InstallRequiredSystemLibraries)
    file(COPY ${CMAKE_INSTALL_SYSTEM_RUNTIME_LIBS} DESTINATION ${CMAKE_CURRENT_BINARY_DIR}/Release)

    # Run winddeployqt if it can be found, to ensure installed dependencies
    add_custom_command(TARGET ${APP_NAME} POST_BUILD
        COMMAND ${CMAKE_PREFIX_PATH}/bin/windeployqt $<TARGET_FILE:${APP_NAME}>)
endif() # Win32

# Make convenient source groups in the IDE
source_group(SonicPi FILES ${SOURCES})
source_group(Osc FILES ${OSC_SOURCES})
source_group(Scintilla FILES ${EDITOR_SOURCES})
source_group(Qt FILES ${QT_SOURCES})

source_group(Qt\\AutoMoc FILES ${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}_automoc.cpp )
source_group(Qt\\AutoMoc REGULAR_EXPRESSION "(mocs_*|qrc_.*|QtAwesome.*)" )
