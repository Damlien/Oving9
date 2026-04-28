# Øving 9 – Digital Electronics (ELPE1400)

Verilog implementation of sequential logic circuits for the Nandland Go Board (iCE40 FPGA).  
Built with [apio](https://github.com/FPGAwars/apio) and tested on hardware.

---

## Project Structure

```
Oving9/
├── lib_modules/          # Reusable modules
│   ├── D_vippe.v
│   ├── T_vippe.v
│   ├── debouncer.v
│   ├── pos_edge_detector.v
│   ├── neg_edge_detector.v
│   ├── any_edge_detector.v
│   ├── add_3.v
│   ├── c_add_3_alogrithm.v
│   ├── simple_prescaler.v
│   ├── pulse_stretcher.v
│   └── seven_segment_display_0_F.v
├── testbenching/         # Testbenches and GTKWave files
├── D_100_6_edge_detector_test.v
├── D_100_7_a_SR_latch_with_ctrl.v
├── D_100_7_b_SR_latch_blinking.v
├── D_100_8_display_zero_to_F.v
├── D_100_9_counter_4_1.v
├── D_100_10_counter_up_down.v
├── D_100_11_Letter_count_up_down.v
├── D_100_12_counter_99.v
├── Go_Board_Constraints.pcf
└── apio.ini
```

---

## Implemented Tasks

### D-100.6 – Edge Detectors

**Files:** `lib_modules/pos_edge_detector.v`, `neg_edge_detector.v`, `any_edge_detector.v`, `D_100_6_edge_detector_test.v`

Three edge detector modules, each built around a D flip-flop that stores the previous button state:

- `pos_edge_detector` – detects a rising edge: `output = button & ~prev`
- `neg_edge_detector` – detects a falling edge: `output = ~button & prev`
- `any_edge_detector` – detects either edge: `output = button ^ prev`

The top-level test (`D_100_6_edge_detector_test.v`) connects SW1, SW2, and SW3 through debouncers to one detector each. Each detector drives a T flip-flop, toggling an LED on every detected edge. This makes edge events visible despite their single-clock-cycle duration.

---

### D-100.7 – SR Latch with Control Signal

**Files:** `D_100_7_a_SR_latch_with_ctrl.v`, `D_100_7_b_SR_latch_blinking.v`

**Part a** (`SR_latch_with_ctrl`): Two-input, two-output circuit using SW1 and SW2.

- LED1 (output A): set to 1 on positive edge of SW2, reset to 0 on positive edge of SW1. Implemented as a D flip-flop with next-state logic: `LED1_next = pos_SW2 | (~pos_SW1 & LED1)`
- LED2 (Ctrl): goes high for one clock cycle whenever either button is pressed: `LED2 = pos_SW1 | pos_SW2`

**Part b** (`SR_latch_blinking`): Extends part a with a prescaler driving LED3.

- SW1 pressed (LED1 = 0): LED3 blinks slowly (prescaler bit 24, ~0.5 Hz at 12 MHz)
- SW2 pressed (LED1 = 1): LED3 blinks fast (prescaler bit 22, ~3 Hz)

---

### D-100.8 – Seven-Segment Decoder (0–F)

**File:** `D_100_8_display_zero_to_F.v`

Combinational decoder displaying hexadecimal digits 0–F on a 7-segment display.  
4-bit input from SW1–SW4 (D3–D0). Each segment output is a minimized Boolean expression derived from Karnaugh maps covering all 16 input combinations.

---

### D-100.9 – Down Counter 4→1

**File:** `D_100_9_counter_4_1.v`

Sequential counter that cycles through 4 → 3 → 2 → 1 → 4 … on each press of SW1. The current value is shown on the 7-segment display.

- SW1 is debounced and a positive edge detector converts each button press into a single-cycle clock pulse for the flip-flops.
- State is held in three D flip-flops (D2, D1, D0). D3 is hardwired to 0 since the count range fits in 3 bits (binary 001–100).
- D2 initializes to 1 so the counter starts at 4 (binary `100`).
- Next-state logic (derived from Karnaugh maps):
  - `D2_next = D0 & ~D1 & ~D2`
  - `D1_next = (D0 & D1 & ~D2) | (~D0 & ~D1 & D2)`
  - `D0_next = (~D0 & D1 & ~D2) | (~D0 & ~D1 & D2)`
- Output fed directly into `seven_segment_display_0_F` (reused from D-100.8).

---

### D-100.10 – Up/Down Counter 1↔4

**File:** `D_100_10_counter_up_down.v`

Bidirectional counter over the sequence {1, 2, 3, 4, 1, …}. SW2 counts up; SW1 counts down. The current value is shown on the 7-segment display.

- Both buttons are independently debounced and passed through positive edge detectors.
- The clock for all D flip-flops is `pos_SW1 | pos_SW2`, so any button press advances the state.
- Direction is controlled by `X = clean_SW2` (held high while SW2 is pressed when the edge fires).
- Next-state logic (derived from Karnaugh maps for count-up when X=1, count-down when X=0):
  - `D2_next = (D0 & D1 & ~D2 & X) | (D0 & ~D1 & ~D2 & ~X)`
  - `D1_next = (D0 & D1 & ~D2 & ~X) | (~D0 & ~D1 & D2 & ~X) | (D0 & ~D1 & ~D2 & X) | (~D0 & D1 & ~D2 & X)`
  - `D0_next = (~D0 & ~D1 & D2 & ~X) | (~D0 & ~D1 & D2 & X) | (~D0 & D1 & ~D2 & ~X) | (~D0 & D1 & ~D2 & X)`
- Output fed directly into `seven_segment_display_0_F`.

---

### D-100.11 – Letter Up/Down Counter A↔F

**File:** `D_100_11_Letter_count_up_down.v`

Bidirectional counter over the hexadecimal letter sequence {A, B, C, D, E, F}. SW2 counts up; SW1 counts down. The current letter is shown on the 7-segment display.

- Both SW1 and SW2 are debounced and passed through positive edge detectors.
- The clock for all D flip-flops is `pos_SW1 | pos_SW2`, so a press on either button advances the counter by one step.
- Direction is controlled by `X = clean_SW2`. When SW2 is pressed, `X=1` and the counter follows the count-up path. When SW1 is pressed, `X=0` and the counter follows the count-down path.
- D3 is hardwired to 1 because hexadecimal A–F all have the most significant bit set.
- State is held in three D flip-flops (D2, D1, D0), representing the lower three bits of the displayed hex value.
- D1 initializes to 1, so the counter starts at A (`1010`).
- Next-state logic:
  - `D2_next = (~D0 & D1 & D2) | (~D0 & D1 & X) | (D0 & D2 & X) | (~D1 & D2 & ~X) | (D0 & D1 & ~D2 & ~X)`
  - `D1_next = (~D0 & D1 & ~X) | (D0 & D1 & D2) | (D1 & ~D2 & X) | (D0 & D2 & ~X) | (~D0 & ~D1 & D2 & X)`
  - `D0_next = (~D0 & D1) | (~D0 & D2)`
- Output is fed directly into `seven_segment_display_0_F`, reusing the hexadecimal display decoder from D-100.8.

---

### D-100.12 – Counter 0→99

**Files:** `D_100_12_counter_99.v`, `lib_modules/add_3.v`, `lib_modules/c_add_3_alogrithm.v`

Sequential counter that counts from 0 to 99 on each press of SW1. The value is shown as two decimal digits using both 7-segment displays.

- SW1 is debounced and passed through a positive edge detector, so each button press advances the counter once.
- The count is stored as a 7-bit binary register, which is enough for values 0–99 (`99 = 7'b1100011`).
- When the counter reaches 99, the next button press wraps it back to 0. Otherwise, the counter increments by 1.
- The counter value is stored as ordinary binary, but the two displays need separate decimal digits. For example, decimal 45 is `0101101` as one binary number, but the displays need `0100` for 4 and `0101` for 5.
- BCD solves this by storing each decimal digit in its own 4-bit group. The converter therefore has to turn one binary number into two BCD groups: one for the 1s digit and one for the 10s digit.
- `c_add_3_algorithm` is a combinational binary-to-BCD converter. It does not store or count; whenever the binary input changes, the BCD output changes from the wiring through the converter.
- The converter is based on shifting the binary bits into the future BCD digit groups. A left shift is the same as multiplying by 2, so the partial BCD groups must stay valid after each shift.
- `add_3` is the correction block used before a shift. If a 4-bit group is 5 or greater, the next left shift would make that digit become 10 or greater, which cannot fit inside one BCD digit. Adding 3 before the shift makes the carry move into the next BCD group instead.
- The seven `add_3` instances in `c_add_3_algorithm` are a fixed, unrolled version of this shift-and-correct process for an 8-bit input. The counter only needs 7 bits for 0–99, so it is connected with a leading zero.
- The converter output is split into two BCD digits: `OUT[3:0]` is the 1s digit and goes to the right 7-segment display, while `OUT[7:4]` is the 10s digit and goes to the left 7-segment display.

---

## Reusable Library Modules

| Module | Description |
|---|---|
| `D_vippe` | D flip-flop with Q and Qn outputs, positive clock edge |
| `T_vippe` | T flip-flop built from D_vippe, toggles on clock edge when T=1 |
| `debouncer` | Button debouncer with configurable threshold (default: 250,000 cycles) |
| `pos_edge_detector` | Detects rising edge of a signal |
| `neg_edge_detector` | Detects falling edge of a signal |
| `any_edge_detector` | Detects either edge of a signal |
| `add_3` | C-add-3 correction block for a 4-bit group |
| `c_add_3_algorithm` | Converts an 8-bit binary value to BCD using seven `add_3` blocks |
| `simple_prescaler` | Generates slow (~0.5 Hz) and fast (~3 Hz) blink signals from 12 MHz clock |
| `pulse_stretcher` | Extends a short pulse to a configurable duration (default: ~1 second) |
| `seven_segment_display_0_F` | Combinational 7-segment decoder for hex digits 0–F (reusable wrapper around D-100.8 logic) |

---

## Build & Flash

Requires [apio](https://github.com/FPGAwars/apio) with the iCE40 toolchain.

```bash
apio build    # Synthesize and place-and-route
apio upload   # Flash to Go Board
apio sim      # Run simulation (requires testbench)
```

---

## Hardware

- **Board:** Nandland Go Board (Lattice iCE40 HX1K)
- **Clock:** 25 MHz onboard oscillator
- **Inputs used:** SW1, SW2, SW3, SW4
- **Outputs used:** LED1, LED2, LED3, Segment1, Segment2 (7-segment displays)
