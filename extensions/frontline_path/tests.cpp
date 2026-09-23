#include "path.hpp"

#include <cmath>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <string>
#include <vector>

extern "C" int RVExtensionArgs(char* output, unsigned int outputSize, const char* function, const char** argv, unsigned int argc);

namespace {
int failures = 0;

void check(bool condition, const char* name) {
    std::printf("%s %s\n", condition ? "PASS" : "FAIL", name);
    failures += condition ? 0 : 1;
}

bool near(double a, double b) { return std::abs(a - b) < 1e-6; }

// n x n dry, flat grid of 100 m cells.
flpath::Grid flat(int n) {
    flpath::Grid grid;
    grid.size = 100;
    grid.cells = n;
    grid.flags.assign(static_cast<std::size_t>(grid.side()) * grid.side(), 0);
    grid.heights.assign(static_cast<std::size_t>(n) * n, 0);
    return grid;
}

void setFlag(flpath::Grid& grid, int x, int y, unsigned char value) { grid.flags[static_cast<std::size_t>(y) * grid.side() + x] = value; }

// Water on a cell centre and on every half-cell sample around it.
void flood(flpath::Grid& grid, int cx, int cy) {
    for (int dy = -1; dy <= 1; ++dy) {
        for (int dx = -1; dx <= 1; ++dx) {
            setFlag(grid, 2 * cx + 1 + dx, 2 * cy + 1 + dy, 1);
        }
    }
}

flpath::Context far() {
    flpath::Context context;
    context.destinationX = 1e6; // approach factor 1 everywhere near the test grid
    context.destinationY = 1e6;
    return context;
}

std::string call(const char* function, std::vector<std::string> args, int* code = nullptr, unsigned int size = 8192) {
    std::vector<const char*> argv;
    for (const auto& arg : args) {
        argv.push_back(arg.c_str());
    }
    std::vector<char> output(size, 'x');
    const int result = RVExtensionArgs(output.data(), size, function, argv.data(), static_cast<unsigned int>(argv.size()));
    if (code) {
        *code = result;
    }
    return output.data();
}
} // namespace

int main() {
    flpath::Profile infantry;
    infantry.maxSlope = 1.0;
    flpath::Profile vehicle;
    vehicle.vehicle = true;
    vehicle.maxSlope = 0.45;

    {
        const auto grid = flat(5);
        const auto result = flpath::findGrid(grid, infantry, far(), 10, 20, 480, 30);
        check(result.found && near(result.cost, 420) && result.route.size() == 5, "straight infantry route costs 4 x 100 x 1.05");
        check(near(result.route.front().first, 10) && near(result.route.back().first, 480), "route endpoints are the requested positions");
    }
    {
        auto grid = flat(5);
        for (int y = 0; y < 5; ++y) {
            flood(grid, 2, y);
        }
        check(!flpath::findGrid(grid, infantry, far(), 50, 50, 450, 50).found, "water wall blocks the route");
        setFlag(grid, 5, 9, 3); // road through water at cell (2,4) centre
        setFlag(grid, 4, 9, 2);
        setFlag(grid, 6, 9, 2);
        const auto result = flpath::findGrid(grid, infantry, far(), 50, 50, 450, 50);
        check(result.found && result.route.size() > 5, "road crossing opens a detour");
    }
    {
        auto grid = flat(2);
        setFlag(grid, 2, 2, 1); // water at the shared corner only
        const auto result = flpath::findGrid(grid, infantry, far(), 50, 50, 150, 150);
        check(result.found && result.route.size() == 3, "diagonal midpoint water forces an orthogonal route");
    }
    {
        auto grid = flat(2);
        grid.heights[1] = 100; // every exit from (0,0) climbs 1.0 (orthogonal) or 0.71 (diagonal)
        grid.heights[2] = 100;
        grid.heights[3] = 100;
        check(!flpath::findGrid(grid, vehicle, far(), 50, 50, 150, 50).found, "vehicle slope limit blocks the climb");
        const auto result = flpath::findGrid(grid, infantry, far(), 50, 50, 150, 50);
        check(result.found && near(result.cost, 100 * 1.05 * 3), "infantry pays slope multiplier 1 + min(2, 2 x slope)");
    }
    {
        auto grid = flat(3);
        setFlag(grid, 3, 1, 2); // road at cell (1,0) centre
        flpath::Profile rural = infantry;
        rural.rural = true;
        const auto result = flpath::findGrid(grid, rural, far(), 50, 50, 250, 50);
        check(result.found && result.route.size() == 3 && result.route[1].second > 100, "rural routes avoid a road cell");
    }
    {
        const auto grid = flat(3);
        auto context = far();
        context.threats.push_back({150, 50, 10});
        const double threatened = flpath::findGrid(grid, infantry, context, 50, 50, 250, 50).cost;
        auto congested = far();
        congested.congestion.insert(flpath::cellKey(1, 0));
        const double busy = flpath::findGrid(grid, infantry, congested, 50, 50, 250, 50).cost;
        check(threatened > 210 && busy > 210 && busy < 210 * 1.2, "threats and congestion raise cost");
        auto arriving = far();
        arriving.destinationX = 250;
        arriving.destinationY = 50;
        arriving.congestion.insert(flpath::cellKey(2, 0));
        check(near(flpath::findGrid(grid, infantry, arriving, 50, 50, 250, 50).cost, 210), "congestion fades to nothing at the destination");
    }
    {
        const auto grid = flat(50);
        flpath::Profile capped = infantry;
        capped.maxExpansions = 5;
        const auto result = flpath::findGrid(grid, capped, far(), 50, 50, 4950, 4950);
        check(!result.found && result.expansions == 5, "expansion cap fails the search");
    }
    {
        auto grid = flat(5);
        for (int y = 0; y < 5; ++y) {
            flood(grid, 2, y);
        }
        const auto labels = flpath::components(grid);
        check(labels[0] == labels[1] && labels[3] == labels[4] && labels[0] != labels[3] && labels[2] == -1, "water splits connected land");
        grid.heights[1] = 500; // cliffs do not split land
        check(flpath::components(grid)[0] == flpath::components(grid)[1], "slope ignored by components");
    }
    {
        flpath::Roads roads;
        roads.x = {0, 100, 200, 100};
        roads.y = {0, 0, 0, 100};
        roads.links = {{1, 3}, {0, 2}, {1, 3}, {0, 2}};
        const auto result = flpath::findRoad(roads, 100, far(), 1.12, 20000, 0, 2);
        check(result.found && near(result.cost, 200) && result.route.size() == 3 && near(result.route[1].second, 0), "road search follows the shorter link");
        roads.links = {{1}, {0}, {3}, {2}};
        check(!flpath::findRoad(roads, 100, far(), 1.12, 20000, 0, 2).found, "disconnected roads fail");
    }
    {
        int code = -1;
        call("reset", {}, &code);
        check(code == 0 && call("version", {}) == "[1,1024,500000,150]", "version reply");
        call("gridBegin", {"100", "2"}, &code);
        for (int row = 0; row < 5; ++row) {
            call("gridFlags", {std::to_string(row), "\"00000\""}, &code);
        }
        call("gridHeights", {"0", "\"0,0\""});
        call("gridHeights", {"1", "\"0,-150\""});
        check(call("gridSeal", {}, &code) == "[2]" && code == 0, "grid sealed");
        const auto found = call("find", {"0", "50", "50", "150", "150", "0", "0", "1", "2.25", "1.12", "12000", "150", "150", "600", "1600", "1.2", "\"\"", "\"1:0;0:1\""}, &code);
        check(code == 0 && found.rfind("[1,", 0) == 0, "native find over the ABI");
        check(call("route", {"0", "150"}) == "[[50.00,50.00],[150.00,150.00]]", "route page");
        call("find", {"0", "\"99.99\"", "\"50.00\"", "\"150.00\"", "\"150.00\"", "0", "0", "1", "2.25", "1.12", "12000", "150", "150", "600", "1600", "1.2", "\"\"", "\"\""}, &code);
        check(code == 0 && call("route", {"0", "1"}) == "[[99.99,50.00]]", "quoted coordinates keep full precision");
        check(call("component", {"\"50.00\"", "\"50.00\""}) == "[0]" && call("component", {"-5", "50"}) == "[-1]", "component lookup");
        call("find", {"0", "50"}, &code);
        check(code == 1, "wrong argument count rejected");
        call("gridFlags", {"0", "\"0000\""}, &code);
        check(code == 1, "sealed grid rejects edits");
        call("status", {}, &code, 16);
        check(code == 5, "small output buffer rejected");
        call("warp", {}, &code);
        check(code == 1, "unknown command rejected");
    }
    std::printf("%d failure(s)\n", failures);
    return failures == 0 ? EXIT_SUCCESS : EXIT_FAILURE;
}
