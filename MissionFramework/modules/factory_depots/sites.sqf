/* [world, sector, centre ATL, bay orientation, clear approach metres].
   Stock belongs inside the objective; access need not connect to a road.
   Runtime checks reject blocked footprints without an exterior fallback. */
[
    // Factory Centre: ordered stock bays along the inside of the warehouse
    // perimeter. Smaller footprints follow the courtyard's uneven ground.
    ["beketov", "factory", [13676, 19004, 0], 0, 0, [
        [[13658, 18992, 0], 42, 0, 3],
        [[13666, 18996, 0], 42, 0, 3],
        [[13674, 19000, 0], 42, 0, 3],
        [[13682, 19008, 0], 42, 1, 3],
        [[13690, 19008, 0], 42, 1, 3],
        [[13694, 19020, 0], 42, 2, 3]
    ]],
    ["fata", "factory_1", [4922.39, 4191.68, 0], 0, 0, [
        // Existing Sukri barn: level floor, six bays and a clear central aisle.
        // The optional final flag selects floor/ceiling checks for indoor bays.
        [[4913.37, 4202.22, 0.5112], 27.1971, 0, 4.2, true],
        [[4924.04, 4196.73, 0.509109], 27.1971, 0, 4.2, true],
        [[4934.72, 4191.25, 0.507019], 27.1971, 0, 4.2, true],
        // Far bank pulled toward the roadside so every pallet is within the
        // standard 15m truck-loading range. The barn aisle is for infantry.
        [[4910.627, 4196.885, 0.5112], 207.197, 1, 3, true],
        [[4921.297, 4191.395, 0.509109], 207.197, 1, 3, true],
        [[4931.977, 4185.915, 0.507019], 207.197, 2, 3, true]
    ]],
    // Khassadar Storage: inner yard beside the administration/warehouse row.
    ["fata", "factory_2", [5685, 6053, 0], 0, 10],
    ["fata", "factory_3", [3582.87, 6003.74, 0], 0, 0, [
        // Energy Plant: supply row between plant buildings, ammunition and
        // fuel bays in the eastern service yard. Leave passages for infantry.
        [[3570, 6014, 0], 0, 0, 3],
        [[3578, 6014, 0], 0, 0, 3],
        [[3586, 6014, 0], 0, 0, 3],
        [[3594, 6008, 0], 0, 1, 3],
        [[3594, 6016, 0], 0, 1, 3],
        [[3598, 6026, 0], 0, 2, 3]
    ]]
]
