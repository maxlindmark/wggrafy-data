# DATRAS: more aged fish than caught fish in a haul
2026-11-18

In DATRAS, every aged fish (CA table) belongs to a haul, so we would expect it to be one of the fish caught and measured in that haul (HL table). In some hauls this can’t be the case: there are more aged fish than fish caught, or the aged fish are of lengths that weren’t caught. The examples below are read straight from the DATRAS exchange files (downloaded 13 October 2026).

``` r
library(dplyr)
home <- here::here()

# Read the HL and CA records of one exchange file
read_datras_csv <- function(zip) {
  unzip(zip, exdir = tempdir())
  lines <- readLines(file.path(tempdir(), "DATRAS.csv"))
  start <- which(startsWith(lines, "RecordType,"))
  end <- c(start[-1] - 1, length(lines))
  d <- lapply(1:3, function(i) read.csv(text = lines[start[i]:end[i]]))
  names(d) <- sapply(d, function(x) x$RecordType[1])
  d
}
```

## BTS 2009, Belgium: plaice

12 plaice caught (all measured), 22 aged.

``` r
d <- read_datras_csv(file.path(home, "raw_data/north_east_atlantic_datras/BTS/BTS_2009.zip"))

hl <- d$HL |>
  filter(Country == "BE", Ship == "11BE", Gear == "BT4A", StNo == 81, HaulNo == 25, Quarter == 3, ValidAphiaID == 127143) |>
  select(LngtClass, HLNoAtLngt, SubFactor) |>
  arrange(LngtClass)
hl
```

      LngtClass HLNoAtLngt SubFactor
    1       125          1         1
    2       140          2         1
    3       145          1         1
    4       150          1         1
    5       160          3         1
    6       170          1         1
    7       180          1         1
    8       185          1         1
    9       210          1         1

``` r
ca <- d$CA |>
  filter(Country == "BE", Ship == "11BE", Gear == "BT4A", StNo == 81, HaulNo == 25, Quarter == 3, ValidAphiaID == 127143) |>
  count(LngtClass, wt = CANoAtLngt, name = "CANoAtLngt")
ca
```

      LngtClass CANoAtLngt
    1       150          4
    2       160          2
    3       170          4
    4       180          5
    5       190          2
    6       200          4
    7       250          1

``` r
# Total caught (HLNoAtLngt x SubFactor) and aged
c(caught = sum(hl$HLNoAtLngt * hl$SubFactor), aged = sum(ca$CANoAtLngt))
```

    caught   aged 
        12     22 

## NS-IBTS 2006, Sweden: haddock

125 haddock caught (250 per hour in a 30-minute haul), all 10–17 cm. 9 aged, all 32–50 cm.

``` r
d <- read_datras_csv(file.path(home, "raw_data/north_east_atlantic_datras/NS-IBTS/NS-IBTS_2006.zip"))

hl <- d$HL |>
  filter(Country == "SE", Ship == "77AR", Gear == "GOV", StNo == 495, HaulNo == 44, Quarter == 3, ValidAphiaID == 126437) |>
  select(LngtClass, HLNoAtLngt, SubFactor) |>
  arrange(LngtClass)
hl
```

      LngtClass HLNoAtLngt SubFactor
    1        10          2         1
    2        11          4         1
    3        12         24         1
    4        13         46         1
    5        14         94         1
    6        15         60         1
    7        16         16         1
    8        17          4         1

``` r
ca <- d$CA |>
  filter(Country == "SE", Ship == "77AR", Gear == "GOV", StNo == 495, HaulNo == 44, Quarter == 3, ValidAphiaID == 126437) |>
  count(LngtClass, wt = CANoAtLngt, name = "CANoAtLngt")
ca
```

      LngtClass CANoAtLngt
    1        32          1
    2        34          1
    3        37          1
    4        44          1
    5        45          1
    6        46          1
    7        48          1
    8        49          1
    9        50          1

``` r
# Total caught (HLNoAtLngt x SubFactor is per hour; the haul lasted 30 minutes), caught at the lengths of the aged fish, and aged
c(
  caught = sum(hl$HLNoAtLngt * hl$SubFactor) * 30 / 60,
  caught_at_aged_lengths = sum((hl$HLNoAtLngt * hl$SubFactor)[hl$LngtClass %in% ca$LngtClass]) * 30 / 60,
  aged = sum(ca$CANoAtLngt)
)
```

                    caught caught_at_aged_lengths                   aged 
                       125                      0                      9 

## BITS 1996, Sweden: cod

53 cod caught (106 per hour in a 30-minute haul), 71 aged.

``` r
d <- read_datras_csv(file.path(home, "raw_data/north_east_atlantic_datras/BITS/BITS_1996.zip"))

hl <- d$HL |>
  filter(Country == "SE", Ship == "77AR", Gear == "FOT", StNo == 232, HaulNo == 27, Quarter == 4, ValidAphiaID == 126436) |>
  select(LngtClass, HLNoAtLngt, SubFactor) |>
  arrange(LngtClass)
hl
```

       LngtClass HLNoAtLngt SubFactor
    1         20          2         1
    2         21          2         1
    3         23         10         1
    4         24         10         1
    5         25         10         1
    6         26          8         1
    7         27         10         1
    8         28          8         1
    9         29         10         1
    10        30          4         1
    11        31          8         1
    12        33          8         1
    13        35          6         1
    14        36          2         1
    15        37          6         1
    16        54          2         1

``` r
ca <- d$CA |>
  filter(Country == "SE", Ship == "77AR", Gear == "FOT", StNo == 232, HaulNo == 27, Quarter == 4, ValidAphiaID == 126436) |>
  count(LngtClass, wt = CANoAtLngt, name = "CANoAtLngt")
ca
```

       LngtClass CANoAtLngt
    1         20          1
    2         21          1
    3         23          5
    4         24          5
    5         25          5
    6         26          4
    7         27          5
    8         28          4
    9         29          5
    10        30          2
    11        31          4
    12        33          4
    13        35          3
    14        36          1
    15        37          3
    16        38          4
    17        39          4
    18        40          2
    19        41          1
    20        42          2
    21        43          3
    22        44          1
    23        46          1
    24        54          1

``` r
# Total caught (HLNoAtLngt x SubFactor is per hour; the haul lasted 30 minutes) and aged
c(caught = sum(hl$HLNoAtLngt * hl$SubFactor) * 30 / 60, aged = sum(ca$CANoAtLngt))
```

    caught   aged 
        53     71 

## How common

Share of hauls with aged fish where, for at least one species, more fish were aged than caught (caught fish per hour converted to the haul for hourly data).

| Survey                                                               | % of hauls                      |
|----------------------------------------------------------------------|---------------------------------|
| SNS                                                                  | 30.8                            |
| BTS                                                                  | 13.5                            |
| NIGFS                                                                | 9.3                             |
| DYFS                                                                 | 5.1                             |
| FR-CGFS                                                              | 5.0                             |
| EVHOE                                                                | 3.6                             |
| NL-BSAS                                                              | 3.0                             |
| SWC-IBTS                                                             | 2.8                             |
| NS-IBTS                                                              | 2.5                             |
| SP-NORTH                                                             | 2.0                             |
| SE-SOUND                                                             | 1.4                             |
| BITS                                                                 | 1.3                             |
| SP-PORC                                                              | 1.1                             |
| IE-IGFS                                                              | 0.7                             |
| SCOWCGFS                                                             | 0.2                             |
| PT-IBTS                                                              | 0.1                             |
| BTS-VIII, FR-WCGFS, IE-IAMS, NS-IDPS, NSSS, ROCKALL, SCOROC, SP-ARSA | 0                               |
| **All surveys**                                                      | **4.7** (4,090 of 86,360 hauls) |

EVHOE after correcting `DataType` in 2018 (numbers per haul, not per hour; see [`nea_datras_datatype_corrections.md`](nea_datras_datatype_corrections.md)).
