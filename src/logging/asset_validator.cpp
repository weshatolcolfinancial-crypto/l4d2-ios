#include "asset_validator.h"
#include "logger.h"
#include <filesystem>
#include <sstream>
#include <iomanip>

namespace fs = std::filesystem;

namespace l4d2 {

AssetValidationResult AssetValidator::validateGameDirectory(const std::string& baseDocumentsPath) {
    AssetValidationResult result;
    result.rootPath = baseDocumentsPath;
    result.isValid = false;
    result.totalSizeBytes = 0;

    L4D2_LOG_ASSET("Validator", "Validating game content in: %s", baseDocumentsPath.c_str());

    std::error_code ec;
    if (!fs::exists(baseDocumentsPath, ec)) {
        result.missingFiles.push_back(baseDocumentsPath + " (directory does not exist)");
        result.summary = "Documents directory not found.";
        L4D2_LOG_ERROR("Validator", "%s", result.summary.c_str());
        return result;
    }

    // Critical files required for Left 4 Dead 2 to initialize
    const std::vector<std::string> criticalFiles = {
        "left4dead2/gameinfo.txt",
        "left4dead2/pak01_dir.vpk"
    };

    // Recommended files for full campaign & sound experience
    const std::vector<std::string> recommendedFiles = {
        "left4dead2/left4dead2_dir.vpk",
        "hl2/hl2_dir.vpk",
        "left4dead2/sound.cache"
    };

    // Check critical files
    for (const auto& relPath : criticalFiles) {
        fs::path fullPath = fs::path(baseDocumentsPath) / relPath;
        if (fs::exists(fullPath, ec)) {
            result.foundFiles.push_back(relPath);
            result.totalSizeBytes += fs::file_size(fullPath, ec);
            L4D2_LOG_ASSET("Validator", "Found critical file: %s", relPath.c_str());
        } else {
            result.missingFiles.push_back(relPath);
            L4D2_LOG_ERROR("Validator", "Missing critical file: %s", relPath.c_str());
        }
    }

    // Check recommended files
    for (const auto& relPath : recommendedFiles) {
        fs::path fullPath = fs::path(baseDocumentsPath) / relPath;
        if (fs::exists(fullPath, ec)) {
            result.foundFiles.push_back(relPath);
            result.totalSizeBytes += fs::file_size(fullPath, ec);
            L4D2_LOG_ASSET("Validator", "Found asset: %s", relPath.c_str());
        } else {
            result.warnings.push_back("Recommended asset not found: " + relPath);
            L4D2_LOG_WARN("Validator", "Missing recommended asset: %s (game may have missing textures/sounds)", relPath.c_str());
        }
    }

    // Check total directory size if left4dead2 folder exists
    fs::path l4d2Dir = fs::path(baseDocumentsPath) / "left4dead2";
    if (fs::exists(l4d2Dir, ec) && fs::is_directory(l4d2Dir, ec)) {
        for (const auto& entry : fs::recursive_directory_iterator(l4d2Dir, fs::directory_options::skip_permission_denied, ec)) {
            if (entry.is_regular_file(ec)) {
                result.totalSizeBytes += entry.file_size(ec);
            }
        }
    }

    // Determine validity
    result.isValid = result.missingFiles.empty();

    double sizeInGB = static_cast<double>(result.totalSizeBytes) / (1024.0 * 1024.0 * 1024.0);
    std::ostringstream ss;
    ss << std::fixed << std::setprecision(2);
    if (result.isValid) {
        ss << "Asset check PASSED. Total game content detected: " << sizeInGB << " GB across " 
           << result.foundFiles.size() << " primary archives.";
        result.summary = ss.str();
        L4D2_LOG_INFO("Validator", "%s", result.summary.c_str());
    } else {
        ss << "Asset check FAILED. " << result.missingFiles.size() << " critical files are missing. "
           << "Found " << sizeInGB << " GB.";
        result.summary = ss.str();
        L4D2_LOG_ERROR("Validator", "%s", result.summary.c_str());
    }

    return result;
}

std::string AssetValidator::getTroubleshootingGuide(const AssetValidationResult& result) {
    std::ostringstream ss;
    ss << "=== Left 4 Dead 2 iOS Asset Setup ===\n\n";
    if (result.isValid) {
        ss << "All critical assets found!\n";
        return ss.str();
    }

    ss << "Missing Critical Files:\n";
    for (const auto& file : result.missingFiles) {
        ss << "  ❌ " << file << "\n";
    }

    ss << "\nHow to Import Steam PC Content:\n";
    ss << "1. Run the PC asset downloader:\n";
    ss << "   python tools/download_steam_assets.py\n";
    ss << "   (Downloads clean Steam content using steamcmd)\n\n";
    ss << "2. Transfer to iOS Device:\n";
    ss << "   Option A: Connect iPhone/iPad to PC via USB -> Open iTunes / Apple Devices / Finder\n";
    ss << "             -> Select 'File Sharing' -> 'L4D2 iOS' -> Drag the 'left4dead2' and 'hl2' folders.\n";
    ss << "   Option B: Open the iOS 'Files' app on your device -> 'On My iPhone' -> 'L4D2 iOS'\n";
    ss << "             -> Place 'left4dead2' folder directly inside.\n\n";
    ss << "Log file location: Documents/debug.log\n";

    return ss.str();
}

} // namespace l4d2
