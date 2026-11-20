# NEA DATRAS: recorded catch weight

Our catch weight per length bin (`wgt` in `len_freq`) is calculated, not recorded: the number caught in the bin (`HLNoAtLngt` × `SubFactor`, counted) × the weight at length from a length–weight relationship (DATRASextra `add_total_weight_by_haul()`, with `a` and `b` from `species_info`, or 0.01 and 3 where missing). DATRAS also has the recorded catch weight, `CatCatchWgt` (g, in HL), per haul × species × sex × category. It is not in our outputs.

Compared per haul × species in `len_freq` (801,630 of 836,015 matched to the raw HL), with `CatCatchWgt` summed over sex and category.

## Missing

The recorded weight is missing (-9, in at least one sex or category) for 20.6% of the haul × species (164,921 of 801,630). The counted fish, and so our calculated weight, are there.

| Survey | % missing | Range over years (%) | Years all missing |
|---|---|---|---|
| NL-BSAS | 100 | 100 | 7 of 7 (2019–2025) |
| SNS | 100 | 100 | 40 of 40 (1985–2025) |
| DYFS | 97.6 | 89.2 to 100 | 32 of 41 |
| SWC-IBTS | 36.8 | 2.8 to 100 | 10 of 25 (1986–1995) |
| BTS | 21.5 | 0 to 100 | 3 of 41 (1985–1987) |
| NS-IBTS | 19.8 | 0 to 100 | 5 of 61 (1965–1970) |
| ROCKALL | 10.0 | 0 to 22.8 | 0 |
| SCOWCGFS | 6.6 | 0 to 35.7 | 0 |
| SCOROC | 4.1 | 0 to 32.9 | 0 |
| BITS | < 0.1 | 0 to 0.1 | 0 |
| Other 13 surveys | 0 | 0 | 0 |

## Not consistent

In hauls with `DataType` C (numbers per hour), the recorded weight is per hour too: in 30-minute hauls it is about twice the calculated weight (median ratio SWC-IBTS 1.98, PT-IBTS 1.90, FR-CGFS 1.88, BITS 1.79). In 60-minute hauls with `DataType` C the ratio should then be about 1, but in 8,569 of 15,716 haul × species (BITS, NS-IBTS, SWC-IBTS) it is below 0.05 (median 0.0099). Example, `BITS:1991:1:DE:06S1:SON:22043:11`, dab: 40 fish of 14–31 cm (all measured), recorded weight 46, calculated 4,270 g. 46 g for 40 such fish is not possible; 46 would fit if the unit were 100 g (4,600 g). In 30-minute NS-IBTS hauls with `DataType` C, the ratio ranges widely (median 0.84; 10% below 0.02, 10% above 2.2).

In hauls with `DataType` R (numbers per haul), the calculated weight agrees with the recorded one: median ratio 0.88 to 1.01 per survey (NSSS 0.88, the others 0.95 to 1.01), 1.10 to 1.24 in the Spanish surveys. Where they differ by a factor of about 100, the recorded weight is the one that does not fit the counted fish.

## Decision

Not added for now: the catch weight in the outputs is the calculated one (numbers at length converted to weight).

## To do

- If the recorded catch weight is added later (a column per haul × species, e.g. in `len_freq`), it would need: multiplying by `HaulDur` / 60 for `DataType` C (as DATRAS does for the numbers, not for `CatCatchWgt`), a check per survey × country × year of the unit (factor 100), and NA where missing or not consistent.
- Ask the survey contacts about the unit of `CatCatchWgt` in the 60-minute hauls with `DataType` C (BITS, NS-IBTS, SWC-IBTS).
