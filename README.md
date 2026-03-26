# COBOL Trading System — Study Programs

**Author:** Matheus  
**Started:** April 2025  
**Environment:** IBM z/OS Mainframe (JCL + Enterprise COBOL)

---

## Overview

This repository contains a set of COBOL programs developed as part of a learning journey into mainframe programming. The programs revolve around a **trading journal** theme — processing trade records, computing risk/reward metrics, categorizing results, generating statistics, and handling multi-currency conversions.

The project is organized into three progressively more complex programs, their corresponding JCL jobs, shared copybooks for file layouts, and inline test data.

---

## Repository Structure

```
.
├── trading1-files
    ├── TRADING1.cbl        COBOL — Batch trade enrichment (add IDs, R/R ratio, result category)
    ├── TRADJOB1.jcl        JCL  — Runs TRADING1 against sequential datasets
├── trading2-files
    ├── TRADING2.cbl        COBOL — Batch statistical analysis (AVG, SD, MIN, MAX)
    ├── TRADJOB2.jcl        JCL  — Runs TRADING2 against sequential datasets
├── trading9-files
    ├── TRADING9.cbl        COBOL — Interactive trade processor with currency conversion
    ├── TRADJOB9.jcl        JCL  — Runs TRADING9 with inline SYSIN test data
├── file-layouts
    ├── TRADENT1.cpy        Copybook — INPUT-TRADE record layout
    ├── TRADEXT1.cpy        Copybook — OUTPUT-TRADE record layout
    ├── STATS001.cpy        Copybook — STATS output record layout
└── README.md           This file
```

---

## Programs

### TRADING1 — Batch Trade Enrichment

| Detail | Value |
|---|---|
| **Program-ID** | `TRADING1` |
| **Date Written** | 14/07/2025 |
| **Input File** | `TRADE001` (80-byte fixed, sequential) |
| **Output File** | `TRADS001` (80-byte fixed, sequential) |

**Purpose:** Reads raw trade records and enriches them with a sequential trade ID, a risk/reward ratio, and a result category before writing them to an output file.

**How it works:**

1. Opens `TRADE001` for input and `TRADS001` for output, validating file status codes on both.
2. Reads each record in a `PERFORM UNTIL` loop with `AT END` / `NOT AT END` handling.
3. For each record, calls three processing paragraphs:
   - `21-MOVE-VARS` — Transfers and prepares working variables from the input record.
   - `22-CALC-RES-CAT` — Determines a 2-character result category (`RES-CAT`) based on the result value.
   - `23-CALC-RR-RATIO` — Computes the risk/reward ratio (`TP / SL`).
4. Writes the enriched `OUTPUT-TRADE` record (which adds `TRADE-ID`, `RR-RATIO`, and `RES-CAT` to the original fields).

**Key COBOL concepts demonstrated:** File I/O with status checking, `PERFORM UNTIL`, `READ ... AT END / NOT AT END`, sequential file processing, `WRITE`, and section-based program structure.

> **Note:** The source for sections `21-MOVE-VARS`, `22-CALC-RES-CAT`, `23-CALC-RR-RATIO`, and `90-ENDING` was not fully visible in the original screenshots. These sections are referenced but their implementation is not included in this transcription.

---

### TRADING2 — Batch Statistical Analysis

| Detail | Value |
|---|---|
| **Program-ID** | `TRA02` |
| **Date Written** | 14/07/2025 |
| **Input File** | `TRADE001` (80-byte fixed, sequential) |
| **Output File** | `STATS001` (30-byte fixed, sequential) |

**Purpose:** Reads trade records, separates gains and losses into internal tables, then computes descriptive statistics on each column and writes the results to a statistics file.

**How it works:**

1. Opens files and reads all records into two in-memory arrays:
   - `WS-GAIN-COL` — Stores positive `RES-VAL` values (gains).
   - `WS-LOSS-COL` — Stores negative `RES-VAL` values (losses).
   - Both arrays support up to 50 entries (`OCCURS 50 TIMES INDEXED BY I`).
2. After loading all records, calls four calculation sections in `20-PROCEDURES`:
   - `21-CALC-AVG` — Uses `FUNCTION MEAN` on each column.
   - `22-CALC-SD` — Uses `FUNCTION STANDARD-DEVIATION` on each column.
   - `23-CALC-MIN` — Uses `FUNCTION MIN` on each column.
   - `24-CALC-MAX` — Uses `FUNCTION MAX` on each column.
3. Each section moves the stat label (e.g., `'AVG'`, `'SD'`) into `STAT`, computes the value for gains and losses, and the record is written to `STATS001`.

**Output record format** (30 bytes):

| Field | PIC | Description |
|---|---|---|
| `STAT` | `X(03)` | Statistic label: `AVG`, `SD`, `MIN`, or `MAX` |
| `LOSS` | `9(03)V99` | Computed value for the loss column |
| `GAIN` | `9(03)V99` | Computed value for the gain column |
| `FILLER` | `X(17)` | Padding |

**Key COBOL concepts demonstrated:** Internal tables with `OCCURS` and `INDEXED BY`, intrinsic functions (`MEAN`, `STANDARD-DEVIATION`, `MIN`, `MAX`), the `(ALL)` subscript for operating on entire arrays, two-phase processing (load then compute), and `77`-level standalone variables.

---

### TRADING9 — Interactive Trade Processor with Currency Conversion

| Detail | Value |
|---|---|
| **Program-ID** | `TRADING9` |
| **Date Written** | 07/04/2025 |
| **Input** | `SYSIN` (inline data via `ACCEPT`) |
| **Output** | `DISPLAY` to `SYSOUT` |

**Purpose:** The most complete program. Accepts trade records interactively from SYSIN, classifies the market into an investment type using a two-dimensional lookup table, computes risk/reward ratios, categorizes results into outcome labels, handles BRL-to-USD currency conversion, and maintains a running USD balance (margin).

**How it works:**

1. **Initialization** — Sets starting balance to `100.00` USD and the USD/BRL exchange rate to `5.93`.

2. **Input parsing** — Each SYSIN line is accepted into `WS-INPUT`, which is structured as:
   ```
   YYYYMMDD MARKET TP    SL    RESULT CUR
   20250320 USA500 01023 00700 -00500 USD
   ```

3. **Market classification** — Uses a hardcoded 2D table (`TB-2DIM`) with three investment types, each containing four market codes:

   | Type Code | Label | Markets |
   |---|---|---|
   | `FTR` | Futures | WINFUT, WDOFUT, USA500, AUS200 |
   | `ETF` | ETFs | QQQ, IVVB11, FOMO11, HASH11 |
   | `STK` | Stocks | APPLUS, NVDAUS, PETR4, VALE3 |

   A nested `PERFORM VARYING` loop searches the table. If no match is found, the type code defaults to `'404'` and an error is displayed.

4. **Trade computation** (`2002-COMPUTE`):
   - Calculates risk/reward ratio: `WS-RR-RATIO = WS-TAKE-PROFIT / WS-STOP-LOSS`.
   - Computes the negative stop-loss: `WS-STOP-LOSS-NEG = -1 * WS-STOP-LOSS`.
   - Increments the trade ID counter.
   - Categorizes the result into one of five outcomes:

     | Condition | Label |
     |---|---|
     | `RESULT >= TAKE-PROFIT` | `FULL GAIN` |
     | `RESULT > 0` | `SMALL GAIN` |
     | `RESULT = 0` | `ZERO` |
     | `RESULT <= -STOP-LOSS` | `FULL LOSS` |
     | Otherwise | `SMALL LOSS` |

5. **Currency conversion** (`2100-CONVERTER`):
   - `USD` trades: Result value is added directly to the balance.
   - `BRL` trades: Take-profit, stop-loss, and result are divided by the USD/BRL ratio before updating the balance.
   - Any other currency triggers `9999-ERROR` and a `GOBACK`.

6. **Display sections** — Multiple `DISPLAY` sections produce formatted output:
   - `2996-DISP-CODE-TYPES` — Prints the full market lookup table (shown only on the first trade).
   - `2997-DISP` — Shows trade ID, balance, investment type, formatted date (built with `STRING ... DELIMITED BY SIZE ... INTO`), market, and result label.
   - `2998-DISP-USD` — Displays TP, SL, result, and R/R ratio in USD using edit masks.
   - `2999-DISP-USD-BRL` — Same display but for BRL trades after conversion.

7. **Termination** — The loop ends when the input year starts with `'END'`. The `9000-ENDING` section displays a closing message.

**Key COBOL concepts demonstrated:** `ACCEPT ... FROM SYSIN`, `EVALUATE ... WHEN ... WHEN OTHER`, nested `PERFORM VARYING` with indexes, `STRING ... DELIMITED BY SIZE ... INTO ... ON OVERFLOW`, `REDEFINES` for table structures, `88`-level condition names, edit masks (numeric formatting with `PIC ZZ999,99` and `PIC +999,99`), `COMPUTE` with arithmetic, `ADD ... TO ... END-ADD`, and `GOBACK`.

---

## Copybooks

### TRADENT1.cpy — Input Trade Record

Defines the layout of raw trade input records (used by TRADING1 and TRADING2 via `TRADE001`).

| Field | PIC | Bytes | Description |
|---|---|---|---|
| `MARKET` | `X(06)` | 6 | Market identifier (e.g., `USA500`) |
| `TAKE-PROFIT` | `9(03)V99` | 5 | Take-profit price (3 integer, 2 decimal) |
| `STOP-LOSS` | `9(03)V99` | 5 | Stop-loss price |
| `RESULT-VALUE` | `S9(03)V99` | 6 | Trade result (signed, leading separate) |
| `CUR` | `X(03)` | 3 | Currency code (`USD` or `BRL`) |
| `FILLER` | `X(55)` | 55 | Padding to fill 80-byte record |
| **Total** | | **80** | |

### TRADEXT1.cpy — Output Trade Record

Defines the enriched output layout produced by TRADING1 (written to `TRADS001`).

| Field | PIC | Bytes | Description |
|---|---|---|---|
| `TRADE-ID` | `9(03)` | 3 | Sequential trade identifier |
| `MARKET` | `X(06)` | 6 | Market identifier |
| `TP` | `9(03)V99` | 5 | Take-profit |
| `SL` | `9(03)V99` | 5 | Stop-loss |
| `RR-RATIO` | `9(03)V99` | 5 | Risk/reward ratio |
| `RES-VAL` | `S9(03)V99` | 6 | Result value (signed, leading separate) |
| `CUR` | `X(03)` | 3 | Currency code |
| `RES-CAT` | `X(02)` | 2 | Result category |
| `FILLER` | `X(45)` | 45 | Padding |
| **Total** | | **80** | |

### STATS001.cpy — Statistics Record

Defines the output of TRADING2's statistical computations.

| Field | PIC | Bytes | Description |
|---|---|---|---|
| `STAT` | `X(03)` | 3 | Statistic type (`AVG`, `SD`, `MIN`, `MAX`) |
| `LOSS` | `9(03)V99` | 5 | Value computed on the loss column |
| `GAIN` | `9(03)V99` | 5 | Value computed on the gain column |
| `FILLER` | `X(17)` | 17 | Padding |
| **Total** | | **30** | |

---

## JCL Jobs

### TRADJOB1 — Run TRADING1

Executes the TRADING1 batch program against mainframe datasets.

- **Step ST01**: Uses `IDCAMS` to delete the output dataset `DES.SYS.MZ.BGT1.TRADS001` (with `SET MAXCC=0` to avoid a failure if the file doesn't exist yet).
- **Step PT01**: Runs `PGM=TRADING1`.
  - `TRADE001 DD` → Input: `DES.SYS.MZ.BGT1.TRADE001` (shared).
  - `TRADS001 DD` → Output: `DES.SYS.MZ.BGT1.TRADS001` (new, cataloged, 80-byte LRECL, allocated on SYSDA).

### TRADJOB2 — Run TRADING2

Same structure as TRADJOB1, but runs `PGM=TRADING2`.

- **Step ST01**: Deletes `DES.SYS.MZ.BGT1.TRADE001` before re-creation.
- **Step PT01**: Runs `PGM=TRADING2`.
  - `TRADE001 DD` → Input (shared).
  - `STATS001 DD` → Output (new, cataloged, 80-byte LRECL).

### TRADJOB9 — Run TRADING9 (with inline test data)

Unlike the other jobs, this one provides trade data inline via `SYSIN DD *` rather than referencing a dataset.

- **Step PT01**: Runs `PGM=TRADING9` with `REGION=512K`.
- Inline data contains 14 trade records plus an `END` sentinel, covering multiple markets, both currencies, and a range of outcomes (full gains, small gains, zeros, small losses, full losses).

**Sample inline data:**

```
20250320 USA500 01023 00700 -00500 USD
20250321 WDOFUT 11000 06000 +08000 BRL
20250324 FOMO11 02050 00875 +02050 USD
...
END
```

---

## Concepts Covered

This project demonstrates a progression through core COBOL and mainframe concepts:

**COBOL Language Features:**
- All four divisions (Identification, Environment, Data, Procedure)
- `SECTION` and paragraph-based program flow
- File I/O: `OPEN`, `READ ... AT END / NOT AT END`, `WRITE`, `CLOSE`
- File status checking with `FS-` variables
- `PERFORM UNTIL`, `PERFORM VARYING`, inline `PERFORM`
- `EVALUATE ... WHEN ... WHEN OTHER` (COBOL's equivalent of switch/case)
- `COMPUTE` with arithmetic expressions
- `STRING ... DELIMITED BY SIZE ... INTO ... ON OVERFLOW`
- Intrinsic functions: `MEAN`, `STANDARD-DEVIATION`, `MIN`, `MAX`
- Internal tables: `OCCURS`, `INDEXED BY`, `REDEFINES`
- Two-dimensional table lookup with nested `PERFORM VARYING`
- `88`-level condition names
- Edit masks and numeric formatting (`PIC ZZ999,99`, `PIC +999,99`)
- `ACCEPT ... FROM SYSIN` for interactive input
- `SIGN IS LEADING SEPARATE CHARACTER` for signed fields
- `SPECIAL-NAMES. DECIMAL-POINT IS COMMA` (Brazilian locale)
- `CBL ARITH(EXTEND)` compiler directive for extended arithmetic precision
- `77`-level standalone working-storage variables
- `GOBACK` for program termination

**JCL Concepts:**
- `JOB`, `EXEC`, and `DD` statements
- `IDCAMS` utility for dataset management (`DELETE ... PURGE`, `SET MAXCC=0`)
- Dataset allocation: `DISP=(NEW,CATLG,DELETE)`, `LRECL`, `SPACE`, `UNIT`
- Inline data with `DD *`
- `JOBLIB` for program library resolution
- `SYSOUT=*` for printed output
- `NOTIFY=&SYSUID` for job completion notification

**Mainframe File Concepts:**
- Fixed-length 80-byte records (`RECORDING MODE IS F`)
- Sequential file organization
- Copybooks for shared record layouts
- Block size optimization (`BLOCK CONTAINS 0 RECORDS`)

---

## Dataset Naming Convention

All datasets follow the pattern `DES.SYS.MZ.BGT1.<filename>`:

| Dataset | Description |
|---|---|
| `DES.SYS.MZ.BGT1.TRADE001` | Raw trade input records |
| `DES.SYS.MZ.BGT1.TRADS001` | Enriched trade output (from TRADING1) |
| `DES.SYS.MZ.BGT1.STATS001` | Statistics output (from TRADING2) |

---

## How to Run

1. Upload the `.cbl` source files to a PDS (e.g., `DES.TESTEB.LINKLIB`) and compile them.
2. Create the input dataset `DES.SYS.MZ.BGT1.TRADE001` with 80-byte fixed records matching the `TRADENT1` layout.
3. Submit the JCL jobs:
   - `TRADJOB1` → Produces `TRADS001` (enriched trades).
   - `TRADJOB2` → Produces `STATS001` (statistics).
   - `TRADJOB9` → Runs interactively with inline data, output goes to `SYSOUT`.
