# NEA DATRAS: hauls with missing positions

DATRAS sets the haul position (`lon`, `lat`) to the shoot position (`ShootLong`, `ShootLat`). In the download of 2026-10-13, 311 hauls kept by `clean_datras()` had an incomplete shoot position:

| Hauls | Raw data | Handling |
|---|---|---|
| 22 (16 SWC-IBTS, 5 PT-IBTS, 1 SCOWCGFS) | shoot longitude missing, haul position (`HaulLat`, `HaulLong`) complete | position set to the haul position in the `get_` script |
| 283 DYFS (1985-1993, one in 1997 and one in 2012) | no shoot or haul position and no ICES rectangle | dropped from `haul`, `len_freq` and `ind_age` in the `clean_` script |
| 6 (4 SWC-IBTS, 2 PT-IBTS) | no shoot or haul longitude | dropped from `haul`, `len_freq` and `ind_age` in the `clean_` script |

Before this, aged fish in these hauls were dropped but the hauls and their catch were kept. The dropped hauls held 50,384 caught fish (of 564 million in `len_freq`).
