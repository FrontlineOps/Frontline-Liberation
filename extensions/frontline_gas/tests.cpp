#include "gas.hpp"

#include <algorithm>
#include <chrono>
#include <cmath>
#include <fstream>
#include <iomanip>
#include <iostream>
#include <stdexcept>
#include <string>

namespace {
int checks = 0;
void check(bool ok, const char* label) {
    if (!ok) {
        throw std::runtime_error(label);
    }
    ++checks;
    std::cout << "PASS " << label << '\n';
}

template <class Function>
void rejects(Function function, const char* label) {
    bool rejected = false;
    try {
        function();
    } catch (const std::invalid_argument&) {
        rejected = true;
    }
    check(rejected, label);
}

std::array<flgas::Boundary, 6> boundaries(flgas::Boundary value) {
    std::array<flgas::Boundary, 6> result{};
    result.fill(value);
    return result;
}

double residual(const flgas::Domain& d) {
    const auto total = d.totals();
    double result = 0;
    for (std::size_t k = 0; k < total.size(); ++k) {
        double scale = std::max(1.0, std::abs(d.initialTotals[k]) + std::abs(d.injected[k]) + std::abs(d.boundaryTransfer[k]));
        for (const auto& u : d.cells) {
            scale += std::abs(u[k]) * d.spacing * d.spacing * d.spacing;
        }
        result = std::max(result, std::abs(total[k] + d.boundaryTransfer[k] - d.initialTotals[k] - d.injected[k]) / scale);
    }
    return result;
}
}

int main() {
    try {
        using namespace flgas;
        const auto walls = boundaries(Boundary::Wall);
        const auto periodic = boundaries(Boundary::Periodic);
        const auto open = boundaries(Boundary::Open);
        const State air{1.2, 0, 0, 0, 101325, 0};
        Domain rest({4, 4, 4}, 1, air, 1.4, walls);
        const auto initial = rest.cells;
        for (int i = 0; i < 20; ++i) {
            rest.step(0.001);
        }
        check(rest.cells == initial, "uniform reflecting atmosphere remains exactly stationary");
        check(std::abs(rest.sample(0)[5] - 101325 / (1.2 * 287.05)) < 1e-12, "ideal gas temperature uses SI units");
        const double savedTime = rest.time;
        const auto savedTransfer = rest.boundaryTransfer;
        rejects([&] { rest.step(0.001, 0.6); }, "invalid CFL rejected");
        check(rest.time == savedTime && rest.cells == initial && rest.boundaryTransfer == savedTransfer, "failed advance preserves state and ledgers");
        rejects([&] { rest.fill(63, 2, air); }, "out of range source rejected");
        rejects([&] { rest.fill(0, 1, {1.2, 0, 0, 0, -1, 0}); }, "negative absolute source pressure rejected");
        check(rest.cells == initial && rest.injected == State{}, "invalid source does not partially alter domain");
        rejects([&] { Domain tooBig({4096, 2, 1}, 1, air, 1.4, walls); }, "cell cap enforced before allocation");
        auto unpaired = walls;
        unpaired[0] = Boundary::Periodic;
        rejects([&] { Domain invalid({2, 2, 2}, 1, air, 1.4, unpaired); }, "unpaired periodic boundary rejected");

        for (const auto& b : {walls, open, periodic}) {
            Domain expansion({4, 4, 4}, 1, air, 1.4, b);
            for (int z = 1; z <= 2; ++z) {
                for (int y = 1; y <= 2; ++y) {
                    expansion.fill(static_cast<std::size_t>(1 + 4 * (y + 4 * z)), 2, {1.2, 0, 0, 0, 150000, 1});
                }
            }
            for (int i = 0; i < 20; ++i) {
                expansion.step(0.001);
            }
            check(residual(expansion) < 1e-11, "3D conservation includes sources and signed boundary transfers");
            check(expansion.sample(21)[1] < 150000 && expansion.sample(21)[3] > 0, "source expands and accumulates positive impulse");
            const auto x = expansion.sample(22);
            const auto y = expansion.sample(25);
            const auto z = expansion.sample(37);
            check(std::abs(x[1] - y[1]) < 1e-8 && std::abs(y[1] - z[1]) < 1e-8, "Cartesian permutation preserves symmetric expansion pressure");
            if (b == walls) {
                check(expansion.boundaryTransfer[0] == 0 && expansion.boundaryTransfer[4] == 0, "reflecting walls transmit no mass or energy");
            }
            if (b == open) {
                check(expansion.boundaryTransfer[4] > 0, "ambient reservoir exports expansion energy");
            }
        }
        Domain positive({2, 1, 1}, 10, air, 1.4, periodic);
        positive.fill(0, 2, {1.2, 0, 0, 0, 102325, 0});
        Domain negative({2, 1, 1}, 10, air, 1.4, periodic);
        negative.fill(0, 2, {1.2, 0, 0, 0, 100825, 0});
        for (int i = 0; i < 5; ++i) {
            positive.step(0.001);
            negative.step(0.001);
        }
        check(std::abs(positive.sample(0)[3] - 5) < 1e-12 && std::abs(positive.sample(0)[4] - 5) < 1e-12, "1000 Pa for 5 ms integrates to 5 Pa s");
        check(negative.sample(0)[3] == 0 && std::abs(negative.sample(0)[4] + 2.5) < 1e-12, "negative phase changes signed impulse only");

        // A translating periodic gas pulse has an independent centroid velocity.
        Domain tracer({64, 1, 1}, 1.0 / 64, {1, 1, 0, 0, 1, 0}, 1.4, periodic);
        tracer.fill(0, 16, {1, 1, 0, 0, 1, 1});
        const auto phase = [](const Domain& d) {
            double re = 0;
            double im = 0;
            for (std::size_t i = 0; i < d.cells.size(); ++i) {
                const double angle = 2 * 3.14159265358979323846 * (static_cast<double>(i) + 0.5) / static_cast<double>(d.cells.size());
                re += d.cells[i][5] * std::cos(angle);
                im += d.cells[i][5] * std::sin(angle);
            }
            return std::atan2(im, re);
        };
        const double phase0 = phase(tracer);
        while (tracer.time < 0.25) {
            tracer.step(0.25 - tracer.time);
        }
        const double shift = std::remainder(phase(tracer) - phase0, 2 * 3.14159265358979323846);
        check(std::abs(shift - 3.14159265358979323846 / 2) < 0.005 && residual(tracer) < 1e-11, "periodic passive tracer follows bulk gas flow conservatively");

        Domain chamber({8, 1, 1}, 1, {1,0,0,0,1,0}, 1.4, walls);
        chamber.fill(0, 4, {1,0,0,0,2,1});
        const auto divider = std::find_if(chamber.faces.begin(), chamber.faces.end(), [](const Face& f) { return f.a == 3 && f.b == 4; });
        check(divider != chamber.faces.end(), "interior divider face is addressable");
        const auto faceIndex = static_cast<std::size_t>(std::distance(chamber.faces.begin(), divider));
        chamber.walls(faceIndex, 1, 1);
        const auto closedState = chamber.cells;
        for (int i = 0; i < 40; ++i) { chamber.step(0.01); }
        check(chamber.cells == closedState && residual(chamber) < 1e-11, "interior wall separates unequal pressures without gas leakage");
        chamber.walls(faceIndex, 1, 0);
        for (int i = 0; i < 40; ++i) { chamber.step(0.01); }
        check(chamber.cells[4][5] > 0 && residual(chamber) < 1e-11, "opening a vent admits conservative gas transport");
        const auto beforeHeat = chamber.totals();
        chamber.heat(0, 1000);
        check(std::abs(chamber.totals()[4] - beforeHeat[4] - 1000) < 1e-9 && chamber.totals()[0] == beforeHeat[0], "prescribed heat adds only declared energy");
        for (int i = 0; i < 40; ++i) { chamber.step(0.01); }
        check(residual(chamber) < 1e-11, "heated expansion conserves energy with source ledger");
        const auto beforeInvalidMask = chamber.cells;
        rejects([&] { chamber.walls(faceIndex, 1, 2); }, "face mask cannot exceed its declared range");
        rejects([&] { chamber.heat(0, -1); }, "negative prescribed heat rejected");
        check(chamber.cells == beforeInvalidMask, "invalid geometry or heat does not alter conserved state");

        for (int n : {64, 128, 256}) {
            Domain sod({n, 1, 1}, 1.0 / n, {0.125, 0, 0, 0, 0.1, 0}, 1.4, walls);
            sod.fill(0, static_cast<std::size_t>(n / 2), {1, 0, 0, 0, 1, 1});
            while (sod.time < 0.2) {
                sod.step(0.2 - sod.time);
            }
            std::ofstream csv("sod-" + std::to_string(n) + ".csv");
            csv << std::setprecision(17) << "x,rho,u,p\n";
            for (std::size_t i = 0; i < sod.cells.size(); ++i) {
                const auto w = primitive(sod.cells[i], sod.gamma);
                csv << (static_cast<double>(i) + 0.5) / n << ',' << w[0] << ',' << w[1] << ',' << w[4] << '\n';
            }
            check(residual(sod) < 1e-11, "Sod shock tube remains conservative");
        }
        for (int n : {4, 16}) {
            Domain benchmark({n, n, n}, 1, air, 1.4, walls);
            benchmark.fill(0, 1, {1.2, 0, 0, 0, 150000, 1});
            const auto start = std::chrono::steady_clock::now();
            for (int i = 0; i < 100; ++i) {
                benchmark.step(0.001);
            }
            const double ms = std::chrono::duration<double, std::milli>(std::chrono::steady_clock::now() - start).count() / 100;
            std::cout << "BENCH cells=" << benchmark.cells.size() << " mean_ms_per_step=" << ms << '\n';
        }
        std::cout << "COMPLETE " << checks << " checks\n";
        return 0;
    } catch (const std::exception& e) {
        std::cerr << "FAIL " << e.what() << '\n';
        return 1;
    }
}
