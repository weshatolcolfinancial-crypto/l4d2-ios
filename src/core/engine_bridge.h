#pragma once

#include "types.h"
#include "../logging/asset_validator.h"
#include <string>

namespace l4d2 {

class EngineBridge {
public:
    static EngineBridge& getInstance();

    // Setup logging, directories, and asset validation
    bool initialize(const std::string& documentsPath);

    // Frame tick called from CADisplayLink
    void onFrameTick(double deltaTime, double targetFPS);

    // Feed input state from touch controller
    void processInput(const InputFrameState& input);

    // Engine lifecycle
    void pause();
    void resume();
    void shutdown();

    bool isEngineReady() const { return m_engineReady; }
    const AssetValidationResult& getAssetStatus() const { return m_assetStatus; }
    std::string getDocumentsPath() const { return m_documentsPath; }

private:
    EngineBridge();
    ~EngineBridge();

    bool m_initialized = false;
    bool m_engineReady = false;
    bool m_isPaused = false;
    std::string m_documentsPath;
    AssetValidationResult m_assetStatus;
    InputFrameState m_lastInput;
};

} // namespace l4d2
