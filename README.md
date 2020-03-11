# Welcome to the home of ORCA MPSoC project!

This repository holds the project for the hardware of ORCA MPSoC platform. This repository is part of Project ORCA, whose repositories include 

- [URSA](https://github.com/andersondomingues/ursa), a library and API for creating system-level simulators
- [ORCA-MPSoC](https://github.com/andersondomingues/orca-mpsoc): RTL and simulation files for a NoC-based MPSoC system
- [ORCA-SIM](https://github.com/andersondomingues/orca-sim), a simulation tool on top of URSA that emulates the ORCA MPSoC
- [ORCA-SOFTWARE-ASSETS](https://github.com/andersondomingues/orca-software-assets), applications and libraries to support software development

Other repositories include:

- (HellfireOS)[https://github.com/andersondomingues/hellfireos], an real-time operating system that runs on ORCA MPSoC.

## The ORCA Platform

![Top-level architecture of ORCA platform](https://raw.githubusercontent.com/andersondomingues/orca-mpsoc/master/docs/orca-mpsoc.png)

## Repository organization

This repository is organized as follows.

- `docs`: Folder containing general information about the platform, tutorials and similar documentaions.
- `models`: Folder containing hardware models to use with RTL tools. These models either are described in VHDL language (to use with Mentor's Questa software) or C++ (to use with URSA). However, these models can be adapted to use with other tools with minimal effort.
- `sim`: Simulation scripts for URSA and Quest tools. Additional tools will be added as the project grows.
   
## Third-Party Work

- HF-RISCV. The hf-riscv core is maintained by Sergio Johann (sjohann81). See [his repository](https://github.com/sjohann81). The version of HellfireOS that we use in the project is a fork from Johann's HellfireOS, which can be found [here](https://github.com/sjohann81/hellfireos)

- HEMPS (and HERMES). The GAPH group maintains the HEMPS project. More information on their work can be found at [their website](http://www.inf.pucrs.br/hemps/getting_started.html). Provided network-on-chip router model is based on the RTL models available at [their repository](https://github.com/GaphGroup/hemps). 

## Licensing

See ``LICENSE.MD`` for details. 

## Contact

For now, I ([andersondomingues](https://github.com/andersondomingues)) am the only contributor to this project. Feel free to [mail me](mailto:ti.andersondomingues@gmail.com).

NOTICE: This repository is under construction, so expect missing references and documentation. May an asset be urgent to your cause, please feel free to contact me.
