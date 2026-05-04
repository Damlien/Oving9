# Oving 9 – Digital Electronics (ELPE1400)

Verilog implementation of sequential logic circuits for the Nandland Go Board (iCE40 FPGA).  
Built with [apio](https://github.com/FPGAwars/apio) and tested on hardware.

---

## Project Structure

```
Oving9/
├── lib_modules/          # Reusable modules used across multiple tasks
│   ├── D_vippe.v
│   ├── T_vippe.v
│   ├── debouncer.v
│   ├── pos_edge_detector.v
│   ├── neg_edge_detector.v
│   ├── any_edge_detector.v
│   ├── add_3.v
│   ├── c_add_3_alogrithm.v
│   ├── Repeated_sequentially_counter_1_6.v
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
├── D_100_16_Numbergenerator_counter_1_6.v
├── D_100_17_number_to_dice_decoder.v
├── Go_Board_Constraints.pcf
└── apio.ini
```

---

## Background: Key Concepts Used Throughout

These concepts appear in almost every task. Understanding them once here makes the per-task descriptions much easier to follow.

### Why debouncing is needed

When a physical button is pressed or released, the metal contacts inside do not make clean contact — they "bounce," producing many rapid on/off transitions over a few milliseconds before settling. Without correction, a single button press would be seen by the FPGA as dozens of presses.

The `debouncer` module fixes this by waiting until the button signal has held steady for a fixed number of clock cycles (default: 250,000 cycles, about 10 ms at 25 MHz) before accepting the new state. Only then does the output `debounce_state` change.

### Why edge detection is needed

The FPGA clock runs at 25 MHz — 25 million clock cycles per second. A button held down for even a tenth of a second is seen as high for 2,500,000 consecutive clock cycles. If the clock were directly driving a counter, a single press would increment the counter millions of times.

An edge detector solves this: it produces a pulse that is exactly **one clock cycle long** at the moment the button transitions from low to high (positive edge) or high to low (negative edge). This single-cycle pulse is then used as the clock for the state flip-flops, so one button press equals exactly one state change.

### How Karnaugh maps are used

A Karnaugh map (K-map) is a grid-based method to find the simplest possible Boolean expression for a logic function defined by a truth table. Instead of writing out a long sum of minterms, a K-map lets you group adjacent 1-cells and read off a shorter expression. All next-state logic and segment decoder logic in this project was derived using K-maps.

### Active-low seven-segment display

The seven-segment displays on the Go Board are **active-low**: a segment turns ON when its output pin is driven to 0, and turns OFF when driven to 1. This is why every segment expression in the code is wrapped in `~(...)`. The K-map gives the condition for when a segment should be on (output 1), and then the result is inverted to match the active-low hardware. This pattern appears in D-100.8 and every task that reuses the display decoder.

---

## Implemented Tasks

### D-100.6 – Edge Detectors

**Files:** `lib_modules/pos_edge_detector.v`, `lib_modules/neg_edge_detector.v`, `lib_modules/any_edge_detector.v`, `D_100_6_edge_detector_test.v`

**What the task asks for:** Design three circuits that detect a rising edge, a falling edge, and either edge on a button signal.

**How it is implemented:**

Each detector module contains a D flip-flop that captures the button's state on every rising clock edge, storing it as `button_pre_state`. By comparing the current button value to the stored previous value, the circuit can identify exactly when a transition occurred:

- `pos_edge_detector` — detects a rising edge: `output = button & ~prev`  
  (button is now 1, but was 0 last cycle)
- `neg_edge_detector` — detects a falling edge: `output = ~button & prev`  
  (button is now 0, but was 1 last cycle)
- `any_edge_detector` — detects either edge: `output = button ^ prev`  
  (XOR: output is 1 whenever the two differ)

Each output is high for exactly one clock cycle.

**Testing with T flip-flops:**

The top-level test (`D_100_6_edge_detector_test.v`) connects SW1, SW2, and SW3 through debouncers to one detector each. Since the detector output lasts only one clock cycle — far too short for the human eye — each detector drives a T flip-flop that **toggles an LED** on every detected edge. The LED now changes state and stays there, making each edge event permanently visible. SW1 tests the positive edge detector, SW2 tests the negative edge detector, and SW3 tests the any-edge detector.

---

### D-100.7 – SR Latch with Control Signal

**Files:** `D_100_7_a_SR_latch_with_ctrl.v`, `D_100_7_b_SR_latch_blinking.v`

**What the task asks for:** A two-input, two-output circuit where one output (A) is set to 1 when SW2 is pressed and reset to 0 when SW1 is pressed, and a second output (Ctrl) pulses high for one clock cycle whenever either button is pressed.

#### Part a — SR latch behavior using a D flip-flop

A classical SR latch uses NOR or NAND gates to hold a state. Here, the same behavior is implemented using a D flip-flop with next-state logic — a common and clean approach in synchronous Verilog design.

The key insight is deriving a next-state expression for `LED1`:

- If SW2 was just pressed (positive edge detected): set LED1 to 1, regardless of current state
- If SW1 was just pressed (positive edge detected): reset LED1 to 0, regardless of current state
- Otherwise: LED1 keeps its current value

This translates to:

```
LED1_next = pos_SW2 | (~pos_SW1 & LED1)
```

A D flip-flop clocked by the board's main clock captures `LED1_next` each cycle, holding the value between button presses. `LED1` is the output A from the assignment. `LED2` (the Ctrl output) is driven directly:

```
LED2 = pos_SW1 | pos_SW2
```

This is 1 for exactly one clock cycle whenever either button is pressed.

#### Part b — Blink speed controlled by latch state

Part b extends part a: a prescaler generates a slow and a fast blinking signal from the 25 MHz clock. LED3 selects between them depending on the current latch state (LED1):

```
LED3 = slow_blink & ~LED1 | fast_blink & LED1
```

- SW1 pressed → LED1 = 0 → LED3 blinks slowly (prescaler bit 24, ~0.75 Hz)
- SW2 pressed → LED1 = 1 → LED3 blinks fast (prescaler bit 22, ~3 Hz)

---

### D-100.8 – Seven-Segment Decoder (0–F)

**File:** `D_100_8_display_zero_to_F.v`

**What the task asks for:** A combinational circuit that takes a 4-bit binary input (SW1–SW4) representing a hexadecimal digit 0–F and drives a seven-segment display accordingly. The solution must be derived using Karnaugh maps.

**How it is implemented:**

SW1–SW4 are mapped to the logical inputs D3–D0 (SW1 = D3, SW4 = D0). For each of the seven segments (a–g), a K-map was drawn across all 16 input combinations (0000–1111). The minimized Boolean expression for each segment indicates when that segment should be lit.

Because the Go Board's seven-segment display is **active-low**, each expression is then inverted with `~(...)` so that a logic 1 from the K-map drives the output to 0, turning the segment on. Example:

```verilog
assign Segment1_A = ~( ~D0 & D1 | ~D0 & ~D2 | D1 & D2 | ... );
```

This module is the display foundation reused by D-100.9, D-100.10, D-100.11, D-100.12, and D-100.16. It is wrapped as `seven_segment_display_0_F` in `lib_modules/` so it can be instantiated by name in later tasks.

---

### D-100.9 – Down Counter 4→1

**File:** `D_100_9_counter_4_1.v`

**What the task asks for:** A sequential counter that steps through 4 → 3 → 2 → 1 → 4 … on each press of SW1, with the current value shown on the seven-segment display.

**How it is implemented:**

The count sequence is {4, 3, 2, 1}, which in binary is {100, 011, 010, 001}. Three bits are enough; D3 is hardwired to 0 since no value in the sequence reaches 8.

SW1 is debounced, and the debounced signal is passed through a positive edge detector. The resulting single-cycle pulse is used directly as the clock for three D flip-flops (D2, D1, D0), so the state advances exactly once per button press.

D2 is initialized to 1 so the counter starts at binary `100` = decimal 4.

The next-state logic for each bit was derived using K-maps over the four valid states:

```
D2_next = D0 & ~D1 & ~D2
D1_next = (D0 & D1 & ~D2) | (~D0 & ~D1 & D2)
D0_next = (~D0 & D1 & ~D2) | (~D0 & ~D1 & D2)
```

The state bits feed directly into `seven_segment_display_0_F` with D3 hardwired to 0.

---

### D-100.10 – Up/Down Counter 1↔4

**File:** `D_100_10_counter_up_down.v`

**What the task asks for:** A bidirectional counter over the sequence {1, 2, 3, 4, 1, …}. SW2 increments the count; SW1 decrements it. Current value shown on the display.

**How it is implemented:**

Both buttons are debounced independently and passed through positive edge detectors. The clock for all D flip-flops is `pos_SW1 | pos_SW2` — any button press advances the state machine by one step.

Direction is captured using a variable `X`:

```verilog
assign X = clean_SW2;
```

`clean_SW2` is the debounced SW2 signal. At the exact moment the edge-detector fires the flip-flop clock, `clean_SW2` reflects which button caused the press: if SW2 was pressed, `clean_SW2 = 1` so `X = 1` (count up); if SW1 was pressed, `clean_SW2 = 0` so `X = 0` (count down).

The next-state logic was derived using K-maps with `X` as an additional input variable (8 combinations per bit: 4 states × 2 directions):

```
D2_next = (D0 & D1 & ~D2 & X) | (D0 & ~D1 & ~D2 & ~X)
D1_next = (D0 & D1 & ~D2 & ~X) | (~D0 & ~D1 & D2 & ~X) | (D0 & ~D1 & ~D2 & X) | (~D0 & D1 & ~D2 & X)
D0_next = (~D0 & ~D1 & D2 & ~X) | (~D0 & ~D1 & D2 & X) | (~D0 & D1 & ~D2 & ~X) | (~D0 & D1 & ~D2 & X)
```

D2 initializes to 1 so the counter starts at binary `100` = decimal 4. Wait — actually D2 initializes to 1, meaning the first displayed value is 4. The display wraps correctly through the K-map.

Output feeds into `seven_segment_display_0_F` with D3 hardwired to 0.

---

### D-100.11 – Letter Up/Down Counter A↔F

**File:** `D_100_11_Letter_count_up_down.v`

**What the task asks for:** A bidirectional counter over the hexadecimal letter sequence {A, B, C, D, E, F}. SW2 counts up; SW1 counts down. Current letter shown on the display.

**How it is implemented:**

The structure is the same as D-100.10, with one key difference: the hexadecimal values A–F all have the most significant bit set (A = 1010, B = 1011, … F = 1111). D3 is therefore hardwired to 1, and only D2, D1, D0 need to change. The three D flip-flops are clocked by `pos_SW1 | pos_SW2`, and direction is again captured via `X = clean_SW2`.

D1 is initialized to 1 so the counter starts at D3:D2:D1:D0 = 1:0:1:0 = 0xA = the letter A.

Next-state logic derived from K-maps:

```
D2_next = (~D0 & D1 & D2) | (~D0 & D1 & X) | (D0 & D2 & X) | (~D1 & D2 & ~X) | (D0 & D1 & ~D2 & ~X)
D1_next = (~D0 & D1 & ~X) | (D0 & D1 & D2) | (D1 & ~D2 & X) | (D0 & D2 & ~X) | (~D0 & ~D1 & D2 & X)
D0_next = (~D0 & D1) | (~D0 & D2)
```

Output feeds into `seven_segment_display_0_F`. D3 is hardwired to 1, so the decoder always shows a hex letter (A–F).

---

### D-100.12 – Counter 0→99

**Files:** `D_100_12_counter_99.v`, `lib_modules/add_3.v`, `lib_modules/c_add_3_alogrithm.v`

**What the task asks for:** A counter that counts from 0 to 99 on each press of SW1 and shows the result as two decimal digits on the two seven-segment displays.

**How it is implemented:**

The top-level data path is:

```
SW1 → debouncer → pos_edge_detector → binary counter → BCD converter → two 7-segment decoders
```

**Binary counter:** The current count is stored in a 7-bit register (`counter`). 7 bits is enough because 99 = `7'b1100011`. On each button press (positive edge from the edge detector), the counter increments by 1. When it reaches 99 (`7'b1100011`), the next press wraps it back to 0.

```verilog
always @(posedge pos_edge_det_output_SW1) begin
    if (counter == 7'b1100011) counter <= 7'b0000000;
    else                       counter <= counter + 1;
end
```

**The BCD problem:** The two displays each need one separate decimal digit — the tens and the ones. For example, the value 45 is stored as a single binary number `0101101`, but the left display needs to show 4 (`0100`) and the right display needs to show 5 (`0101`). These are called BCD (Binary-Coded Decimal) digits: each decimal digit gets its own 4-bit group.

**C-add-3 algorithm:** This is a well-known hardware algorithm for converting binary to BCD. It works by shifting the binary number bit by bit from the MSB down, and before each shift, checking whether any BCD digit group has reached 5 or more. If it has, 3 is added to that group before the shift. This correction prevents the digit from overflowing past 9 after the shift. The algorithm produces the BCD digits group by group as bits are shifted in.

`add_3` is the correction block: it receives a 4-bit group and outputs the corrected 4-bit value (passes through values 0–4 unchanged, adds 3 to values 5–9).

`c_add_3_algorithm` chains seven `add_3` blocks (C1–C7) in the order needed to convert an 8-bit binary input to BCD. The module's output is 10 bits wide — enough for three decimal digits (hundreds, tens, ones) — but since the counter never exceeds 99, the top two bits (hundreds digit) are always 0 and are unused.

The result is split: `OUT[7:4]` is the tens digit → left display; `OUT[3:0]` is the ones digit → right display.

---

### D-100.16 – Repeating Number Generator 1→6

**Files:** `D_100_16_Numbergenerator_counter_1_6.v`, `lib_modules/Repeated_sequentially_counter_1_6.v`

**What the task asks for:** Build a number generator that repeatedly cycles through the sequence 1, 2, 3, 4, 5, 6. It should run while SW1 is held and stop when SW1 is released. This generator is a building block for the electronic dice (D-100.17 and D-100.18).

**How it is implemented:**

The state `D_now` is a 3-bit register that holds the current number (binary 001 through 110). Each clock cycle, if `clean_SW1 = 1` (button held), an internal 25-bit counter increments. When the counter reaches 12,000,000 — approximately 0.48 seconds at 25 MHz — `D_now` advances to the next value in the sequence and the counter resets to 0. When `clean_SW1 = 0`, neither the counter nor `D_now` changes, so the display freezes.

The sequence is encoded with a `case` statement:

```
001 → 010 → 011 → 100 → 101 → 110 → 001 (wraps)
```

This corresponds to decimal 1 through 6. A `default` case ensures the state recovers to 001 if an invalid state is ever reached.

**Standalone test vs. reusable module:**

`D_100_16_Numbergenerator_counter_1_6.v` is the full standalone test: it takes the physical `SW1` input, includes the debouncer, and connects the output directly to `seven_segment_display_0_F` so the generated numbers can be verified on the Go Board's display.

`lib_modules/Repeated_sequentially_counter_1_6.v` is the stripped-down reusable version. Its interface takes a `clean_button` (already debounced) and a `clk`, and outputs only `D_now[2:0]`. It contains no physical input handling and no display wiring. This module is imported by the D-100.17/D-100.18 top level.

---

### D-100.17 – Dice LED Decoder

**File:** `D_100_17_number_to_dice_decoder.v`

**What the task asks for:** Implement the decoder block from the dice system diagram. The decoder receives the 3-bit number from the generator and drives the seven LED positions on the physical dice PCB to display the correct dice face pattern.

**How it is implemented:**

A standard physical dice has seven LED positions arranged in a fixed grid. By overlaying all six faces, every possible dot position maps to one of seven LEDs (labeled L0–L6):

```
L0    L4
L1    L5
L2 L3 L6
```

A truth table was written for all six inputs (001–110), listing which LEDs are on for each dice face. Karnaugh maps over D2, D1, D0 were used to minimize each LED expression:

| Output | Expression | PMOD pin |
|--------|------------|----------|
| L0 (top left) | `D2` | PMOD1 |
| L1 (middle left) | `D1 & D2` | PMOD2 |
| L2 (bottom left) | `D1 \| D2` | PMOD3 |
| L3 (center) | `D0` | PMOD4 |
| L4 (top right) | `D1 \| D2` | PMOD7 |
| L5 (middle right) | `D1 & D2` | PMOD8 |
| L6 (bottom right) | `D2` | PMOD9 |

The symmetry in the expressions reflects the physical symmetry of a dice face: top-left mirrors top-right, middle-left mirrors middle-right, etc.

---

### D-100.18 – Complete Electronic Dice

**File:** `D_100_17_number_to_dice_decoder.v` (same top-level file as D-100.17)

**What the task asks for:** Assemble the complete dice system from D-100.16 (generator) and D-100.17 (decoder) and test that all six dice faces appear correctly on the physical LED PCB.

**How it is implemented:**

The top-level module `number_to_dice_decoder` wires the full chain:

```
SW1 → debouncer → Repeated_sequentially_counter_1_6 → dice decoder → PMOD pins
```

Holding SW1 down makes the generator cycle through dice values 1–6. Each value stays for ~0.48 seconds at 25 MHz before advancing. Releasing SW1 stops the generator, leaving the current dice face frozen on the external LED PCB.

The `Repeated_sequentially_counter_1_6` reusable module is used here — the top level handles debouncing of `SW1` and passes the cleaned signal as `clean_button`. The decoder equations are the seven `assign` statements from D-100.17.

The active top module for flashing is `number_to_dice_decoder`, set in `apio.ini`.

---

## Reusable Library Modules

| Module | File | Description |
|--------|------|-------------|
| `D_vippe` | `D_vippe.v` | D flip-flop with Q and Qn outputs, triggered on positive clock edge. Foundation for all sequential logic in this project. |
| `T_vippe` | `T_vippe.v` | T flip-flop built on top of `D_vippe`. Toggles its output each time the clock rises and T=1. Used to latch edge detection events into visible LED state. |
| `debouncer` | `debouncer.v` | Waits for the button signal to be stable for 250,000 consecutive clock cycles (~10 ms at 25 MHz) before updating its output. Eliminates mechanical contact bounce. |
| `pos_edge_detector` | `pos_edge_detector.v` | Produces a one-cycle pulse on a rising edge: `button & ~prev`. |
| `neg_edge_detector` | `neg_edge_detector.v` | Produces a one-cycle pulse on a falling edge: `~button & prev`. |
| `any_edge_detector` | `any_edge_detector.v` | Produces a one-cycle pulse on either edge: `button ^ prev`. |
| `add_3` | `add_3.v` | C-add-3 correction block. Receives a 4-bit BCD group; if the value is 5 or greater, adds 3 and returns the result; otherwise passes through unchanged. |
| `c_add_3_algorithm` | `c_add_3_alogrithm.v` | Converts an 8-bit binary value to BCD using seven chained `add_3` blocks. Output is 10 bits (up to three decimal digits); for values 0–99 only the lower 8 bits (tens and ones) are used. |
| `Repeated_sequentially_counter_1_6` | `Repeated_sequentially_counter_1_6.v` | Repeating 1-to-6 generator. Expects a pre-debounced button input. Steps through `001→010→011→100→101→110→001` at ~0.48 s per step. Used by the electronic dice. |
| `simple_prescaler` | `simple_prescaler.v` | Free-running 25-bit counter driven by the 25 MHz board clock. Exposes two bits as blink signals: bit 24 (~0.75 Hz, slow blink) and bit 22 (~3 Hz, fast blink). |
| `pulse_stretcher` | `pulse_stretcher.v` | Extends a short pulse to a configurable duration (default: ~0.5 s at 25 MHz). Useful for making single-cycle events visible on LEDs during testing. |
| `seven_segment_display_0_F` | `seven_segment_display_0_F.v` | Combinational 7-segment decoder for hex digits 0–F. Wraps the D-100.8 Boolean expressions as a reusable module with named D3–D0 inputs. All segment outputs are active-low. |

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
- **Outputs used:** LED1, LED2, LED3, Segment1, Segment2 (seven-segment displays), PMOD1, PMOD2, PMOD3, PMOD4, PMOD7, PMOD8, PMOD9
