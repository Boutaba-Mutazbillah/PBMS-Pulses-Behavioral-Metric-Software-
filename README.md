# PBMS-Pulses-Behavioral-Metric-Software-
PBMS is a dynamic x86 (32-bit) timing side-channel process that tracks CPU hardware execution behavior. By capturing a 28 clock cycles metric via RDTSC, it successfully exposes a definitive L1 Cache Hit.

A dynamic hardware-level security research tool designed to analyze and isolate CPU physical execution behavior via timing side-channel analysis on the x86 architecture.

---

## 1. Project Overview & Objective

**PBMS (Pulses Behavioral Metric Software)** is an advanced, non-invasive hardware-level security experiment developed to demonstrate a dynamic **Timing Side-Channel Attack** running on the **x86 (32-bit)** architecture. 

The primary objective of this project is to prove that internal CPU physical storage states (such as cache layers) can be reverse-engineered and mapped solely by counting execution ticks at a single-digit clock cycle resolution, without inducing any software-level breach or OS-level modifications.

---

## 2. Understanding the Attack Vector: Timing Side-Channels

The fundamental mechanism of this attack does not rely on traditional software vulnerabilities or logical code bugs within the operating system. Instead, it directly exploits the **physical propagation delay and architecture latency constraints** inherent to modern computing hardware. 

The processor interacts with distinct tiers of memory subsystems to fetch, store, and execute data:

### Memory Subsystems Delay Metrics:
* **Internal CPU Cache Memory:** An ultra-fast, on-die storage system (divided into L1, L2, and L3 tiers). Hardware operations within these lines execute nearly instantly, requiring only a minimal number of clock cycles (typically below 50 cycles for L1).
* **Main Random Access Memory (RAM):** An external memory module situated on the motherboard. Due to physical bus limitations and hardware routing, requests pulling from RAM induce an execution penalty requiring hundreds of clock cycles.

**PBMS** leverages this specific variance by reading the hardware's internal timestamp counter before and after an un-cached or cached volatile memory transaction. By calculating the clock tick delta, the software successfully classifies the exact physical layer where the target data resides.

---

## 3. Structural Analysis of the Injected Assembly Code

The lightweight assembly script, compiled using **NASM 3.02** and executed dynamically within memory space at address `00401000`, operates through the following exact low-level pipeline phases:

### Phase 1: The Padding and Alignment Stage
Four continuous `NOP` (No Operation) padding instructions are positioned at the entry point of the executable. In x86 architecture, a single `NOP` consumes exactly **1 byte** of memory space. This padding enforces strict pipeline alignment within the instruction decoder block, ensuring subsequent core cycles are fetched cleanly without cache misalignment penalties.

### Phase 2: Dynamic Memory Target Allocation
The instruction `MOV ECX, ESP` actively duplicates the current stack pointer memory address into the general-purpose register `ECX`. The Stack space is an inherently volatile memory region managed directly by the hardware and is typically pre-cached inside the fastest processor boundary layer (**L1 Data Cache**) to optimize active routines.

### Phase 3: Initial Cycle Stamping
The execution engine calls the `RDTSC` (Read Time-Stamp Counter) instruction. This reads the internal 64-bit cycle counter register. The primary lower-half bits of this hardware counter are instantly pushed to the `EAX` register and then safely preserved inside the `ESI` register via `MOV ESI, EAX`.

### Phase 4: Target Write Operation & Final Stamping
The instruction `MOV dword ptr [ECX], EAX` triggers the execution of a 4-byte memory write transaction to the exact destination point mapped inside the stack array. Immediately following the hardware write cycle, a secondary `RDTSC` instruction is fired to instantly capture the newly updated hardware time stamp count.

### Phase 5: Net Metric Delta Extraction
The instruction `SUB EAX, ESI` computes the net arithmetic difference by subtracting the boot time counter stored in `ESI` from the final counter recorded in `EAX`. This absolute hardware latency delta is subsequently committed to the general-purpose register `EBX` via `MOV EBX, EAX` for immediate structural analysis.

---

## 4. Physical Interpretation and Analysis of the Captured Metric

During runtime debugging within the `x32dbg` environment, freezing the execution thread directly via a hardware Breakpoint at the final calculation instruction at address `00401010` exposes the following precise physical characteristics in the register layout panel:

* **Captured Output Value:** **`28` Clock Cycles**.

### Technical Diagnosis of the Delta:
This exceptionally low execution window (exactly **28 clock cycles**) provides undeniable empirical evidence of a definitive **Cache Hit** event. The processor performed the memory modification locally within the high-speed boundaries of the internal **L1 Data Cache** mapped by the `ESP` stack register. 

Had the targeted storage reference been purged or un-cached, forcing the execution unit to route commands outward to the system board RAM, the clock counter would have experienced a sharp latency penalty, spiking instantly to a range of **200 to 300+ clock cycles**. The program successfully resolved and isolated the physical operational state of the storage hardware at a single-digit cycle precision tier.

---

## 5. Software Challenges in Modern Production Environments

While the attack vector executes flawlessly inside an isolated debugger boundary, production deployment introduces architectural complexities:

1. **Out-of-Order Execution Optimization:** Modern performance-optimized CPUs execute instruction trees speculatively. In raw environments, the hardware decoder can shuffle `RDTSC` sequence blocks. To maintain absolute deterministic boundaries in specialized security research, serialization barriers like fence instructions (`LFENCE`) are required.
2. **Hardware Pre-fetch Systems:** Internal CPU logic automatically maps data access profiles and pre-loads values into cache layers. To expose raw main memory latency deltas, researchers deploy explicit instructions such as `CLFLUSH` (Cache Line Flush) to manually invalidate targeted cache rows and force a hard physical RAM draw.

---

## 6. Experimental Visual Walkthrough & Screenshots

Below is the step-by-step visual documentation mapping the real-time physical execution profile extracted during the debugging process.

### Step 1: Writing the Assembly Source Code
![Step 1](<img width="1680" height="1050" alt="1" src="https://github.com/user-attachments/assets/12c26224-82aa-429a-bfaf-21413f9db14c" />
)
*Writing the initial assembly logic.*

### Step 2: Navigating Project Workspace Directory
![Step 2](<img width="1680" height="1020" alt="2" src="https://github.com/user-attachments/assets/49d2fc99-e41e-4d8a-bb8d-73f69f93a6fa" />
)
*Locating the source files.*

### Step 3: Verification of Object Binary Compilation
![Step 3](<img width="1680" height="1020" alt="3" src="https://github.com/user-attachments/assets/ece20239-3c43-43bc-90fc-c26f3ea2a2f2" />
)
*Compiling using NASM tool.*

### Step 4: Linking Object to Standalone Executable
![Step 4](<img width="1680" height="1020" alt="4" src="https://github.com/user-attachments/assets/31b0a216-048b-442d-a08d-239a4fce63fe" />
)
*Generating executable using GCC tool.*

### Step 5: Loading Binary inside x32dbg Debugger
![Step 5](<img width="1680" height="1020" alt="4" src="https://github.com/user-attachments/assets/c951328b-5365-4add-afc1-da4a2f5535db" />
)
*Opening the program for analysis.*

### Step 6: Analyzing Thread Entry Breakpoint State
![Step 6](<img width="1680" height="1020" alt="6" src="https://github.com/user-attachments/assets/9954c027-1935-458a-85cf-57ad779e2e3d" />
)
*Debugger loading standard library modules.*

### Step 7: Checking Preliminary Processor Register Matrix
![Step 7](<img width="1680" height="1020" alt="7" src="https://github.com/user-attachments/assets/beec6731-8830-4519-9b98-ab838218b36f" />
)
*Inspecting registers layout before modification.*

### Step 8: Verifying Thread Call Stack Boundaries
![Step 8](<img width="1680" height="1020" alt="8" src="https://github.com/user-attachments/assets/bd67fbfc-9b44-4515-98b6-961771629225" />
)
*Monitoring memory stack framework initialization.*

### Step 9: Mapping Binary Export Symbols Table
![Step 9](<img width="1680" height="892" alt="9" src="https://github.com/user-attachments/assets/c9abee98-dd83-4d0b-becc-1b09cccd6f16" />
)
*Extracting module execution entry addresses.*

### Step 10: Identifying Application Entry Point Address
![Step 10](<img width="1680" height="892" alt="10" src="https://github.com/user-attachments/assets/05517bf3-2c18-4160-8413-e458449e8e48" />
)
*Pinpointing core program target code.*

### Step 11: Jumping to Assembly Injected Code
![Step 11](<img width="1680" height="1020" alt="11" src="https://github.com/user-attachments/assets/4ecf4a3b-ab71-4875-a7b2-7791bd81253d" />
)
*Navigating to base memory instruction.*

### Step 12: Locating Injected Instructions in Memory
![Step 12](<img width="1680" height="1020" alt="12" src="https://github.com/user-attachments/assets/267cae69-197b-4b0d-af7c-cebac3d06e26" />
)
*Inspecting raw code layout.*

### Step 13: Deploying Hardware Breakpoint on Code
![Step 13](<img width="1680" height="1020" alt="13" src="https://github.com/user-attachments/assets/e7725ecd-aef4-45f2-a7a2-072fb33d5aa9" />
)
*Setting breakpoint at sub instruction.*

### Step 14: Running Payload and Freezing Execution
![Step 14](<img width="1680" height="1020" alt="14" src="https://github.com/user-attachments/assets/128fb514-2178-4b3e-8880-928170c69e16" />
)
*Executing code until breakpoint triggers.*

### Step 15: Evaluating Clock Ticks via EAX
![Step 15](<img width="1680" height="1020" alt="15" src="https://github.com/user-attachments/assets/75ce6280-e183-486e-b1a3-59f120a362d7" />
)
*Opening register modification hex window.*

### Step 16: Verifying L1 Cache Hit Metric
![Step 16](<img width="1680" height="1020" alt="16" src="https://github.com/user-attachments/assets/06bde459-3d7a-4e82-99c7-e14e7e4b6405" />
)
)
*Confirming precise 28 cycles result.*
