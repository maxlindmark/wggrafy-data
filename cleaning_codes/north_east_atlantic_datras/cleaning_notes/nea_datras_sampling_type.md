# NEA DATRAS: sampling type (`sampling_type`)

`sampling_type` is `unknown` for all records in `north_east_atlantic_datras`. In the final preparation, join a table of survey, year and sampling strategy (e.g. a csv) to fill it. It decides which records need weighting for length-stratified subsampling; the mean length at age uses the plain mean for `random` and the weighted mean for `length-stratified` and `unknown`.

## To do

- Fill `sampling_type` per survey (and year, where it changed), once the sampling type glossary is written (see `TODO.md`).
