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

    assert call('version') == [4, 4096, 8, 8]
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

    # Validate terrain-reference normalization through the actual DLL. The
    # conserved solver tests above remain independent of this response bridge.
    def reference_field(pressure=104000, wall=False, terrain=True, heat=0, end=0.05):
        h, size = call('create', [5,5,5,2,1.4,1.2,0,0,0,101325,0,0,0,0,0,0,0])
        faces_count = call('stats', [h])[10]
        for first in range(0, faces_count, 16):
            faces = call('faces', [h,first,16])
            mask = actual = 0
            for i, (a,b,axis,sign) in enumerate(faces):
                below = terrain and (a // 25 < 2 or (b >= 0 and b // 25 < 2))
                barrier = wall and axis == 0 and b >= 0 and a % 5 == 2
                mask |= int(below) << i
                actual |= int(below or barrier) << i
            call('geometry',[h,first,len(faces),actual,mask])
        call('fill',[h,62,1,1.2,0,0,0,pressure,1])
        return h, call('refBegin',[h,end,62,heat])

    h, started = reference_field()
    assert started == [0,0]
    pristine = call('stats',[h])
    call('responseSamples',[h,62],expected=1)
    for cmd, arguments in [('refBegin',[h,0.05,62,0]),('refWalls',[h,0,1,0]),('refAdvance',[h,8])]:
        call(cmd,arguments,expected=1)
    obstructed, shared = reference_field(wall=True)
    assert shared == [1,0]
    while call('refAdvance',[obstructed])[0] != 1:
        pass
    assert call('stats',[h]) == pristine
    assert call('refStats',[h])[0] == 1
    ref_stats = call('refStats',[h])
    for i in (0,4,5):
        assert abs(ref_stats[8][i]+ref_stats[7][i]-ref_stats[5][i]-ref_stats[6][i]) < 1e-7 * max(1,abs(ref_stats[5][i]))
    checks.append('terrain reference advances independently, shares unfinished work and conserves mass/energy/tracer')
    for handle in (h,obstructed):
        while call('stats',[handle])[0] < 0.05-1e-12:
            now = call('stats',[handle])[0]
            call('advance',[handle,min(0.04,0.05-now),8,0.4])
    for cell in (62,63,64,67):
        observed = call('responseSamples',[h,cell])[0]
        assert len(observed) == 13
        assert math.isclose(observed[2],observed[11],rel_tol=1e-10,abs_tol=1e-8)
        assert math.isclose(observed[3],observed[12],rel_tol=1e-10,abs_tol=1e-8)
    shadow = call('responseSamples',[obstructed,64])[0]
    assert shadow[2] == 0 and shadow[3] == 0 and shadow[11] > 0 and shadow[12] > 0
    assert call('refStats',[h]) == ref_stats
    checks.append('identical clear fields give unit attenuation; sealed divider gives zero without contaminating shared reference')
    call('release',[h]); call('release',[obstructed])
    cached, ready = reference_field()
    assert ready == [1,1]
    call('release',[cached])
    changed, fresh = reference_field(pressure=104001)
    assert fresh == [0,0]
    call('release',[changed])
    changed, fresh = reference_field(terrain=False)
    assert fresh == [0,0]
    call('release',[changed])
    checks.append('completed references cache across released jobs; source and terrain changes select distinct entries')

    thermal, fresh = reference_field(heat=1250)
    assert fresh == [0,0]
    while call('refAdvance',[thermal])[0] != 1:
        pass
    while call('stats',[thermal])[0] < 0.05-1e-12:
        now = call('stats',[thermal])[0]
        call('advance',[thermal,min(0.04,0.05-now),8,0.4])
    for cell in (62,63,64):
        observed = call('responseSamples',[thermal,cell])[0]
        assert math.isclose(observed[2],observed[11],rel_tol=1e-10,abs_tol=1e-8)
        assert math.isclose(observed[3],observed[12],rel_tol=1e-10,abs_tol=1e-8)
    thermal_stats = call('refStats',[thermal])
    actual_stats = call('stats',[thermal])
    assert actual_stats[7] == thermal_stats[6]
    for i in (0,4,5):
        assert abs(actual_stats[9][i]+actual_stats[8][i]-actual_stats[6][i]-actual_stats[7][i]) < 1e-7 * max(1,abs(actual_stats[6][i]))
    call('release',[thermal])
    checks.append('prescribed heat release uses the same per-step schedule and conserved ledger in both fields')

    for value in range(18):
        handle, _ = reference_field(pressure=105000+value)
        assert call('refStats',[handle])[4] <= 16
        call('release',[handle])
    orphan = call('create',[5,5,5,2,1.4,1.2,0,0,0,101325,0,0,0,0,0,0,0])[0]
    before = call('stats',[orphan])
    for cmd, arguments in [
        ('refBegin',[orphan,0.05,62,0]),
        ('refBegin',[orphan,-1,62,0]),
        ('refBegin',[orphan,0.05,200,0]),
        ('refBegin',[orphan,0.05,62,-1]),
        ('geometry',[orphan,0,1,2,0]),
        ('geometry',[orphan,0,1,0,2]),
        ('refWalls',[orphan,24575,1,0]),
        ('refAdvance',[orphan]),
        ('responseSamples',[orphan,62])]:
        call(cmd,arguments,expected=1)
    assert call('stats',[orphan]) == before
    call('reset')
    call('refStats',[orphan],expected=1)
    assert call('status') == []
    checks.append('reference cache cap/eviction, incomplete terrain, bad schedules/ranges, release and reset guards')
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
