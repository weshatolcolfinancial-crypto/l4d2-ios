#pragma once

#include <string>
#include <vector>
#include <cstdint>

namespace l4d2 {

struct AssetValidationResult {
    bool isValid = false;
    std::string rootPath;
    std::vector<std::string> foundFiles;
    std::vector<std::string> missingFiles;
    std::vector<std::string> warnings;
    uint64_t totalSizeBytes = 0;
    std::string summary;
};

class AssetValidator {
public:
    static AssetValidationResult validateGameDirectory(const std::string& baseDocumentsPath);
    
    // Generates a user-friendly troubleshooting guide when files are missing
    static std::string getTroubleshootingGuide(const AssetValidationResult& result);
};

} // namespace l4d2
