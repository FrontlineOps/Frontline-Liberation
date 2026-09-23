#include "path.hpp"

#include <algorithm>
#include <charconv>
#include <chrono>
#include <cmath>
#include <cstring>
#include <iomanip>
#include <locale>
#include <mutex>
#include <sstream>
#include <stdexcept>
#include <string>
#include <string_view>

#ifdef _WIN32
#define FL_EXPORT extern "C" __declspec(dllexport)
#define FL_CALL __stdcall
#else
#define FL_EXPORT extern "C" __attribute__((visibility("default")))
#define FL_CALL
#endif

namespace {
constexpr unsigned int minBuffer = 4096;
constexpr int maxRoads = 500000;
constexpr int maxPage = 150;
std::mutex guard;
flpath::Grid grid;
std::vector<char> flagRows;
std::vector<char> heightRows;
bool gridReady = false;
std::vector<int> labels; // connected land, built on first use after gridSeal
flpath::Roads roads;
std::vector<char> roadSet;
bool roadsReady = false;
flpath::Result last;

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

// Integer-only bulk payloads: parsing is locale-independent and exact.
long long integer(std::string_view text, long long low, long long high) {
    long long value = 0;
    const auto parsed = std::from_chars(text.data(), text.data() + text.size(), value);
    require(parsed.ec == std::errc() && parsed.ptr == text.data() + text.size() && value >= low && value <= high, "Invalid integer field");
    return value;
}

template <class Visit>
void split(std::string_view text, char separator, Visit visit) {
    if (text.empty()) {
        return;
    }
    std::size_t begin = 0;
    while (true) {
        const std::size_t end = text.find(separator, begin);
        visit(text.substr(begin, end == std::string_view::npos ? std::string_view::npos : end - begin));
        if (end == std::string_view::npos) {
            return;
        }
        begin = end + 1;
    }
}

struct Arguments {
    const char** values;
    unsigned int count;

    void size(unsigned int expected) const {
        require(count == expected && (count == 0 || values), "Wrong argument count");
    }

    // Coordinates arrive as quoted toFixed strings: SQF number arguments keep
    // only six significant digits, which can move a position across a cell.
    double number(unsigned int index) const {
        require(index < count && values && values[index], "Missing numeric argument");
        const char* value = values[index];
        std::size_t length = 0;
        while (length < 64 && value[length]) {
            ++length;
        }
        if (length >= 2 && value[0] == '"' && value[length - 1] == '"') {
            ++value;
            length -= 2;
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

    int whole(unsigned int index, int low, int high) const {
        const double value = number(index);
        require(value >= low && value <= high && value == std::floor(value), "Integer outside supported bounds");
        return static_cast<int>(value);
    }

    // SQF passes string arguments with their surrounding quotes.
    std::string_view text(unsigned int index) const {
        require(index < count && values && values[index], "Missing string argument");
        std::string_view value(values[index]);
        require(value.size() >= 2 && value.front() == '"' && value.back() == '"', "Expected string argument");
        return value.substr(1, value.size() - 2);
    }
};

std::string dispatch(const std::string& command, const Arguments& args) {
    std::ostringstream output;
    output.imbue(std::locale::classic());
    if (command == "version") {
        args.size(0);
        output << "[1," << flpath::maxCells << ',' << maxRoads << ',' << maxPage << ']';
        return output.str();
    }
    if (command == "reset") {
        args.size(0);
        grid = {};
        flagRows.clear();
        heightRows.clear();
        gridReady = false;
        labels.clear();
        roads = {};
        roadSet.clear();
        roadsReady = false;
        last = {};
        return "[]";
    }
    if (command == "status") {
        args.size(0);
        output << '[' << gridReady << ',' << grid.cells << ',' << roadsReady << ',' << roads.x.size() << ']';
        return output.str();
    }
    if (command == "gridBegin") {
        args.size(2);
        const double size = args.number(0);
        require(size >= 1 && size <= 1000, "Invalid grid size");
        grid = {};
        grid.size = size;
        grid.cells = args.whole(1, 1, flpath::maxCells);
        grid.flags.assign(static_cast<std::size_t>(grid.side()) * grid.side(), 0);
        grid.heights.assign(static_cast<std::size_t>(grid.cells) * grid.cells, 0);
        flagRows.assign(grid.side(), 0);
        heightRows.assign(grid.cells, 0);
        gridReady = false;
        labels.clear();
        return "[]";
    }
    if (command == "gridFlags") {
        args.size(2);
        require(!flagRows.empty() && !gridReady, "Grid not open");
        const int row = args.whole(0, 0, grid.side() - 1);
        const auto text = args.text(1);
        require(static_cast<int>(text.size()) == grid.side(), "Flag row length mismatch");
        for (int x = 0; x < grid.side(); ++x) {
            require(text[x] >= '0' && text[x] <= '3', "Invalid flag");
            grid.flags[static_cast<std::size_t>(row) * grid.side() + x] = static_cast<unsigned char>(text[x] - '0');
        }
        flagRows[row] = 1;
        return "[]";
    }
    if (command == "gridHeights") {
        args.size(2);
        require(!heightRows.empty() && !gridReady, "Grid not open");
        const int row = args.whole(0, 0, grid.cells - 1);
        int x = 0;
        split(args.text(1), ',', [&](std::string_view field) {
            require(x < grid.cells, "Height row too long");
            grid.heights[static_cast<std::size_t>(row) * grid.cells + x++] = integer(field, -10000000, 10000000) / 100.0;
        });
        require(x == grid.cells, "Height row length mismatch");
        heightRows[row] = 1;
        return "[]";
    }
    if (command == "gridSeal") {
        args.size(0);
        const auto set = [](char value) { return value == 1; };
        require(!flagRows.empty() && std::all_of(flagRows.begin(), flagRows.end(), set)
            && std::all_of(heightRows.begin(), heightRows.end(), set), "Grid incomplete");
        gridReady = true;
        output << '[' << grid.cells << ']';
        return output.str();
    }
    if (command == "roadsBegin") {
        args.size(1);
        const int count = args.whole(0, 0, maxRoads);
        roads = {};
        roads.x.assign(count, 0);
        roads.y.assign(count, 0);
        roads.links.assign(count, {});
        roadSet.assign(count, 0);
        roadsReady = false;
        return "[]";
    }
    if (command == "roadsChunk") {
        args.size(2);
        require(!roadsReady, "Roads sealed");
        const int count = static_cast<int>(roads.x.size());
        int index = args.whole(0, 0, maxRoads);
        split(args.text(1), ';', [&](std::string_view entry) {
            require(index < count, "Road index out of range");
            int field = 0;
            roads.links[index].clear();
            split(entry, ',', [&](std::string_view value) {
                if (field == 0) {
                    roads.x[index] = integer(value, -10000000, 100000000) / 100.0;
                } else if (field == 1) {
                    roads.y[index] = integer(value, -10000000, 100000000) / 100.0;
                } else {
                    roads.links[index].push_back(static_cast<int>(integer(value, 0, count - 1)));
                }
                ++field;
            });
            require(field >= 2, "Road entry needs a position");
            roadSet[index++] = 1;
        });
        return "[]";
    }
    if (command == "roadsSeal") {
        args.size(0);
        require(std::all_of(roadSet.begin(), roadSet.end(), [](char value) { return value == 1; }), "Roads incomplete");
        roadsReady = true;
        output << '[' << roads.x.size() << ']';
        return output.str();
    }
    if (command == "find") {
        args.size(18);
        require(gridReady, "Grid not ready");
        const int kind = args.whole(0, 0, 1);
        flpath::Context context;
        context.destinationX = args.number(11);
        context.destinationY = args.number(12);
        context.approachRadius = args.number(13);
        context.threatRadius = args.number(14);
        context.congestionMultiplier = args.number(15);
        split(args.text(16), ';', [&](std::string_view entry) {
            long long values[3] = {};
            int field = 0;
            split(entry, ',', [&](std::string_view value) {
                require(field < 3, "Threat entry too long");
                values[field++] = integer(value, -10000000, 100000000);
            });
            require(field == 3, "Threat entry needs x,y,strength");
            context.threats.push_back({values[0] / 100.0, values[1] / 100.0, static_cast<double>(values[2])});
        });
        split(args.text(17), ';', [&](std::string_view entry) {
            const auto colon = entry.find(':');
            require(colon != std::string_view::npos, "Congestion key needs x:y");
            context.congestion.insert(flpath::cellKey(integer(entry.substr(0, colon), -1000000, 1000000),
                integer(entry.substr(colon + 1), -1000000, 1000000)));
        });
        const double weight = args.number(9);
        const int maxExpansions = args.whole(10, 1, 1000000);
        require(weight >= 0 && weight <= 10, "Invalid heuristic weight");
        const auto started = std::chrono::steady_clock::now();
        if (kind == 0) {
            flpath::Profile profile;
            profile.vehicle = args.whole(5, 0, 1) == 1;
            profile.rural = args.whole(6, 0, 1) == 1;
            profile.maxSlope = args.number(7);
            profile.ruralRoadMultiplier = args.number(8);
            profile.weight = weight;
            profile.maxExpansions = maxExpansions;
            last = flpath::findGrid(grid, profile, context, args.number(1), args.number(2), args.number(3), args.number(4));
        } else {
            require(roadsReady, "Roads not ready");
            last = flpath::findRoad(roads, grid.size, context, weight, maxExpansions, args.whole(1, 0, maxRoads), args.whole(2, 0, maxRoads));
        }
        const double micros = std::chrono::duration<double, std::micro>(std::chrono::steady_clock::now() - started).count();
        output << std::fixed << std::setprecision(3) << '[' << last.found << ',' << last.expansions << ',' << last.route.size() << ',' << last.cost << ',' << micros << ']';
        return output.str();
    }
    if (command == "component") {
        args.size(2);
        require(gridReady, "Grid not ready");
        if (labels.empty()) {
            labels = flpath::components(grid);
        }
        const auto x = static_cast<long long>(std::floor(args.number(0) / grid.size));
        const auto y = static_cast<long long>(std::floor(args.number(1) / grid.size));
        const bool inside = x >= 0 && y >= 0 && x < grid.cells && y < grid.cells;
        output << '[' << (inside ? labels[static_cast<std::size_t>(y) * grid.cells + x] : -1) << ']';
        return output.str();
    }
    if (command == "route") {
        args.size(2);
        const int first = args.whole(0, 0, 1000000);
        const int count = args.whole(1, 1, maxPage);
        require(first < static_cast<int>(last.route.size()), "Route page out of range");
        const int end = std::min(first + count, static_cast<int>(last.route.size()));
        output << std::fixed << std::setprecision(2) << '[';
        for (int i = first; i < end; ++i) {
            output << (i == first ? "" : ",") << '[' << last.route[i].first << ',' << last.route[i].second << ']';
        }
        output << ']';
        return output.str();
    }
    throw std::invalid_argument("Unknown command");
}
} // namespace

FL_EXPORT void FL_CALL RVExtensionVersion(char* output, unsigned int outputSize) {
    write(output, outputSize, "Frontline Path 1.0.0");
}

FL_EXPORT void FL_CALL RVExtension(char* output, unsigned int outputSize, const char* function) {
    write(output, outputSize, function && std::strcmp(function, "version") == 0 ? "[1]" : "[\"Use the array callExtension interface\"]");
}

FL_EXPORT int FL_CALL RVExtensionArgs(char* output, unsigned int outputSize, const char* function, const char** argv, unsigned int argc) {
    // No code evaluation, network, filesystem, callbacks or worker threads.
    // Buffer rejection precedes mutation; no unterminated/truncated responses.
    if (!output || outputSize < minBuffer) {
        write(output, outputSize, "[]");
        return 5;
    }
    try {
        require(function && std::strlen(function) <= 16 && argc <= 18, "Invalid command envelope");
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
