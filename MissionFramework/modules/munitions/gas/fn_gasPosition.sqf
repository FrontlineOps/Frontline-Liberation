params ["_job", "_index"];
private _cell = _job get "gasCell";
private _n = _job getOrDefault ["gasN", 7];
private _half = (_n - 1) / 2;
(_job get "origin") vectorAdd [
    ((_index mod _n) - _half) * _cell,
    ((floor ((_index mod (_n * _n)) / _n)) - _half) * _cell,
    ((floor (_index / (_n * _n))) - _half) * _cell
]
