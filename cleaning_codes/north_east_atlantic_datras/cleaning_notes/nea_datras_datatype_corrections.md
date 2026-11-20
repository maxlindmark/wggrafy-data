# NEA DATRAS: DataType corrections

`DataType` in the haul records (HH) says whether the catch numbers at length (HL) are per haul (R) or per hour (C). For C, DATRAS converts them to the haul when the data are read (`DATRAS:::addExtraVariables()`: `Count` = `HLNoAtLngt` × `HaulDur` / 60 × `SubFactor`), and `DATRAS::addSpectrum()` (used by `DATRASextra::add_numbers_at_length()`) rounds the numbers per length class, where 0.5 rounds to 0.

## Corrected: EVHOE 2018

All 155 hauls of EVHOE 2018 have `DataType` C; all other EVHOE years have R. The numbers are per haul:

* In numbers per hour from a 30-minute haul, one fish is 2 per hour, so `HLNoAtLngt` is never 1. In EVHOE 2018, 154 of the 155 hauls have length classes with 1 (42% of all length classes, as in the years with R; 0% in FR-CGFS 2018, which is per hour).
* The sum of `HLNoAtLngt` equals the number measured (`NoMeas`) as in the years with R, and never `NoMeas` × 60 / `HaulDur`.

Read as per hour, the catch is halved, length classes with one fish are rounded to 0 (so some haul × species have no catch at all), and many haul × species have more aged than caught fish. Raw data: [`nea_datras_evhoe_2018.md`](nea_datras_evhoe_2018.md).

Correction in `get_north_east_atlantic_datras.R`, after `read_datras()`: for EVHOE 2018 hauls with `DataType` C, `Count` is multiplied by 60 / `HaulDur` (undoing the conversion) and `DataType` is set to R. To be removed if DATRAS is corrected.

## Not corrected: BITS

The same test (hauls of 40 minutes or less with `DataType` C and a length class with `HLNoAtLngt` 1) finds about 50 other hauls, all in BITS: Lithuania 2008–2010, 2015 and 2016 (45 of 54 hauls), Estonia 2006 (4 of 4) and Denmark 2018 (1 of 1). Not corrected, as the evidence is a few hauls per year. Checked per haul were the survey × year × country with `DataType` C where at least 10% of the length classes have 1; in the other four (BITS DE 1992, BITS SE 1993, NS-IBTS GB 1991, NS-IBTS GB-SCT 1998), the 1s are almost all in hauls of 60 minutes, where one fish is 1 per hour (270 of the 281 hauls with a 1; the other 11 are 40 to 77 minutes), and in the short hauls only in 1 of 48 in BITS SE 1993.

## To do

- EVHOE: ask the survey contacts to confirm that the 2018 numbers are per haul.
- BITS: ask the Baltic survey contacts about the hauls above; correct as for EVHOE if confirmed.
