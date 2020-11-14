# ORCA MPSOC

ORCA MPSOC is a many core platform based on the 32-bit Risc-V architecture. It used HF-RiscV processor cores to provide computing power, distributed over a mesh-topology network-on-chip based on the Hermes NoC. This repository holds the project for the hardware of ORCA MPSoC platform, including their RTL models and simulation scripts for Vivado and Quest (ModelSim) tools. Related repositories are enlisted below.

- ORCA-SIM (https://github.com/andersondomingues/orca-sim), a simulation tool on top of URSA that emulates the ORCA MPSoC
- ORCA-SOFTWARE-ASSETS (https://github.com/andersondomingues/orca-software-assets), applications and libraries to support software development

![Top-level architecture of ORCA platform](https://raw.githubusercontent.com/andersondomingues/orca-mpsoc/master/docs/orca-mpsoc.png)

## Repository organization

This repository is organized as follows.

- `docs`: Folder containing general information about the platform, tutorials and similar documentations.
- `models`: Folder containing hardware models to use with RTL tools. These models either are described in VHDL language (to use with Mentor's Questa software) or C++ (to use with URSA). However, these models can be adapted to use with other tools with minimal effort.
- `sim`: Simulation scripts for URSA and Quest tools. Additional tools will be added as the project grows.

## Project Documentation

There are two main design in this repository. A single processing tile
and the MPSoC, i.e. an array of 2x2 processing tiles. Both design 
connected to the Zynq's ARM processor. Their documentation is available 
in the following links:

 - [Processing Tile](./docs/processing-tile.md)
 - [2x2 MPSoC](./docs/mpsoc-2x2.md)


## Project Roadmap

Things that we currently working on:

- Testbenchs for each of the memory modules
- Simulation scripts for Vivado and Questa tools assuming for a couple of scenarios 
- Prototyping the project to a FPGA 
  
## Third-Party Work

- HF-RISCV. The hf-riscv core is maintained by Sergio Johann (sjohann81). See [his repository](https://github.com/sjohann81). The version of HellfireOS that we use in the project is a fork from Johann's HellfireOS, which can be found [here](https://github.com/sjohann81/hellfireos)

- HEMPS (and HERMES). The GAPH group maintains the HEMPS project. More information on their work can be found at [their website](http://www.inf.pucrs.br/hemps/getting_started.html). Provided network-on-chip router model is based on the RTL models available at [their repository](https://github.com/GaphGroup/hemps). 
   
## Licensing

This is free software (and hardware)! See ``LICENSE.MD`` for details. 

## Contact

Feel free to contact me ([andersondomingues](https://github.com/andersondomingues)), the maintainer of this project: mailto:ti.andersondomingues@gmail.com.

## Third-Party Work and Acknowledgement

- HF-RISCV. The hf-riscv core is maintained by Sergio Johann (sjohann81). More information on his work can be found at [his repository](https://github.com/sjohann81). I would like to thank Mr. Johann for the time spent explaining me the depths of the HF-RiscV architecture.

- HERMES. The GAPH group maintains the HERMES network-on-chip. More information on their work can be found at [their website](http://www.inf.pucrs.br/hemps/getting_started.html). Provided network-on-chip router model is based on the RTL models available at [their repository](https://github.com/GaphGroup/hemps). I would like to thank the GAPH group for giving me so many insights on Hermes' architecture. 

- I would to thank Mr. Guilherme Heck (https://github.com/heckgui) for his active participation in the prototying of the platform.

- I would to thank Mr. Alexandre Amory (https://github.com/amamory) for the advising during the prototying process, for providing the FPGA boards, and other resources. 
