#include "gas.hpp"

#include <algorithm>
#include <cmath>
#include <stdexcept>

namespace flgas {
namespace {
void require(bool valid, const char* message) {
    if (!valid) {
        throw std::invalid_argument(message);
    }
}

bool finite(const State& value) {
    return std::all_of(value.begin(), value.end(), [](double x) { return std::isfinite(x); });
}
}

Primitive primitive(const State& u, double gamma) {
    require(finite(u) && u[0] > 0 && std::isfinite(gamma) && gamma > 1, "Invalid conserved state");
    const double ux = u[1] / u[0];
    const double uy = u[2] / u[0];
    const double uz = u[3] / u[0];
    const double p = (gamma - 1) * (u[4] - 0.5 * (u[1] * ux + u[2] * uy + u[3] * uz));
    require(std::isfinite(p) && p > 0 && u[5] >= -1e-12 * u[0] && u[5] <= (1 + 1e-12) * u[0], "Inadmissible pressure or tracer");
    const double sound = std::sqrt(gamma * p / u[0]);
    require(std::isfinite(sound) && std::isfinite(ux) && std::isfinite(uy) && std::isfinite(uz), "Nonfinite primitive state");
    return {u[0], ux, uy, uz, p, sound, u[5] / u[0]};
}

State conserve(const State& w, double gamma) {
    require(finite(w) && w[0] >= 1e-9 && w[0] <= 1e6 && w[4] >= 1e-9 && w[4] <= 1e12
        && w[5] >= 0 && w[5] <= 1 && std::isfinite(gamma) && gamma >= 1.001 && gamma <= 3,
        "Primitive input outside supported bounds");
    require(std::abs(w[1]) <= 1e7 && std::abs(w[2]) <= 1e7 && std::abs(w[3]) <= 1e7, "Velocity outside supported bounds");
    State u{w[0], w[0] * w[1], w[0] * w[2], w[0] * w[3],
        w[4] / (gamma - 1) + 0.5 * w[0] * (w[1] * w[1] + w[2] * w[2] + w[3] * w[3]), w[0] * w[5]};
    primitive(u, gamma);
    return u;
}

State flux(const State& l, const State& r, const Primitive& wl, const Primitive& wr, int axis, int sign) {
    const auto normal = static_cast<std::size_t>(axis + 1);
    const double vl = wl[normal] * sign;
    const double vr = wr[normal] * sign;
    const double speed = std::max(std::abs(vl) + wl[5], std::abs(vr) + wr[5]);
    State result{};
    for (std::size_t k = 0; k < result.size(); ++k) {
        double fl = l[k] * vl;
        double fr = r[k] * vr;
        if (k == normal) {
            fl += wl[4] * sign;
            fr += wr[4] * sign;
        }
        if (k == 4) {
            fl += wl[4] * vl;
            fr += wr[4] * vr;
        }
        result[k] = 0.5 * (fl + fr - speed * (r[k] - l[k]));
    }
    return result;
}

Domain::Domain(std::array<int, 3> dims, double dx, const State& w, double g,
    const std::array<Boundary, 6>& bounds) : spacing(dx), gamma(g), ambientPressure(w[4]), ambient(conserve(w, g)) {
    require(std::isfinite(dx) && dx >= 1e-6 && dx <= 1e6, "Invalid cell spacing");
    std::size_t count = 1;
    for (int size : dims) {
        require(size > 0 && size <= static_cast<int>(maxCells), "Invalid dimensions");
        count *= static_cast<std::size_t>(size);
        require(count <= maxCells, "Domain exceeds cell cap");
    }
    for (int axis = 0; axis < 3; ++axis) {
        for (int side = 0; side < 2; ++side) {
            const auto b = bounds[2 * axis + side];
            require(b == Boundary::Open || b == Boundary::Wall || b == Boundary::Periodic, "Invalid boundary");
        }
        require((bounds[2 * axis] == Boundary::Periodic) == (bounds[2 * axis + 1] == Boundary::Periodic), "Periodic boundaries must be paired");
    }
    cells.assign(count, ambient);
    primitives.resize(count);
    next.resize(count);
    delta.resize(count);
    nextPressure.resize(count);
    positiveImpulse.assign(count, 0);
    signedImpulse.assign(count, 0);
    peak.assign(count, 0);
    const std::array<int, 3> strides{1, dims[0], dims[0] * dims[1]};
    faces.reserve(count * 6);
    for (int z = 0; z < dims[2]; ++z) {
        for (int y = 0; y < dims[1]; ++y) {
            for (int x = 0; x < dims[0]; ++x) {
                const int index = x + dims[0] * (y + dims[1] * z);
                const auto a = static_cast<std::size_t>(index);
                const std::array<int, 3> coords{x, y, z};
                for (int axis = 0; axis < 3; ++axis) {
                    const auto b = bounds[2 * axis + 1];
                    if (coords[axis] < dims[axis] - 1) {
                        faces.push_back({a, index + strides[axis], axis, 1, Boundary::Open});
                    } else if (b == Boundary::Periodic) {
                        faces.push_back({a, index - (dims[axis] - 1) * strides[axis], axis, 1, Boundary::Open});
                    } else {
                        faces.push_back({a, -1, axis, 1, b});
                    }
                    if (coords[axis] == 0 && bounds[2 * axis] != Boundary::Periodic) {
                        faces.push_back({a, -1, axis, -1, bounds[2 * axis]});
                    }
                }
            }
        }
    }
    initialTotals = totals();
}

void Domain::fill(std::size_t first, std::size_t count, const State& value) {
    require(count > 0 && first < cells.size() && count <= cells.size() - first, "Invalid fill range");
    const State u = conserve(value, gamma);
    const double volume = spacing * spacing * spacing;
    for (std::size_t i = first; i < first + count; ++i) {
        for (std::size_t k = 0; k < u.size(); ++k) {
            injected[k] += (u[k] - cells[i][k]) * volume;
        }
        cells[i] = u;
        peak[i] = std::max(peak[i], value[4] - ambientPressure);
    }
}

void Domain::walls(std::size_t first, std::size_t count, unsigned int mask) {
    require(count > 0 && count <= 16 && first < faces.size() && count <= faces.size() - first
        && mask < (1u << count), "Invalid face mask");
    for (std::size_t i = 0; i < count; ++i) {
        faces[first + i].blocked = (mask & (1u << i)) != 0;
    }
}

void Domain::heat(std::size_t cell, double joules) {
    require(cell < cells.size() && std::isfinite(joules) && joules >= 0 && joules <= 1e12, "Invalid prescribed heat input");
    State updated = cells[cell];
    updated[4] += joules / (spacing * spacing * spacing);
    const auto w = primitive(updated, gamma);
    cells[cell] = updated;
    injected[4] += joules;
    peak[cell] = std::max(peak[cell], w[4] - ambientPressure);
}

double Domain::step(double maxDt, double cfl) {
    require(std::isfinite(maxDt) && maxDt > 0 && maxDt <= 1e6 && std::isfinite(cfl) && cfl > 0 && cfl <= 0.5, "Invalid timestep or CFL");
    double maxSpeed = 0;
    for (std::size_t i = 0; i < cells.size(); ++i) {
        primitives[i] = primitive(cells[i], gamma);
        const auto& w = primitives[i];
        maxSpeed = std::max(maxSpeed, std::abs(w[1]) + std::abs(w[2]) + std::abs(w[3]) + 3 * w[5]);
        delta[i].fill(0);
    }
    const double dt = std::min(maxDt, cfl * spacing / maxSpeed);
    require(std::isfinite(dt) && dt > 0 && time + dt > time, "Timestep below numerical resolution");
    State boundary{};
    const Primitive wa = primitive(ambient, gamma);
    const double factor = dt / spacing;
    const double areaTime = dt * spacing * spacing;
    for (const Face& face : faces) {
        // An impermeable interior face has two independent reflecting sides.
        // Each side transfers momentum to the wall; neither exchanges gas.
        if (face.blocked) {
            const auto reflect = [&](std::size_t cell, int sign) {
                State mirror = cells[cell];
                Primitive wm = primitives[cell];
                mirror[face.axis + 1] *= -1;
                wm[face.axis + 1] *= -1;
                const State f = flux(cells[cell], mirror, primitives[cell], wm, face.axis, sign);
                for (std::size_t k = 0; k < f.size(); ++k) {
                    delta[cell][k] -= f[k] * factor;
                    boundary[k] += f[k] * areaTime;
                }
            };
            reflect(face.a, face.sign);
            if (face.b >= 0) {
                reflect(static_cast<std::size_t>(face.b), -face.sign);
            }
            continue;
        }
        const State& l = cells[face.a];
        const Primitive& wl = primitives[face.a];
        State r = ambient;
        Primitive wr = wa;
        if (face.b >= 0) {
            r = cells[face.b];
            wr = primitives[face.b];
        } else if (face.boundary == Boundary::Wall) {
            r = l;
            wr = wl;
            r[face.axis + 1] *= -1;
            wr[face.axis + 1] *= -1;
        }
        const State f = flux(l, r, wl, wr, face.axis, face.sign);
        for (std::size_t k = 0; k < f.size(); ++k) {
            const double change = f[k] * factor;
            delta[face.a][k] -= change;
            if (face.b >= 0) {
                delta[face.b][k] += change;
            } else {
                boundary[k] += f[k] * areaTime;
            }
        }
    }
    for (std::size_t i = 0; i < cells.size(); ++i) {
        for (std::size_t k = 0; k < cells[i].size(); ++k) {
            next[i][k] = cells[i][k] + delta[i][k];
        }
        // Any failure throws before observable state or ledgers commit.
        nextPressure[i] = primitive(next[i], gamma)[4];
    }
    for (std::size_t i = 0; i < cells.size(); ++i) {
        const double oldP = primitives[i][4] - ambientPressure;
        const double newP = nextPressure[i] - ambientPressure;
        peak[i] = std::max({peak[i], oldP, newP});
        signedImpulse[i] += 0.5 * (oldP + newP) * dt;
        if (oldP > 0 && newP > 0) {
            positiveImpulse[i] += 0.5 * (oldP + newP) * dt;
        } else if (oldP > 0 || newP > 0) {
            const double positive = std::max(oldP, newP);
            positiveImpulse[i] += 0.5 * positive * positive / std::abs(newP - oldP) * dt;
        }
    }
    for (std::size_t k = 0; k < boundary.size(); ++k) {
        boundaryTransfer[k] += boundary[k];
    }
    cells.swap(next);
    time += dt;
    ++steps;
    return dt;
}

std::array<double, 11> Domain::sample(std::size_t cell, double gasConstant) const {
    require(cell < cells.size() && std::isfinite(gasConstant) && gasConstant > 0, "Invalid sample");
    const auto w = primitive(cells[cell], gamma);
    return {time, w[4], peak[cell], positiveImpulse[cell], signedImpulse[cell],
        w[4] / (w[0] * gasConstant), w[0], w[1], w[2], w[3], w[6]};
}

State Domain::totals() const {
    State result{};
    const double volume = spacing * spacing * spacing;
    for (const auto& u : cells) {
        for (std::size_t k = 0; k < result.size(); ++k) {
            result[k] += u[k] * volume;
        }
    }
    return result;
}

}
