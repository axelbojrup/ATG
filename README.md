# Findings

Data quality and modeling issues observed across the `raw` SWAPI source tables (`raw.films`, `raw.people`, `raw.planets`, `raw.species`, `raw.starships`, `raw.vehicles`) in `swapi/dev.duckdb`.

## 1. Inconsistent Missing Values

Missing data is represented inconsistently across tables and columns—mixing string sentinels, casing variants, SQL `NULL`, and empty arrays:

- **`"unknown"`**: Used across almost all tables, including **`planets.name`** (1 row), `people` (`height`, `mass`, `skin_color`, `eye_color`, `birth_year`), `planets` (`rotation_period`, `orbital_period`, `diameter`, `climate`, `gravity`, `terrain`, `surface_water`, `population`), `species` (`classification`, `average_height`, `hair_colors`, `eye_colors`, `average_lifespan`, `language`), `starships` (`cost_in_credits`, `max_atmosphering_speed`, `crew`, `passengers`, `cargo_capacity`, `consumables`, `hyperdrive_rating`, `MGLT`), and `vehicles` (`manufacturer`, `cost_in_credits`, `length`, `max_atmosphering_speed`, `passengers`, `cargo_capacity`, `consumables`).
- **`"n/a"` vs `"N/A"`**: Lowercase `"n/a"` appears in `people` (`hair_color`, `gender`), `species` (`average_height`, `skin_colors`, `hair_colors`, `eye_colors`, `language`), and `starships` (`max_atmosphering_speed`, `passengers`); uppercase `"N/A"` appears in `planets.gravity` (1 row).
- **`"none"`**: Used in `people` (`hair_color`: 36 rows, `gender`: 1 row), `species.hair_colors` (26 rows), and `vehicles` (`cargo_capacity`: 3 rows, `consumables`: 10 rows).
- **`"indefinite"`**: Used in `species.average_lifespan` (1 row).
- **`"0"`**: Used alongside `"none"` and `"unknown"` in `vehicles.consumables`.
- **SQL `NULL`**: Appears in `species.homeworld` (1 row) rather than a string sentinel.
- **Empty arrays (`[]`)**: Used for missing/absent relationships in `VARCHAR[]` columns (e.g., `people.species` has 32 empty arrays, `people.vehicles` has 71, `people.starships` has 63, `planets.films` has 40, `starships.pilots` has 21, `vehicles.pilots` has 29).

## 2. References Using URLs

All primary keys and foreign-key references use full SWAPI URLs (e.g., `https://swapi.dev/api/people/1/`) instead of integer/surrogate IDs:

- **Primary keys (`url`)**: Every table uses `url` (`VARCHAR`) as its unique identifier.
- **Scalar URL foreign keys**: `people.homeworld` and `species.homeworld` reference `planets.url`.
- **Array URL foreign keys**: All relationship arrays store lists of `url` strings (see Section 3).
- *Note*: Across the current snapshot, there are **0 dangling URLs** and all 9 bidirectional relationship pairs (e.g., `people.homeworld` ↔ `planets.residents`, `vehicles.pilots` ↔ `people.vehicles`, `films.characters` ↔ `people.films`) are mutually consistent.

## 3. One-to-Many / Many-to-Many Array References per Row

All 6 source tables store multi-valued relationships as `VARCHAR[]` arrays directly on the parent row rather than normalized bridge/junction tables:

- **`raw.films`**: `characters` (up to 40/row), `planets` (up to 13/row), `starships` (up to 12/row), `vehicles` (up to 13/row), `species` (up to 20/row)
- **`raw.people`**: `films` (up to 6/row), `species` (up to 1/row — stored as an array despite being 0-or-1), `vehicles` (up to 2/row), `starships` (up to 5/row)
- **`raw.planets`**: `residents` (up to 11/row), `films` (up to 5/row)
- **`raw.species`**: `people` (up to 4/row), `films` (up to 6/row)
- **`raw.starships`**: `pilots` (up to 4/row), `films` (up to 3/row)
- **`raw.vehicles`**: `pilots` (up to 2/row), `films` (up to 3/row)

## 4. Additional Issues Across Sources

### Numeric Fields Stored as `VARCHAR` with Formatting Anomalies
Nearly all quantitative columns are typed as `VARCHAR` due to sentinel strings and formatting inconsistencies that break direct numeric casting:
- **Thousands-separator commas**: `people.mass` (`"1,358"`), `starships.length` (`"1,600"`), `starships.crew` (`"47,060"`, `"342,953"`, `"279,144"`), and `starships.passengers` (`"843,342"`).
- **Ranges**: `starships.crew` contains `"30-165"`.
- **Embedded unit suffixes**: `starships.max_atmosphering_speed` contains `"1000km"`.
- **Trailing whitespace**: `vehicles.length` contains `"36.8 "`, `"10.4 "`, and `"3.4 "`.

### Mixed Units and Free-Text in Measurement Columns
- **`planets.gravity`**: Mixes bare numbers (`"0.9"`, `"0.98"`, `"1"`, `"1.56"`), numbers with `" standard"` (`"0.9 standard"`, `"1 standard"`), and a multi-location free-text string (`"1.5 (surface), 1 standard (Cloud City)"`).
- **`starships.consumables` & `vehicles.consumables`**: Mixes time units (`"15 hours"`, `"5 days"`, `"1 week"`, `"1 month"`, `"2 years"`) and includes free-text (`"Live food tanks"` in `vehicles.consumables`).
- **`people.birth_year`**: Encoded as Star Wars epoch strings (`"19BBY"`, `"41.9BBY"`, etc.) rather than numeric years.

### Comma-Separated Multi-Valued Strings in Scalar `VARCHAR` Columns
Unlike the URL relationships (which are `VARCHAR[]`), several descriptive attributes store multiple values as comma-separated strings in a single `VARCHAR` column:
- `films.producer` (3 rows, e.g., `"Gary Kurtz, Rick McCallum"`)
- `people.hair_color` (3 rows), `people.skin_color` (14 rows), `people.eye_color` (2 rows)
- `planets.climate` (11 rows), `planets.terrain` (43 rows)
- `species.skin_colors` (25 rows), `species.hair_colors` (6 rows), `species.eye_colors` (15 rows)
- `starships.manufacturer` (13 rows), `vehicles.manufacturer` (6 rows)

### Categorical, Naming, and Text Formatting Inconsistencies
- **`species.classification` & `species.designation`**:
  - Singular/plural and adjective inconsistencies in `classification`: `"mammal"` vs `"mammals"`, `"reptile"` vs `"reptilian"`.
  - Misclassified values across columns: `"sentient"` appears in `species.classification` (normally a `designation`), while `"reptilian"` appears in `species.designation` (normally a `classification`).
- **Trailing whitespace in categories**: `planets.climate` contains `"artificial temperate "`.
- **Column casing**: `starships.MGLT` is uppercase while all other columns are `snake_case`.
- **Line endings**: `films.opening_crawl` contains Windows-style `\r\n` (CRLF) line breaks in all 6 rows.
