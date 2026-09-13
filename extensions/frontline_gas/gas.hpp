#pragma once

#include <array>
#include <cstddef>
#include <vector>

namespace flgas {

// SI conserved state: density, x/y/z momentum density, total energy density,
// passive tracer mass density. This is a perfect-gas solver, not chemistry.
using State = std::array<double, 6>;
using Primitive = std::array<double, 7>;
enum class Boundary { Open, Wall, Periodic };
constexpr std::size_t maxCells = 4096;

State conserve(const State& primitive, double gamma);
Primitive primitive(const State& conserved, double gamma);
State flux(const State& left, const State& right, const Primitive& wl,
    const Primitive& wr, int axis, int sign);

struct Face {
    std::size_t a;
    int b;
    int axis;
    int sign;
    Boundary boundary;
    bool blocked = false;
    double opening = 1;
};

class Domain {
public:
    Domain(std::array<int, 3> dimensions, double spacing, const State& initial,
        double gamma, const std::array<Boundary, 6>& boundaries);
    void fill(std::size_t first, std::size_t count, const State& value);
    void walls(std::size_t first, std::size_t count, unsigned int mask);
    void openings(std::size_t first, const std::vector<double>& fractions);
    void heat(std::size_t cell, double joules);
    double step(double maxDt, double cfl = 0.4);
    std::array<double, 11> sample(std::size_t cell, double gasConstant = 287.05) const;
    State totals() const;

    std::vector<State> cells;
    std::vector<Face> faces;
    double spacing;
    double gamma;
    double ambientPressure;
    State ambient;
    double time = 0;
    unsigned int steps = 0;
    State initialTotals{};
    State injected{};
    State boundaryTransfer{};
    std::vector<double> positiveImpulse;
    std::vector<double> signedImpulse;
    std::vector<double> peak;

private:
    // Reuse scratch allocations. A trial commits only after every cell passes.
    std::vector<Primitive> primitives;
    std::vector<State> next;
    std::vector<State> delta;
    std::vector<double> nextPressure;
};

}
