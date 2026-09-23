#include "path.hpp"

#include <algorithm>
#include <cmath>
#include <queue>

namespace flpath {
namespace {

constexpr double unvisited = 1e30;

// Stable min-heap order of priority_queue.sqf: priority, then insertion order.
struct Entry {
    double priority;
    long long order;
    int node;
    double cost;
};
struct Later {
    bool operator()(const Entry& a, const Entry& b) const {
        return a.priority > b.priority || (a.priority == b.priority && a.order > b.order);
    }
};
using Open = std::priority_queue<Entry, std::vector<Entry>, Later>;

double dynamicMultiplier(const Context& context, long long key, double x, double y) {
    double multiplier = 1;
    const double toDestination = std::hypot(x - context.destinationX, y - context.destinationY);
    const double approach = context.approachRadius <= 0 ? 1 : std::min(1.0, toDestination / context.approachRadius);
    if (approach > 0) {
        for (const auto& threat : context.threats) {
            const double distance = std::hypot(x - threat.x, y - threat.y);
            if (distance < context.threatRadius) {
                multiplier += (1 - distance / context.threatRadius) * (0.15 + std::min(0.2, 0.04 * threat.strength)) * approach;
            }
        }
        if (context.congestion.count(key)) {
            const double congestion = std::max(1.0, context.congestionMultiplier);
            multiplier *= 1 + (congestion - 1) * approach;
        }
    }
    return multiplier;
}

long long cellOf(double value, double size) { return static_cast<long long>(std::floor(value / size)); }

} // namespace

Result findGrid(const Grid& grid, const Profile& profile, const Context& context, double startX, double startY, double goalX, double goalY) {
    Result result;
    const int n = grid.cells;
    const double size = grid.size;
    const long long sx = cellOf(startX, size), sy = cellOf(startY, size);
    const long long gx = cellOf(goalX, size), gy = cellOf(goalY, size);
    const auto valid = [n](long long x, long long y) { return x >= 0 && y >= 0 && x < n && y < n; };
    const auto blocked = [&grid](int x, int y) {
        const unsigned char flag = grid.flag(x, y);
        return (flag & 1) && !(flag & 2);
    };
    if (!valid(sx, sy) || !valid(gx, gy) || blocked(2 * static_cast<int>(sx) + 1, 2 * static_cast<int>(sy) + 1)
        || blocked(2 * static_cast<int>(gx) + 1, 2 * static_cast<int>(gy) + 1)) {
        return result;
    }
    const auto index = [n](long long x, long long y) { return static_cast<int>(y * n + x); };
    const auto centre = [size](long long cell) { return (static_cast<double>(cell) + 0.5) * size; };
    const int start = index(sx, sy);
    const int goal = index(gx, gy);
    const double goalCentreX = centre(gx), goalCentreY = centre(gy);

    std::vector<double> best(static_cast<std::size_t>(n) * n, unvisited);
    std::vector<int> cameFrom(best.size(), -1);
    std::vector<char> closed(best.size(), 0);
    Open open;
    long long order = 0;
    best[start] = 0;
    open.push({std::hypot(centre(sx) - goalCentreX, centre(sy) - goalCentreY), ++order, start, 0});
    static constexpr int offsets[8][2] = {{-1, -1}, {0, -1}, {1, -1}, {-1, 0}, {1, 0}, {-1, 1}, {0, 1}, {1, 1}};

    while (true) {
        if (open.empty()) {
            return result;
        }
        const Entry current = open.top();
        open.pop();
        if (current.cost > best[current.node] || closed[current.node]) {
            continue;
        }
        closed[current.node] = 1;
        ++result.expansions;
        if (current.node == goal) {
            result.found = true;
            break;
        }
        if (result.expansions >= profile.maxExpansions) {
            return result;
        }
        const int cx = current.node % n, cy = current.node / n;
        const double currentX = centre(cx), currentY = centre(cy);
        const double currentHeight = grid.heights[current.node];
        for (const auto& offset : offsets) {
            const long long nx = cx + offset[0], ny = cy + offset[1];
            if (!valid(nx, ny)) {
                continue;
            }
            const int next = index(nx, ny);
            if (closed[next]) {
                continue;
            }
            const unsigned char flag = grid.flag(2 * static_cast<int>(nx) + 1, 2 * static_cast<int>(ny) + 1);
            const bool road = (flag & 2) != 0;
            if ((flag & 1) && !road) {
                continue;
            }
            if (blocked(2 * cx + 1 + offset[0], 2 * cy + 1 + offset[1])) {
                continue;
            }
            const double nextX = centre(nx), nextY = centre(ny);
            const double edge = std::hypot(nextX - currentX, nextY - currentY);
            const double slope = std::abs(grid.heights[next] - currentHeight) / std::max(1.0, edge);
            if (slope > profile.maxSlope) {
                continue;
            }
            const double terrain = profile.rural ? (road ? std::max(1.0, profile.ruralRoadMultiplier) : 1)
                                                 : (road ? 1 : (profile.vehicle ? 1.35 : 1.05));
            const double slopeMultiplier = 1 + std::min(2.0, slope * 2);
            const double cost = current.cost + edge * terrain * slopeMultiplier * dynamicMultiplier(context, cellKey(nx, ny), nextX, nextY);
            if (cost >= best[next]) {
                continue;
            }
            best[next] = cost;
            cameFrom[next] = current.node;
            open.push({cost + profile.weight * std::hypot(nextX - goalCentreX, nextY - goalCentreY), ++order, next, cost});
        }
    }

    result.cost = best[goal];
    for (int node = goal, guard = 0; node >= 0 && guard < 50000; node = node == start ? -1 : cameFrom[node], ++guard) {
        result.route.emplace_back(centre(node % n), centre(node / n));
    }
    std::reverse(result.route.begin(), result.route.end());
    result.route.front() = {startX, startY};
    result.route.back() = {goalX, goalY};
    return result;
}

Result findRoad(const Roads& roads, double gridSize, const Context& context, double weight, int maxExpansions, int start, int goal) {
    Result result;
    const int count = static_cast<int>(roads.x.size());
    if (start < 0 || goal < 0 || start >= count || goal >= count) {
        return result;
    }
    const auto distance = [&roads](int a, int b) { return std::hypot(roads.x[a] - roads.x[b], roads.y[a] - roads.y[b]); };
    std::vector<double> best(count, unvisited);
    std::vector<int> cameFrom(count, -1);
    std::vector<char> closed(count, 0);
    Open open;
    long long order = 0;
    best[start] = 0;
    open.push({distance(start, goal), ++order, start, 0});

    while (true) {
        if (open.empty()) {
            return result;
        }
        const Entry current = open.top();
        open.pop();
        if (current.cost > best[current.node] || closed[current.node]) {
            continue;
        }
        closed[current.node] = 1;
        ++result.expansions;
        if (current.node == goal) {
            result.found = true;
            break;
        }
        if (result.expansions >= maxExpansions) {
            return result;
        }
        for (const int next : roads.links[current.node]) {
            if (closed[next]) {
                continue;
            }
            const double x = roads.x[next], y = roads.y[next];
            const double multiplier = dynamicMultiplier(context, cellKey(cellOf(x, gridSize), cellOf(y, gridSize)), x, y);
            const double cost = current.cost + distance(current.node, next) * multiplier;
            if (cost >= best[next]) {
                continue;
            }
            best[next] = cost;
            cameFrom[next] = current.node;
            open.push({cost + weight * distance(next, goal), ++order, next, cost});
        }
    }

    result.cost = best[goal];
    for (int node = goal, guard = 0; node >= 0 && guard < 100000; node = node == start ? -1 : cameFrom[node], ++guard) {
        result.route.emplace_back(roads.x[node], roads.y[node]);
    }
    std::reverse(result.route.begin(), result.route.end());
    return result;
}

} // namespace flpath
