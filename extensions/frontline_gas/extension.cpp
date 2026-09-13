#include "gas.hpp"

#include <algorithm>
#include <chrono>
#include <cmath>
#include <cstring>
#include <iomanip>
#include <locale>
#include <limits>
#include <map>
#include <memory>
#include <mutex>
#include <sstream>
#include <stdexcept>
#include <string>

#ifdef _WIN32
#define FL_EXPORT extern "C" __declspec(dllexport)
#define FL_CALL __stdcall
#else
#define FL_EXPORT extern "C" __attribute__((visibility("default")))
#define FL_CALL
#endif

namespace {
constexpr std::size_t maxDomains = 8;
constexpr int maxBatch = 8;
constexpr unsigned int minBuffer = 4096;
constexpr double budgetMs = 2;
std::mutex guard;
std::map<int, std::unique_ptr<flgas::Domain>> domains;
// Never reuse a handle after release/reset: stale mission handles cannot alias.
int nextHandle = 1;

void require(bool valid, const char* message) {
    if (!valid) {
        throw std::invalid_argument(message);
    }
}

bool write(char* output, unsigned int size, const std::string& text) {
    if (!output || size == 0) {
        return false;
    }
    output[0] = '\0';
    if (text.size() >= size) {
        return false;
    }
    std::memcpy(output, text.c_str(), text.size() + 1);
    return true;
}

template <class Range>
void array(std::ostream& output, const Range& values) {
    output << '[';
    bool first = true;
    for (const auto& value : values) {
        require(std::isfinite(static_cast<double>(value)) && std::abs(static_cast<double>(value)) <= std::numeric_limits<float>::max(), "Result exceeds SQF numeric range");
        if (!first) {
            output << ',';
        }
        output << value;
        first = false;
    }
    output << ']';
}

struct Arguments {
    const char** values;
    unsigned int count;

    void size(unsigned int expected) const {
        require(count == expected && (count == 0 || values), "Wrong argument count");
    }

    double number(unsigned int index) const {
        require(index < count && values && values[index], "Missing numeric argument");
        // Fixed, small numeric tokens only. Classic locale accepts decimal dots
        // irrespective of the dedicated server's operating-system language.
        const char* value = values[index];
        std::size_t length = 0;
        while (length < 64 && value[length]) {
            ++length;
        }
        require(length > 0 && length < 64, "Invalid numeric token length");
        std::istringstream input(std::string(value, length));
        input.imbue(std::locale::classic());
        double result = 0;
        input >> result;
        require(!input.fail(), "Invalid number");
        input >> std::ws;
        require(input.eof() && std::isfinite(result), "Invalid finite number");
        return result;
    }

    int integer(unsigned int index, int low, int high) const {
        const double value = number(index);
        require(value >= low && value <= high && value == std::floor(value), "Integer outside supported bounds");
        return static_cast<int>(value);
    }

    flgas::State state(unsigned int first) const {
        flgas::State result{};
        for (unsigned int i = 0; i < result.size(); ++i) {
            result[i] = number(first + i);
        }
        return result;
    }
};

std::string dispatch(const std::string& command, const Arguments& args) {
    std::ostringstream output;
    output.imbue(std::locale::classic());
    output << std::setprecision(17);
    if (command == "version") {
        args.size(0);
        output << "[2," << flgas::maxCells << ',' << maxDomains << ',' << maxBatch << ']';
        return output.str();
    }
    if (command == "reset") {
        args.size(0);
        domains.clear();
        return "[]";
    }
    if (command == "status") {
        args.size(0);
        std::vector<int> handles;
        for (const auto& entry : domains) {
            handles.push_back(entry.first);
        }
        array(output, handles);
        return output.str();
    }
    if (command == "create") {
        args.size(17);
        require(domains.size() < maxDomains, "Active domain cap reached");
        require(nextHandle <= 16000000, "Handle range exhausted; restart server");
        const std::array<int, 3> dims{args.integer(0, 1, 4096), args.integer(1, 1, 4096), args.integer(2, 1, 4096)};
        std::array<flgas::Boundary, 6> boundaries{};
        for (unsigned int i = 0; i < boundaries.size(); ++i) {
            boundaries[i] = static_cast<flgas::Boundary>(args.integer(11 + i, 0, 2));
        }
        auto domain = std::make_unique<flgas::Domain>(dims, args.number(3), args.state(5), args.number(4), boundaries);
        output << '[' << nextHandle << ',' << domain->cells.size() << ']';
        domains.emplace(nextHandle++, std::move(domain));
        return output.str();
    }
    // Reject an unknown command before it can address a domain.
    const std::map<std::string, unsigned int> counts{{"release", 1}, {"fill", 9}, {"advance", 4}, {"sample", 3}, {"cells", 3}, {"stats", 1}, {"faces", 3}, {"walls", 4}, {"heat", 3}, {"samples", 0}};
    const auto expected = counts.find(command);
    require(expected != counts.end(), "Unknown command");
    if (command == "samples") {
        require(args.count >= 2 && args.count <= 9, "Expected one to eight sample indices");
    } else {
        args.size(expected->second);
    }
    const int id = args.integer(0, 1, 16000000);
    const auto found = domains.find(id);
    require(found != domains.end(), "Unknown or released domain handle");
    auto& d = *found->second;
    if (command == "release") {
        domains.erase(found);
        return "[]";
    }
    if (command == "faces") {
        const auto first = static_cast<std::size_t>(args.integer(1, 0, 24575));
        const auto count = static_cast<std::size_t>(args.integer(2, 1, 16));
        require(first < d.faces.size(), "Invalid face start");
        output << '[';
        for (std::size_t i = first; i < std::min(first + count, d.faces.size()); ++i) {
            if (i != first) { output << ','; }
            const auto& f = d.faces[i];
            output << '[' << f.a << ',' << f.b << ',' << f.axis << ',' << f.sign << ']';
        }
        output << ']';
        return output.str();
    }
    if (command == "walls") {
        d.walls(static_cast<std::size_t>(args.integer(1, 0, 24575)), static_cast<std::size_t>(args.integer(2, 1, 16)),
            static_cast<unsigned int>(args.integer(3, 0, 65535)));
        return "[]";
    }
    if (command == "heat") {
        d.heat(static_cast<std::size_t>(args.integer(1, 0, 4095)), args.number(2));
        return "[]";
    }
    if (command == "samples") {
        output << '[';
        for (unsigned int i = 1; i < args.count; ++i) {
            if (i > 1) { output << ','; }
            array(output, d.sample(static_cast<std::size_t>(args.integer(i, 0, 4095))));
        }
        output << ']';
        return output.str();
    }
    if (command == "fill") {
        const auto first = static_cast<std::size_t>(args.integer(1, 0, 4095));
        const auto count = static_cast<std::size_t>(args.integer(2, 1, 4096));
        d.fill(first, count, args.state(3));
        return "[]";
    }
    if (command == "advance") {
        const double interval = args.number(1);
        const int limit = args.integer(2, 1, maxBatch);
        const double cfl = args.number(3);
        require(interval > 0 && interval <= 1e6 && cfl > 0 && cfl <= 0.5, "Invalid interval or CFL");
        const double target = d.time + interval;
        require(target > d.time, "Interval below numerical resolution");
        const auto start = std::chrono::steady_clock::now();
        double lastDt = 0;
        double elapsed = 0;
        int performed = 0;
        while (performed < limit && d.time < target && elapsed < budgetMs) {
            lastDt = d.step(target - d.time, cfl);
            ++performed;
            elapsed = std::chrono::duration<double, std::milli>(std::chrono::steady_clock::now() - start).count();
        }
        output << '[' << d.time << ',' << d.steps << ',' << lastDt << ',' << performed << ',' << elapsed << ']';
        return output.str();
    }
    if (command == "sample") {
        array(output, d.sample(static_cast<std::size_t>(args.integer(1, 0, 4095)), args.number(2)));
        return output.str();
    }
    if (command == "cells") {
        const auto first = static_cast<std::size_t>(args.integer(1, 0, 4095));
        const auto count = static_cast<std::size_t>(args.integer(2, 1, 16));
        require(first < d.cells.size() && count <= d.cells.size() - first, "Invalid cell range");
        output << '[';
        for (std::size_t i = first; i < first + count; ++i) {
            if (i != first) {
                output << ',';
            }
            array(output, d.cells[i]);
        }
        output << ']';
        return output.str();
    }
    output << '[' << d.time << ',' << d.steps << ',' << d.cells.size() << ',' << d.spacing << ',' << d.gamma << ',' << d.ambientPressure << ',';
    array(output, d.initialTotals);
    output << ',';
    array(output, d.injected);
    output << ',';
    array(output, d.boundaryTransfer);
    output << ',';
    array(output, d.totals());
    output << ',' << d.faces.size() << ']';
    return output.str();
}
}

FL_EXPORT void FL_CALL RVExtensionVersion(char* output, unsigned int outputSize) {
    write(output, outputSize, "Frontline Gas 2.0.0 / generic game integration");
}

FL_EXPORT void FL_CALL RVExtension(char* output, unsigned int outputSize, const char* function) {
    if (function && std::strcmp(function, "version") == 0) {
        write(output, outputSize, "[2,4096,8,8]");
    } else {
        write(output, outputSize, "[\"Use the array callExtension interface\"]");
    }
}

FL_EXPORT int FL_CALL RVExtensionArgs(char* output, unsigned int outputSize, const char* function, const char** argv, unsigned int argc) {
    // No code evaluation, network, filesystem, callbacks or worker threads.
    // Buffer rejection precedes mutation; no unterminated/truncated responses.
    if (!output || outputSize < minBuffer) {
        write(output, outputSize, "[]");
        return 5;
    }
    try {
        require(function && std::strlen(function) <= 16 && argc <= 17, "Invalid command envelope");
        const std::lock_guard<std::mutex> lock(guard);
        const auto result = dispatch(function, {argv, argc});
        if (!write(output, outputSize, result)) {
            return 5;
        }
        return 0;
    } catch (const std::invalid_argument& error) {
        write(output, outputSize, std::string("[\"") + error.what() + "\"]");
        return 1;
    } catch (...) {
        write(output, outputSize, "[\"Native backend error\"]");
        return 2;
    }
}
