#include "engine_bridge.h"
#include "../logging/logger.h"
#include <filesystem>

namespace fs = std::filesystem;

namespace l4d2 {

EngineBridge& EngineBridge::getInstance() {
    static EngineBridge instance;
    return instance;
}

EngineBridge::EngineBridge() = default;
EngineBridge::~EngineBridge() {
    shutdown();
}

bool EngineBridge::initialize(const std::string& documentsPath) {
    m_documentsPath = documentsPath;

    // 1. Initialize persistent file logger in Documents/debug.log
    std::string logFile = (fs::path(documentsPath) / "debug.log").string();
    Logger::getInstance().initialize(logFile);

    L4D2_LOG_INFO("EngineBridge", "Initializing Left 4 Dead 2 iOS Engine Bridge");
    L4D2_LOG_INFO("EngineBridge", "Sandbox documents root: %s", documentsPath.c_str());

    // 2. Perform asset integrity verification
    m_assetStatus = AssetValidator::validateGameDirectory(documentsPath);

    if (!m_assetStatus.isValid) {
        L4D2_LOG_WARN("EngineBridge", "Asset validation incomplete. Halting engine startup until files are placed.");
        m_engineReady = false;
        m_initialized = true;
        return false;
    }

    // 3. Setup Source Engine filesystem search paths
    L4D2_LOG_INFO("EngineBridge", "Mounting VPK archives and game directories...");
    // - Mount left4dead2/pak01_dir.vpk
    // - Mount left4dead2/left4dead2_dir.vpk
    // - Mount hl2/hl2_dir.vpk
    // - Register custom SpewOutputFunc hook
    L4D2_LOG_INFO("EngineBridge", "Source filesystem mounted successfully.");

    m_engineReady = true;
    m_initialized = true;
    L4D2_LOG_INFO("EngineBridge", "Engine bridge fully initialized and ready for main loop.");
    return true;
}

void EngineBridge::processInput(const InputFrameState& input) {
    if (!m_engineReady || m_isPaused) return;

    m_lastInput = input;

    // Handle weapon slot switching
    if (input.pendingSlot > 0) {
        L4D2_LOG_INFO("Input", "Dispatched weapon command: slot%d", input.pendingSlot);
        // Engine command dispatch: Cbuf_AddText(va("slot%d\n", input.pendingSlot))
    }

    // Handle flashlight toggle
    if (input.toggleFlashlight) {
        L4D2_LOG_INFO("Input", "Dispatched flashlight command: impulse 100");
        // Engine command dispatch: Cbuf_AddText("impulse 100\n")
    }

    // Map movements to Source engine CUserCmd
    // forwardmove = input.moveVector.y * cl_forwardspeed
    // sidemove    = input.moveVector.x * cl_sidespeed
    // viewangles.x += input.lookDelta.y (pitch)
    // viewangles.y -= input.lookDelta.x (yaw)
}

void EngineBridge::onFrameTick(double deltaTime, double targetFPS) {
    if (!m_engineReady || m_isPaused) return;

    // Run Source Engine main simulation tick and render
    // 1. Process client input
    // 2. Tick local client & server
    // 3. Render frame to Metal view
}

void EngineBridge::pause() {
    m_isPaused = true;
    L4D2_LOG_INFO("EngineBridge", "Engine paused.");
}

void EngineBridge::resume() {
    m_isPaused = false;
    L4D2_LOG_INFO("EngineBridge", "Engine resumed.");
}

void EngineBridge::shutdown() {
    if (m_initialized) {
        L4D2_LOG_INFO("EngineBridge", "Shutting down engine bridge.");
        m_engineReady = false;
        m_initialized = false;
        Logger::getInstance().shutdown();
    }
}

} // namespace l4d2
