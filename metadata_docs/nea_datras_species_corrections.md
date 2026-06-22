# NEA DATRAS: Species-specific length corrections

Corrections applied in `cleaning_codes/north-east-atlantic-datras/clean_north_east_atlantic_datras.R`.  
All issues were identified from per-species length-at-age plots (coloured by `lngt_code`) saved in `cleaning_codes/north-east-atlantic-datras/check_species_laa/`.

The dominant error pattern is `lngt_code == 1` records where lengths were stored in mm but treated as cm, producing values 10× too large. Where dividing by 10 yields a biologically plausible result the fix is applied; where it does not (values still implausible after correction), records are removed instead.

## Summary table

| Species | Survey(s) | Issue | Fix |
|---|---|---|---|
| *Zeus faber* | all | mm stored as cm (`lngt_cm > 100`) | ÷ 10; residual values > 75 cm removed |
| *Trisopterus luscus* | all | mm stored as cm (`lngt_cm > 50`) | ÷ 10 |
| *Platichthys flesus* | BITS | mm stored as cm (`lngt_cm > 70`) | ÷ 10; records with age > 30 removed |
| *Lepidorhombus boscii* | SP-NORTH | horizontal band at 50–90 cm unrelated to unit code | remove `lngt_cm > 45`; **TODO: age-0 range still implausible, needs further investigation** |
| *Lepidorhombus whiffiagonis* | SP-NORTH, SP-PORC | outliers above species max (~60 cm) | remove `lngt_cm > 65`; **TODO: SP-NORTH age-0 still implausible, SP-PORC needs revisiting** |
| *Lophius piscatorius* | NS-IBTS | age-0 fish above 40 cm (impossible for 0-group) | remove |
| *Clupea harengus* | NS-IBTS | mm stored as cm at young ages (`lngt_cm > 60`) | ÷ 10 |
| *Conger conger* | all | mm stored as cm (`lngt_cm > 400`) | ÷ 10 |
| *Engraulis encrasicolus* | NS-IBTS | `lngt_code 1` cloud at age 1 in 20–37 cm range; ÷ 10 gives 2–4 cm (too small for age-1) | remove `lngt_code 1` records > 20 cm |
| *Gadus morhua* | BITS | values > 200 cm erroneous | remove |
| *Pleuronectes platessa* | all | values > 100 cm exceed species max (~95 cm) | remove |
| *Sardina pilchardus* | NS-IBTS | `lngt_code 1` age-1 cloud at 19–34 cm vs `lngt_code 0` at 7–17 cm; ÷ 10 gives 2–3 cm (too small for age-1); ages 3+ overlap correctly | remove `lngt_code 1` age-1 records > 17 cm |
| *Scophthalmus maximus* | all | values > 100 cm exceed species max (~100 cm) | remove |
| *Sprattus sprattus* | BITS | `lngt_code 1` dots at 16–30 cm at age 1–2; ÷ 10 gives 1.6–3 cm (too small) | remove `lngt_code 1` records > 20 cm |
| *Phycis blennoides* | N/A | issue visible in plots but no clean fix identified | no action taken |

## Species notes

### *Zeus faber* (John Dory, max ~90 cm)
Unit mismatch: `lngt_cm > 100` divided by 10. After correction a residual cloud of age-1 fish remains above 75 cm, which is still implausible; these are removed with a hard filter.

### *Trisopterus luscus* (Pouting, max ~45 cm)
Straightforward unit mismatch: values above 50 cm divided by 10.

### *Platichthys flesus* (European Flounder, max ~60 cm)
Unit mismatch confined to BITS survey. After ÷ 10 fix, a handful of age records above 30 years remain; these are biologically implausible and removed.

### *Lepidorhombus boscii* (Four-spot Megrim, max ~45 cm)
SP-NORTH shows a distinct horizontal band of records at 50–90 cm. Unlike the typical mm/cm mismatch, dividing by 10 yields 5–9 cm for old fish, which is also implausible. The source of the error is unclear; records above 45 cm in SP-NORTH are removed.

**TODO:** After the > 45 cm fix, SP-NORTH still contains age-0 fish spanning 0–40 cm, which is biologically implausible (age-0 individuals should be a narrow band at small sizes). The source of this pattern is unclear. SP-NORTH data for this species should be excluded or investigated further before use.

### *Lepidorhombus whiffiagonis* (Megrim, max ~60 cm)
SP-NORTH and SP-PORC show scattered outliers above 65 cm. Still looks somewhat unusual even after removal; worth revisiting with additional data.

**TODO:** After the > 65 cm fix, SP-NORTH still shows a biologically implausible length range at age 0 (similar to *L. boscii* above). SP-PORC also remains suspicious and should be revisited. Both surveys for this species should be treated with caution.

### *Lophius piscatorius* (Angler, NS-IBTS)
Age-0 fish recorded above 40 cm are impossible for 0-group individuals. Removed.

### *Clupea harengus* (Atlantic Herring, max ~45 cm)
NS-IBTS contains `lngt_code 1` outliers above 60 cm at young ages. Divided by 10.

### *Conger conger* (European Conger, max ~300 cm)
Unit mismatch at very high values (> 400 cm). Divided by 10.

### *Engraulis encrasicolus* (European Anchovy, max ~20 cm)
NS-IBTS `lngt_code 1` records form a cloud at 20–37 cm for age-1 fish, well above the species maximum. Dividing by 10 gives 2–4 cm, which is too small for age-1 anchovy. These records cannot be salvaged and are removed.

### *Gadus morhua* (Atlantic Cod, max ~150 cm)
BITS contains a small number of records above 200 cm. Removed as erroneous.

### *Pleuronectes platessa* (European Plaice, max ~95 cm)
Values above 100 cm removed across all surveys.

### *Sardina pilchardus* (European Pilchard, max ~25 cm)
NS-IBTS shows two distinct age-1 clouds: `lngt_code 0` at 7–17 cm (plausible) and `lngt_code 1` at 19–34 cm (implausible). At ages 3+, both codes overlap, so the issue is age-1 specific. Dividing by 10 gives 2–3 cm (too small for age-1 sardine). Age-1 `lngt_code 1` records above 17 cm are removed.

### *Scophthalmus maximus* (Turbot, max ~100 cm)
Values above 100 cm removed across all surveys.

### *Sprattus sprattus* (European Sprat, max ~19 cm)
BITS contains a handful of `lngt_code 1` records at 16–30 cm for age 1–2 fish. Dividing by 10 gives 1.6–3 cm, which is too small. Records removed.

### *Phycis blennoides* (Greater Forkbeard)
Plots show something unusual but no clean correction could be identified. No action taken; flagged for future review.
