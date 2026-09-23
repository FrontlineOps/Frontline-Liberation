#pragma once

#include <unordered_set>
#include <utility>
#include <vector>

// Server-owned A* for Battlespace task forces. Rules, costs, expansion order
// and tie-breaking mirror modules/battlespace_ai/task_forces/pathfinder.sqf.
namespace flpath {

constexpr int maxCells = 1024;

struct Grid {
    double size = 0;
    int cells = 0;                    // valid cell indices per axis
    std::vector<unsigned char> flags; // (2 * cells + 1)^2 half-cell samples: 1 water, 2 road
    std::vector<double> heights;      // cell-centre terrain height ASL
    int side() const { return 2 * cells + 1; }
    unsigned char flag(int x, int y) const { return flags[static_cast<std::size_t>(y) * side() + x]; }
};

struct Roads {
    std::vector<double> x;
    std::vector<double> y;
    std::vector<std::vector<int>> links; // roadsConnectedTo order
};

struct Threat {
    double x;
    double y;
    double strength;
};

struct Context {
    double destinationX = 0;
    double destinationY = 0;
    double approachRadius = 600;
    double threatRadius = 1600;
    double congestionMultiplier = 1.2;
    std::vector<Threat> threats;
    std::unordered_set<long long> congestion; // grid cell keys
};

struct Profile {
    bool vehicle = false;
    bool rural = false;
    double maxSlope = 1;
    double ruralRoadMultiplier = 2.25;
    double weight = 1.12;
    int maxExpansions = 12000;
};

struct Result {
    bool found = false;
    int expansions = 0;
    double cost = 0;
    std::vector<std::pair<double, double>> route;
};

inline long long cellKey(long long x, long long y) { return (x << 32) ^ (y & 0xffffffffLL); }

Result findGrid(const Grid& grid, const Profile& profile, const Context& context, double startX, double startY, double goalX, double goalY);
Result findRoad(const Roads& roads, double gridSize, const Context& context, double weight, int maxExpansions, int start, int goal);
// Connected land (grid-search water rules, no slope limit): one label per cell, -1 where blocked.
std::vector<int> components(const Grid& grid);

} // namespace flpath
