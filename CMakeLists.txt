cmake_minimum_required(VERSION 3.16)
project(L4D2_IOS LANGUAGES C CXX OBJC OBJCXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# Set minimum iOS deployment target to iOS 15.0 (for modern CADisplayLink ProMotion support)
if(NOT DEFINED CMAKE_OSX_DEPLOYMENT_TARGET)
    set(CMAKE_OSX_DEPLOYMENT_TARGET "15.0")
endif()

# Source files
set(CORE_SOURCES
    src/core/types.h
    src/core/engine_bridge.h
    src/core/engine_bridge.cpp
    src/core/promotion_manager.h
    src/core/promotion_manager.mm
)

set(TOUCH_SOURCES
    src/touch/dynamic_joystick.h
    src/touch/dynamic_joystick.mm
    src/touch/touch_buttons.h
    src/touch/touch_buttons.mm
    src/touch/weapon_switcher.h
    src/touch/weapon_switcher.mm
    src/touch/touch_controller.h
    src/touch/touch_controller.mm
)

set(LOGGING_SOURCES
    src/logging/logger.h
    src/logging/logger.cpp
    src/logging/asset_validator.h
    src/logging/asset_validator.cpp
    src/logging/debug_overlay.h
    src/logging/debug_overlay.mm
)

set(IOS_SOURCES
    ios/src/main.mm
    ios/src/AppDelegate.h
    ios/src/AppDelegate.mm
    ios/src/GameViewController.h
    ios/src/GameViewController.mm
    ios/src/MetalView.h
    ios/src/MetalView.mm
)

set(ALL_SOURCES
    ${CORE_SOURCES}
    ${TOUCH_SOURCES}
    ${LOGGING_SOURCES}
    ${IOS_SOURCES}
)

# App bundle target
add_executable(L4D2IOS MACOSX_BUNDLE ${ALL_SOURCES})

target_include_directories(L4D2IOS PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/src
    ${CMAKE_CURRENT_SOURCE_DIR}/src/core
    ${CMAKE_CURRENT_SOURCE_DIR}/src/touch
    ${CMAKE_CURRENT_SOURCE_DIR}/src/logging
    ${CMAKE_CURRENT_SOURCE_DIR}/ios/src
)

# Target properties for iOS bundle
set_target_properties(L4D2IOS PROPERTIES
    MACOSX_BUNDLE TRUE
    MACOSX_BUNDLE_INFO_PLIST "${CMAKE_CURRENT_SOURCE_DIR}/ios/Info.plist"
    MACOSX_BUNDLE_BUNDLE_NAME "Left4Dead2"
    MACOSX_BUNDLE_GUI_IDENTIFIER "com.valvesoftware.l4d2ios"
    MACOSX_BUNDLE_BUNDLE_VERSION "1.0.0"
    MACOSX_BUNDLE_SHORT_VERSION_STRING "2.2.3.1"
    XCODE_ATTRIBUTE_PRODUCT_BUNDLE_IDENTIFIER "com.valvesoftware.l4d2ios"
    XCODE_ATTRIBUTE_TARGETED_DEVICE_FAMILY "1,2" # iPhone and iPad
    XCODE_ATTRIBUTE_ENABLE_BITCODE "NO"
    XCODE_ATTRIBUTE_CLANG_ENABLE_OBJC_ARC "YES"
    XCODE_ATTRIBUTE_CODE_SIGNING_ALLOWED "NO"
    XCODE_ATTRIBUTE_CODE_SIGNING_REQUIRED "NO"
    XCODE_ATTRIBUTE_CODE_SIGN_IDENTITY ""
)

# Link Apple System Frameworks
if(APPLE)
    find_library(UIKIT_LIB UIKit REQUIRED)
    find_library(FOUNDATION_LIB Foundation REQUIRED)
    find_library(QUARTZCORE_LIB QuartzCore REQUIRED)
    find_library(COREGRAPHICS_LIB CoreGraphics REQUIRED)
    find_library(METAL_LIB Metal REQUIRED)
    find_library(METALKIT_LIB MetalKit REQUIRED)
    find_library(AVFOUNDATION_LIB AVFoundation REQUIRED)
    find_library(COREMOTION_LIB CoreMotion REQUIRED)
    find_library(AUDIOTOOLBOX_LIB AudioToolbox REQUIRED)

    target_link_libraries(L4D2IOS PRIVATE
        ${UIKIT_LIB}
        ${FOUNDATION_LIB}
        ${QUARTZCORE_LIB}
        ${COREGRAPHICS_LIB}
        ${METAL_LIB}
        ${METALKIT_LIB}
        ${AVFOUNDATION_LIB}
        ${COREMOTION_LIB}
        ${AUDIOTOOLBOX_LIB}
    )
endif()
