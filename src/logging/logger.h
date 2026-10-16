#pragma once

#include <string>
#include <vector>
#include <mutex>
#include <fstream>
#include <functional>
#include <cstdarg>

namespace l4d2 {

enum class LogLevel {
    DEBUG,
    INFO,
    WARN,
    ERROR,
    ASSET,
    RENDER,
    INPUT
};

struct LogEntry {
    LogLevel level;
    std::string timestamp;
    std::string tag;
    std::string message;
};

class Logger {
public:
    static Logger& getInstance();

    // Initialize logger with custom output path (e.g. iOS Documents/debug.log)
    void initialize(const std::string& logFilePath);
    void shutdown();

    void log(LogLevel level, const char* tag, const char* fmt, ...);
    void logV(LogLevel level, const char* tag, const char* fmt, va_list args);

    // Retrieve recent logs for on-screen debug console
    std::vector<LogEntry> getRecentLogs(size_t maxCount = 100);
    void clearRecentLogs();

    // Direct path to the log file on disk
    std::string getLogFilePath() const { return m_logFilePath; }

    // Flush pending file writes
    void flush();

    // Valve Source Engine SpewOutputFunc hook adapter
    static void spewOutputAdapter(int spewType, const char* msg);

private:
    Logger();
    ~Logger();

    Logger(const Logger&) = delete;
    Logger& operator=(const Logger&) = delete;

    std::string getCurrentTimestamp();
    const char* levelToString(LogLevel level);

    std::mutex m_mutex;
    std::string m_logFilePath;
    std::ofstream m_fileStream;
    std::vector<LogEntry> m_ringBuffer;
    size_t m_maxRingBufferSize = 250;
    bool m_initialized = false;
};

// Convenience macros
#define L4D2_LOG_DEBUG(tag, fmt, ...) l4d2::Logger::getInstance().log(l4d2::LogLevel::DEBUG, tag, fmt, ##__VA_ARGS__)
#define L4D2_LOG_INFO(tag, fmt, ...)  l4d2::Logger::getInstance().log(l4d2::LogLevel::INFO,  tag, fmt, ##__VA_ARGS__)
#define L4D2_LOG_WARN(tag, fmt, ...)  l4d2::Logger::getInstance().log(l4d2::LogLevel::WARN,  tag, fmt, ##__VA_ARGS__)
#define L4D2_LOG_ERROR(tag, fmt, ...) l4d2::Logger::getInstance().log(l4d2::LogLevel::ERROR, tag, fmt, ##__VA_ARGS__)
#define L4D2_LOG_ASSET(tag, fmt, ...) l4d2::Logger::getInstance().log(l4d2::LogLevel::ASSET, tag, fmt, ##__VA_ARGS__)

} // namespace l4d2
