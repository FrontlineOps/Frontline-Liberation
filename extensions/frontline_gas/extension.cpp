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
// Reference fields are isolated from gameplay fields and bounded independently.
// The key contains exact initial state/topology/terrain and the heat schedule;
// no ammo classname, rounded physical value or world coordinate is a cache key.
struct Reference {
    flgas::Domain field;
    double end;
    std::size_t source;
    double heat;
    double heatAdded = 0;
    explicit Reference(const flgas::Domain& initial, double until, std::size_t cell, double remaining)
        : field(initial), end(until), source(cell), heat(remaining) {}
    bool ready() const { return field.time >= end - 1e-12; }
};
struct Terrain {
    std::vector<int> faces;
};
constexpr std::size_t maxReferences = 16;
std::map<int, Terrain> terrains;
std::map<int, std::shared_ptr<Reference>> references;
std::map<std::string, std::shared_ptr<Reference>> referenceCache;
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
        output << "[4," << flgas::maxCells << ',' << maxDomains << ',' << maxBatch << ']';
        return output.str();
    }
    if (command == "reset") {
        args.size(0);
        domains.clear();
        terrains.clear();
        references.clear();
        referenceCache.clear();
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
    const std::map<std::string, unsigned int> counts{{"release", 1}, {"fill", 9}, {"advance", 4}, {"sample", 3}, {"cells", 3}, {"stats", 1}, {"faces", 3}, {"walls", 4}, {"heat", 3}, {"samples", 0}, {"openings", 0}, {"refWalls", 4}, {"geometry", 5}, {"refBegin", 4}, {"refAdvance", 1}, {"refStats", 1}, {"responseSamples", 0}};
    const auto expected = counts.find(command);
    require(expected != counts.end(), "Unknown command");
    if (command == "samples" || command == "responseSamples") {
        require(args.count >= 2 && args.count <= 9, "Expected one to eight sample indices");
    } else if (command == "openings") {
        require(args.count >= 3 && args.count <= 10, "Expected one to eight opening fractions");
    } else {
        args.size(expected->second);
    }
    const int id = args.integer(0, 1, 16000000);
    const auto found = domains.find(id);
    require(found != domains.end(), "Unknown or released domain handle");
    auto& d = *found->second;
    if (command == "refWalls" || command == "geometry") {
        const auto first = static_cast<std::size_t>(args.integer(1, 0, 24575));
        const auto count = static_cast<std::size_t>(args.integer(2, 1, 16));
        const auto mask = static_cast<unsigned int>(args.integer(command == "geometry" ? 4 : 3, 0, 65535));
        const auto actual = static_cast<unsigned int>(args.integer(3, 0, 65535));
        require(d.time == 0 && !references.count(id), "Reference geometry already sealed");
        require(first < d.faces.size() && count <= d.faces.size() - first && mask < (1u << count) && actual < (1u << count), "Invalid reference face range or mask");
        if (command == "geometry") { d.walls(first, count, actual); }
        auto& terrain = terrains[id].faces;
        if (terrain.empty()) { terrain.assign(d.faces.size(), -1); }
        for (std::size_t i = 0; i < count; ++i) { terrain[first + i] = (mask >> i) & 1u; }
        return "[]";
    }
    if (command == "refBegin") {
        const double end = args.number(1);
        const auto source = static_cast<std::size_t>(args.integer(2, 0, 4095));
        const double heat = args.number(3);
        require(end > 0 && end <= 5 && source < d.cells.size() && heat >= 0 && heat <= 1e10, "Invalid reference schedule");
        require(d.time == 0 && !references.count(id), "Reference already started");
        const auto terrain = terrains.find(id);
        require(terrain != terrains.end() && std::find(terrain->second.faces.begin(), terrain->second.faces.end(), -1) == terrain->second.faces.end(), "Reference terrain incomplete");
        std::string cacheKey;
        cacheKey.reserve(d.cells.size() * sizeof(flgas::State) + d.faces.size() * 32 + 128);
        const auto append = [&cacheKey](const auto& value) {
            cacheKey.append(reinterpret_cast<const char*>(&value), sizeof(value));
        };
        append(d.cells.size());
        append(d.faces.size());
        append(d.spacing);
        append(d.gamma);
        append(end);
        append(source);
        append(heat);
        for (const auto value : d.ambient) { append(value); }
        for (const auto& cell : d.cells) { for (const auto value : cell) { append(value); } }
        for (std::size_t i = 0; i < d.faces.size(); ++i) {
            const auto& face = d.faces[i];
            append(face.a);
            append(face.b);
            append(face.axis);
            append(face.sign);
            append(static_cast<int>(face.boundary));
            append(terrain->second.faces[i]);
        }
        const auto cached = referenceCache.find(cacheKey);
        const bool hit = cached != referenceCache.end();
        std::shared_ptr<Reference> reference;
        if (hit) {
            reference = cached->second;
        } else {
            if (referenceCache.size() >= maxReferences) {
                const auto spare = std::find_if(referenceCache.begin(), referenceCache.end(), [](const auto& item) { return item.second.use_count() == 1; });
                require(spare != referenceCache.end(), "Reference cache busy");
                referenceCache.erase(spare);
            }
            reference = std::make_shared<Reference>(d, end, source, heat);
            for (std::size_t i = 0; i < d.faces.size(); ++i) {
                auto& face = reference->field.faces[i];
                face.blocked = terrain->second.faces[i] != 0;
                face.opening = face.blocked ? 0 : 1;
            }
            referenceCache.emplace(cacheKey, reference);
        }
        references.emplace(id, reference);
        terrains.erase(terrain);
        output << '[' << hit << ',' << reference->ready() << ']';
        return output.str();
    }
    if (command == "refAdvance" || command == "refStats") {
        const auto reference = references.find(id);
        require(reference != references.end(), "Reference unavailable");
        auto& ref = *reference->second;
        double elapsed = 0;
        if (command == "refAdvance" && !ref.ready()) {
            const auto start = std::chrono::steady_clock::now();
            for (int step = 0; step < maxBatch && !ref.ready() && elapsed < budgetMs; ++step) {
                ref.field.step(std::min(0.04, ref.end - ref.field.time), 0.4);
                // Heat is time-based and applied every step in both fields.
                const double desired = ref.heat * std::min(1.0, ref.field.time / (0.5 * ref.end));
                if (desired > ref.heatAdded) {
                    ref.field.heat(ref.source, desired - ref.heatAdded);
                    ref.heatAdded = desired;
                }
                elapsed = std::chrono::duration<double, std::milli>(std::chrono::steady_clock::now() - start).count();
            }
        }
        output << '[' << ref.ready() << ',' << ref.field.time << ',' << ref.field.steps << ',' << elapsed << ',' << referenceCache.size();
        if (command == "refStats") {
            output << ','; array(output, ref.field.initialTotals);
            output << ','; array(output, ref.field.injected);
            output << ','; array(output, ref.field.boundaryTransfer);
            output << ','; array(output, ref.field.totals());
        }
        output << ']';
        return output.str();
    }
    if (command == "openings") {
        std::vector<double> fractions;
        for (unsigned int i = 2; i < args.count; ++i) {
            fractions.push_back(args.number(i));
        }
        d.openings(static_cast<std::size_t>(args.integer(1, 0, 24575)), fractions);
        return "[]";
    }
    if (command == "release") {
        references.erase(id);
        terrains.erase(id);
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
    if (command == "samples" || command == "responseSamples") {
        const auto reference = references.find(id);
        if (command == "responseSamples") { require(reference != references.end() && reference->second->ready(), "Reference not ready"); }
        output << '[';
        for (unsigned int i = 1; i < args.count; ++i) {
            if (i > 1) { output << ','; }
            const auto cell = static_cast<std::size_t>(args.integer(i, 0, 4095));
            const auto sample = d.sample(cell);
            std::vector<double> values(sample.begin(), sample.end());
            if (command == "responseSamples") {
                values.push_back(reference->second->field.peak.at(cell));
                values.push_back(reference->second->field.positiveImpulse.at(cell));
            }
            array(output, values);
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
            const auto reference = references.find(id);
            if (reference != references.end() && reference->second->heat > 0) {
                const auto& ref = *reference->second;
                const double previous = ref.heat * std::min(1.0, (d.time - lastDt) / (0.5 * ref.end));
                const double desired = ref.heat * std::min(1.0, d.time / (0.5 * ref.end));
                if (desired > previous) { d.heat(ref.source, desired - previous); }
            }
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
    write(output, outputSize, "Frontline Gas 4.0.0 / terrain reference response");
}

FL_EXPORT void FL_CALL RVExtension(char* output, unsigned int outputSize, const char* function) {
    if (function && std::strcmp(function, "version") == 0) {
        write(output, outputSize, "[4,4096,8,8]");
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
