"""Standard-library independent continuum reference and native ABI checks.

Run after tools/Build-GasExtension.ps1:
    python extensions/frontline_gas/verify.py .build/gas-extension

The exact Sod reference uses shock/rarefaction relations from
https://www.clawpack.org/riemann_book/html/Euler.html, not the production flux.
Acceptance: N=128 density/pressure MAE < .05, both decreasing at each refinement.
The ABI is exercised through the actual built DLL, not a Python solver port.
"""
from pathlib import Path
import csv
import ctypes
import hashlib
import json
import math
import sys


def exact_sod(x):
    gamma = 1.4
    left = (1.0, 0.0, 1.0)
    right = (0.125, 0.0, 0.1)

    def curve(p, state):
        rho, _, pk = state
        c = math.sqrt(gamma * pk / rho)
        if p > pk:
            a = 2 / ((gamma + 1) * rho)
            b = (gamma - 1) / (gamma + 1) * pk
            return (p - pk) * math.sqrt(a / (p + b))
        return 2 * c / (gamma - 1) * ((p / pk) ** ((gamma - 1) / (2 * gamma)) - 1)

    lo, hi = 1e-12, 10.0
    for _ in range(100):
        mid = (lo + hi) / 2
        if curve(mid, left) + curve(mid, right) > 0:
            hi = mid
        else:
            lo = mid
    pstar = (lo + hi) / 2
    ustar = (curve(pstar, right) - curve(pstar, left)) / 2
    rho_l = left[0] * (pstar / left[2]) ** (1 / gamma)
    beta = (gamma - 1) / (gamma + 1)
    ratio = pstar / right[2]
    rho_r = right[0] * (ratio + beta) / (beta * ratio + 1)
    cl = math.sqrt(gamma * left[2] / left[0])
    cstar = math.sqrt(gamma * pstar / rho_l)
    cr = math.sqrt(gamma * right[2] / right[0])
    shock = cr * math.sqrt((gamma + 1) / (2 * gamma) * ratio + (gamma - 1) / (2 * gamma))
    xi = (x - 0.5) / 0.2
    if xi > ustar:
        return right if xi > shock else (rho_r, ustar, pstar)
    if xi < -cl:
        return left
    if xi > ustar - cstar:
        return rho_l, ustar, pstar
    u = 2 / (gamma + 1) * (cl + xi)
    c = 2 / (gamma + 1) * (cl - (gamma - 1) * xi / 2)
    return left[0] * (c / cl) ** (2 / (gamma - 1)), u, left[2] * (c / cl) ** (2 * gamma / (gamma - 1))


def verify(build):
    build = Path(build).resolve()
    errors = {}
    for n in (64, 128, 256):
        with (build / f'sod-{n}.csv').open() as stream:
            rows = list(csv.DictReader(stream))
        assert len(rows) == n
        sums = [0.0, 0.0, 0.0]
        for row in rows:
            reference = exact_sod(float(row['x']))
            for i, field in enumerate(('rho', 'u', 'p')):
                sums[i] += abs(float(row[field]) - reference[i]) / n
        errors[n] = sums
    assert errors[128][0] < 0.05 and errors[128][2] < 0.05, errors
    for fine, coarse in ((128, 64), (256, 128)):
        assert errors[fine][0] < errors[coarse][0] and errors[fine][2] < errors[coarse][2], errors

    library_path = build / 'frontline_gas_x64.dll'
    library = ctypes.CDLL(str(library_path))
    entry = library.RVExtensionArgs
    entry.argtypes = [ctypes.c_void_p, ctypes.c_uint, ctypes.c_char_p, ctypes.POINTER(ctypes.c_char_p), ctypes.c_uint]
    entry.restype = ctypes.c_int
    checks = []

    def call(command, values=(), expected=0):
        encoded = [str(x).encode('ascii') for x in values]
        args = (ctypes.c_char_p * len(encoded))(*encoded)
        buffer = ctypes.create_string_buffer(10240)
        code = entry(buffer, len(buffer), command.encode('ascii'), args, len(args))
        assert code == expected, (command, code, buffer.value)
        return json.loads(buffer.value)

    assert call('version') == [3, 4096, 8, 8]
    call('reset')
    standard = [4, 4, 4, 1, 1.4, 1.2, 0, 0, 0, 101325, 0, 1, 1, 1, 1, 1, 1]
    handle, count = call('create', standard)
    assert count == 64
    call('fill', [handle, 21, 2, 1.2, 0, 0, 0, 150000, 1])
    before = call('stats', [handle])
    snapshot = call('cells', [handle, 16, 16])
    call('openings', [handle, 0, 0, 0.25, 1])
    call('openings', [handle, 0, 0.5, -1], expected=1)
    call('openings', [handle, 24575, 1], expected=1)
    call('openings', [handle, 0, 'NaN'], expected=1)
    call('walls', [handle, 0, 3, 0])
    for command, args in (
        ('fill', [handle, 63, 2, 1.2, 0, 0, 0, 150000, 1]),
        ('fill', [handle, 0, 1, 1.2, 0, 0, 0, -1, 1]),
        ('advance', [handle, 0.01, 9, 0.4]),
        ('advance', [handle, 0.01, 8, 0.6]),
        ('advance', [handle, 'NaN', 8, 0.4]),
        ('advance', [handle, 'Infinity', 8, 0.4]),
        ('advance', [handle, '1;anything', 8, 0.4]),
        ('sample', [handle, 64, 287.05]),
        ('sample', [handle, 21, '1e-300']),
        ('cells', [handle, 0, 17]),
        ('release', [handle, 1]),
        ('unknown', [handle]),
        ('create', [4096, 2, 1] + standard[3:]),
        ('heat', [handle, 0, -1]),
        ('walls', [handle, 0, 1, 2]),
        ('samples', [handle] + [0] * 9),
    ):
        call(command, args, expected=1)
    assert call('stats', [handle]) == before
    assert call('cells', [handle, 16, 16]) == snapshot
    checks.append('malformed input, oversized work and nonrepresentable SQF output rejected without state changes')

    # The engine supplies outputSize. Deliberately undersize it with a canary.
    buffer = ctypes.create_string_buffer(b'X' * 32)
    args = (ctypes.c_char_p * 1)(str(handle).encode())
    assert entry(buffer, 4, b'release', args, 1) == 5
    assert buffer.raw[4:32] == b'X' * 28
    assert call('stats', [handle]) == before
    checks.append('small output buffer preserves canary and rejects before mutation')

    advance = call('advance', [handle, 0.01, 8, 0.4])
    assert 1 <= advance[3] <= 8 and 0 < advance[0] <= 0.01
    sample = call('sample', [handle, 21, 287.05])
    assert sample[1] < 150000 and sample[3] > 0
    stats = call('stats', [handle])
    for i in (0, 4, 5):
        assert abs(stats[9][i] + stats[8][i] - stats[6][i] - stats[7][i]) / max(1, abs(stats[6][i]) + abs(stats[7][i])) < 1e-11
    checks.append('actual DLL advances conservative states and returns SI samples')
    faces = call('faces', [handle, 0, 8])
    assert len(faces) == 8 and len(faces[0]) == 4
    call('walls', [handle, 0, 8, 255])
    total_before_heat = call('stats', [handle])[9]
    call('heat', [handle, 0, 1000])
    total_after_heat = call('stats', [handle])[9]
    assert abs(total_after_heat[4] - total_before_heat[4] - 1000) < 1e-7
    assert total_after_heat[0] == total_before_heat[0]
    assert len(call('samples', [handle] + list(range(8)))) == 8
    checks.append('geometry masks, prescribed heat ledger and bounded sample batches cross actual ABI')
    for _ in range(7):
        call('create', standard)
    call('create', standard, expected=1)
    assert len(call('status')) == 8
    call('reset')
    call('stats', [handle], expected=1)
    new_handle = call('create', standard)[0]
    assert new_handle > handle
    call('release', [new_handle])
    call('release', [new_handle], expected=1)
    assert call('status') == []
    checks.append('domain cap, cleanup and nonrecycled handles prevent stale aliasing')
    report = {
        'dll_sha256': hashlib.sha256(library_path.read_bytes()).hexdigest(),
        'sources': {p.name: hashlib.sha256(p.read_bytes()).hexdigest() for p in Path(__file__).parent.glob('*') if p.suffix in ('.cpp', '.hpp', '.py')},
        'reference': 'https://www.clawpack.org/riemann_book/html/Euler.html',
        'mean_absolute_errors_density_velocity_pressure': errors,
        'abi_checks': checks,
        'native_summary': (build / 'native-tests.txt').read_text(),
        'passed': True,
    }
    (build / 'verification.json').write_text(json.dumps(report, indent=2))
    print(json.dumps({k: v for k, v in report.items() if k not in ('sources', 'native_summary')}, indent=2))


if __name__ == '__main__':
    verify(sys.argv[1] if len(sys.argv) > 1 else '.build/gas-extension')
