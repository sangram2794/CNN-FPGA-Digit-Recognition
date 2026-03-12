# FPGA CNN Digit Recognition — DE2-115

A hardware implementation of a Convolutional Neural Network (CNN) for handwritten digit recognition, built on the Intel DE2-115 FPGA board. The system takes a pre-processed MNIST image stored in memory and displays the predicted digit (0–9) on the 7-segment display.

---

## Project Overview

```
Image (.mem file)
      ↓
 Conv Layer        ← 3×3 filter slides across 28×28 image → 676 outputs
      ↓
  FC Layer         ← 676 inputs × 10 neurons → 10 scores
      ↓
  Argmax           ← picks highest score
      ↓
 HEX0 Display      ← shows predicted digit
```

---

## Hardware

- **Board:** Intel DE2-115 (Cyclone IV E — EP4CE115F29C7)
- **Tool:** Intel Quartus Prime 22.1 Standard Edition
- **Language:** Verilog HDL

---

## Repository Structure

```
project/
├── mac_unit.v            # Multiply-accumulate unit (core math)
├── bram_rom.v            # Block RAM — loads .mem files, serves data by address
├── conv_controller.v     # FSM that slides 3×3 kernel across 28×28 image
├── conv_buffer.v         # Stores all 676 conv outputs for FC layer to read
├── fc_controller.v       # FSM that runs 10 FC neurons × 676 inputs each
├── argmax.v              # Stores 10 neuron scores, picks the highest
├── seg7_decoder.v        # Converts digit 0–9 to 7-segment display signal
├── top_cnn.v             # Top-level: connects all modules, maps to board I/O
│
├── conv_weights.mem      # 9 trained conv filter weights (3×3)
├── fc_weights.mem        # 6760 trained FC weights (676 × 10)
├── image_1_label_7.mem   # Test image — digit 7
├── image_2_label_4.mem   # Test image — digit 4
├── image_3_label_1.mem   # Test image — digit 1
└── image_4_label_0.mem   # Test image — digit 0
```

---

## Module Descriptions

| Module | Purpose |
|--------|---------|
| `mac_unit.v` | Multiplies two 8-bit numbers and accumulates the result — the core math unit used by both conv and FC layers |
| `bram_rom.v` | Loads a `.mem` file into on-chip memory at synthesis time and outputs data by address — used for images and weights |
| `conv_controller.v` | State machine that slides a 3×3 window across the full 28×28 image, controlling addressing and MAC enable for each of 676 output positions |
| `conv_buffer.v` | 676-entry register array that stores all conv layer outputs so the FC layer can read them after conv finishes |
| `fc_controller.v` | State machine that steps through all 676 inputs for each of the 10 output neurons, computing absolute weight addresses via addition |
| `argmax.v` | Captures each neuron's final score as it finishes, then on `fc_done` picks the index of the highest score as the predicted digit |
| `seg7_decoder.v` | Combinational decoder that maps digit 0–9 to the active-low 7-segment encoding for the DE2-115 display |
| `top_cnn.v` | Top-level module that instantiates and connects all sub-modules, and assigns signals to board pins |

---

## Architecture Details

### Why 676?

The conv layer uses a 3×3 filter with no padding on a 28×28 image:

```
Valid output rows = 28 - 3 + 1 = 26
Valid output cols = 28 - 3 + 1 = 26
Total outputs    = 26 × 26    = 676
```

### Memory Files

| File | Entries | Description |
|------|---------|-------------|
| `conv_weights.mem` | 9 | One 3×3 conv filter, trained on MNIST |
| `fc_weights.mem` | 6760 | FC weights: 10 neurons × 676 inputs each, stored flat |
| `image_X_label_Y.mem` | 784 | 28×28 pixel image, one byte per pixel |

The FC weight file is laid out as:
```
entries    0 –  675  →  neuron 0 (score for digit 0)
entries  676 – 1351  →  neuron 1 (score for digit 1)
...
entries 6084 – 6759  →  neuron 9 (score for digit 9)
```

### Convolution Window Example

For output position (row=0, col=0):
```
tap 0 → image[0]  × weight[0]
tap 1 → image[1]  × weight[1]
tap 2 → image[2]  × weight[2]
tap 3 → image[28] × weight[3]
tap 4 → image[29] × weight[4]
tap 5 → image[30] × weight[5]
tap 6 → image[56] × weight[6]
tap 7 → image[57] × weight[7]
tap 8 → image[58] × weight[8]
         ↓
    accumulate → one output value → conv_buffer[0]
```

---

## Pin Assignments (DE2-115)

| Signal | Pin | Description |
|--------|-----|-------------|
| `CLOCK_50` | PIN_Y2 | 50 MHz system clock |
| `KEY[0]` | PIN_M23 | Reset (active low) |
| `KEY[1]` | PIN_M21 | Start inference (active low) |
| `HEX0[6:0]` | See QSF | Predicted digit display |
| `LEDG0` | PIN_E21 | Lights when inference is complete |
| `LEDR[3:0]` | See QSF | Binary value of predicted digit |

Full pin assignments are in `top_cnn.qsf`.

---

## How to Use

### 1. Setup
- Place all `.v` files and `.mem` files in the same Quartus project folder
- The `.mem` files do **not** need to be added to the Quartus project — `$readmemh` finds them automatically

### 2. Select an Image
In `top_cnn.v`, change this line to select which image to test:
```verilog
bram_rom #(..., .INIT_FILE("image_1_label_7.mem")) image_mem (...);
```

### 3. Compile
```
Quartus → Processing → Start Compilation
```

### 4. Flash to Board
```
Quartus → Tools → Programmer → Add File → output_files/top_cnn.sof → Start
```

### 5. Run
```
1. Press KEY[0]  →  reset the system
2. Press KEY[1]  →  start inference
3. Wait ~2 sec   →  LEDG0 lights up when done
4. Read HEX0     →  predicted digit
```

### 6. Expected Results

| Image file | Expected output |
|------------|----------------|
| `image_1_label_7.mem` | **7** |
| `image_2_label_4.mem` | **4** |
| `image_3_label_1.mem` | **1** |
| `image_4_label_0.mem` | **0** |

---

## Pipeline Timing

```
KEY[1] pressed
      ↓
Conv stage:  676 windows × 9 taps × 2 cycles = ~12,168 cycles  (~0.24 ms)
      ↓
FC stage:    10 neurons × 676 inputs × 2 cycles = ~13,520 cycles (~0.27 ms)
      ↓
Argmax:      1 cycle
      ↓
LEDG0 lights, HEX0 shows digit
Total: < 1 ms at 50 MHz
```

---

## Authors

- Developed as part of a digital design / embedded systems project
- CNN trained on the MNIST handwritten digit dataset
- Target device: Intel Cyclone IV E (DE2-115 development board)
