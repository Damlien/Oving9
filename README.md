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
│   ├── simple_prescaler.v
│   └── pulse_stretcher.v
├── testbenching/         # Testbenches and GTKWave files
├── D_100_6_edge_detector_test.v
├── D_100_7_a_SR_latch_with_ctrl.v
├── D_100_7_b_SR_latch_blinking.v
├── D_100_8_display_zero_to_F.v
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

## Reusable Library Modules

| Module | Description |
|---|---|
| `D_vippe` | D flip-flop with Q and Qn outputs, positive clock edge |
| `T_vippe` | T flip-flop built from D_vippe, toggles on clock edge when T=1 |
| `debouncer` | Button debouncer with configurable threshold (default: 250,000 cycles) |
| `pos_edge_detector` | Detects rising edge of a signal |
| `neg_edge_detector` | Detects falling edge of a signal |
| `any_edge_detector` | Detects either edge of a signal |
| `simple_prescaler` | Generates slow (~0.5 Hz) and fast (~3 Hz) blink signals from 12 MHz clock |
| `pulse_stretcher` | Extends a short pulse to a configurable duration (default: ~1 second) |

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
- **Outputs used:** LED1, LED2, LED3, Segment1 (7-segment display)
