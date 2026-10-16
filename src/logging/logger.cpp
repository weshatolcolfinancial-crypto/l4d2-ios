#include "logger.h"
#include <iostream>
#include <chrono>
#include <ctime>
#include <iomanip>
#include <sstream>

#if defined(__APPLE__)
#include <TargetConditionals.h>
#include <os/log.h>
#endif

namespace l4d2 {

Logger& Logger::getInstance() {
    static Logger instance;
    return instance;
}

Logger::Logger() : m_initialized(false) {}

Logger::~Logger() {
    shutdown();
}

void Logger::initialize(const std::string& logFilePath) {
    std::lock_guard<std::mutex> lock(m_mutex);
    m_logFilePath = logFilePath;
    m_fileStream.open(m_logFilePath, std::ios::out | std::ios::trunc);
    m_initialized = m_fileStream.is_open();

    if (m_initialized) {
        m_fileStream << "====================================================\n";
        m_fileStream << " Left 4 Dead 2 iOS Port Diagnostic Log\n";
        m_fileStream << " Started: " << getCurrentTimestamp() << "\n";
        m_fileStream << "====================================================\n";
        m_fileStream.flush();
    }
}

void Logger::shutdown() {
    std::lock_guard<std::mutex> lock(m_mutex);
    if (m_fileStream.is_open()) {
        m_fileStream << "\n--- Engine Shutdown: " << getCurrentTimestamp() << " ---\n";
        m_fileStream.flush();
        m_fileStream.close();
    }
    m_initialized = false;
}

std::string Logger::getCurrentTimestamp() {
    auto now = std::chrono::system_clock::now();
    auto in_time_t = std::chrono::system_clock::to_time_t(now);
    auto ms = std::chrono::duration_cast<std::chrono::milliseconds>(now.time_since_epoch()) % 1000;

    std::tm time_info;
#if defined(_WIN32)
    localtime_s(&time_info, &in_time_t);
#else
    localtime_r(&in_time_t, &time_info);
#endif

    std::ostringstream ss;
    ss << std::put_time(&time_info, "%H:%M:%S") << '.' << std::setfill('0') << std::setw(3) << ms.count();
    return ss.str();
}

const char* Logger::levelToString(LogLevel level) {
    switch (level) {
        case LogLevel::DEBUG:   return "DEBUG";
        case LogLevel::INFO:    return "INFO";
        case LogLevel::WARN:    return "WARN";
        case LogLevel::ERROR:   return "ERROR";
        case LogLevel::ASSET:   return "ASSET";
        case LogLevel::RENDER:  return "RENDER";
        case LogLevel::INPUT:   return "INPUT";
        default:                return "GENERIC";
    }
}

void Logger::log(LogLevel level, const char* tag, const char* fmt, ...) {
    va_list args;
    va_start(args, fmt);
    logV(level, tag, fmt, args);
    va_end(args);
}

void Logger::logV(LogLevel level, const char* tag, const char* fmt, va_list args) {
    va_list argsCopy;
    va_copy(argsCopy, args);

    // Calculate required buffer size
    int len = vsnprintf(nullptr, 0, fmt, args);
    if (len <= 0) {
        va_end(argsCopy);
        return;
    }

    std::vector<char> buffer(len + 1);
    vsnprintf(buffer.data(), buffer.size(), fmt, argsCopy);
    va_end(argsCopy);

    std::string message(buffer.data());
    std::string timestamp = getCurrentTimestamp();
    const char* lvlStr = levelToString(level);

    std::lock_guard<std::mutex> lock(m_mutex);

    // 1. Write to in-memory ring buffer for on-screen debug console
    LogEntry entry{level, timestamp, tag ? tag : "L4D2", message};
    if (m_ringBuffer.size() >= m_maxRingBufferSize) {
        m_ringBuffer.erase(m_ringBuffer.begin());
    }
    m_ringBuffer.push_back(entry);

    // 2. Write to disk (Documents/debug.log)
    if (m_fileStream.is_open()) {
        m_fileStream << "[" << timestamp << "] [" << lvlStr << "] [" << entry.tag << "] " << message << "\n";
        m_fileStream.flush();
    }

    // 3. Output to terminal / Xcode console / os_log
    fprintf(stdout, "[%s] [%s] [%s] %s\n", timestamp.c_str(), lvlStr, entry.tag.c_str(), message.c_str());
    fflush(stdout);
#if defined(__APPLE__)
    os_log_with_type(OS_LOG_DEFAULT, OS_LOG_TYPE_DEFAULT, "[%{public}s] [%{public}s] %{public}s", lvlStr, entry.tag.c_str(), message.c_str());
#endif
}

std::vector<LogEntry> Logger::getRecentLogs(size_t maxCount) {
    std::lock_guard<std::mutex> lock(m_mutex);
    if (m_ringBuffer.size() <= maxCount) {
        return m_ringBuffer;
    }
    return std::vector<LogEntry>(m_ringBuffer.end() - maxCount, m_ringBuffer.end());
}

void Logger::clearRecentLogs() {
    std::lock_guard<std::mutex> lock(m_mutex);
    m_ringBuffer.clear();
}

void Logger::flush() {
    std::lock_guard<std::mutex> lock(m_mutex);
    if (m_fileStream.is_open()) {
        m_fileStream.flush();
    }
}

// Source Engine SpewOutputFunc hook
void Logger::spewOutputAdapter(int spewType, const char* msg) {
    if (!msg) return;
    
    // Clean trailing newlines
    std::string cleanMsg = msg;
    while (!cleanMsg.empty() && (cleanMsg.back() == '\n' || cleanMsg.back() == '\r')) {
        cleanMsg.pop_back();
    }
    if (cleanMsg.empty()) return;

    LogLevel level = LogLevel::INFO;
    switch (spewType) {
        case 0: level = LogLevel::INFO;  break; // SPEW_MESSAGE
        case 1: level = LogLevel::WARN;  break; // SPEW_WARNING
        case 2: level = LogLevel::ERROR; break; // SPEW_ASSERT
        case 3: level = LogLevel::ERROR; break; // SPEW_ERROR
        case 4: level = LogLevel::INFO;  break; // SPEW_LOG
        default: level = LogLevel::INFO; break;
    }

    Logger::getInstance().log(level, "SourceEngine", "%s", cleanMsg.c_str());
}

} // namespace l4d2
