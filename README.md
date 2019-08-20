# Welcome to the home of ORCA MPSoC project!

This repository holds the project for the hardware of ORCA MPSoC platform. The software counterpart of this repository can be found at [https://github.com/andersondomingues/ursa].

## The ORCA Platform

![Top-level architecture of ORCA platform](https://raw.githubusercontent.com/andersondomingues/orca-mpsoc/master/docs/orca-mpsoc.png)

## Repository organization

This repository is organized as follows.

- `docs`: Folder containing general information about the platform, tutorials and similar documentaions.
- `models`: Folder containing hardware models to use with RTL tools. These models either are described in VHDL language (to use with Mentor's Questa software) or C++ (to use with URSA). However, these models can be adapted to use with other tools with minimal effort.
- `sim`: Simulation scripts for URSA and Quest tools. Additional tools will be added as the project grows.
   
## Third-Party Work

- HF-RISCV. The hf-riscv core is maintained by Sergio Johann (sjohann81). More information on his work can be found at [his repository](https://github.com/sjohann81). Also, our model of hf-riscv core is very based on the one provided by him. 

- HEMPS (and HERMES). The GAPH group maintains the HEMPS project. More information on their work can be found at [their website](http://www.inf.pucrs.br/hemps/getting_started.html). Provided network-on-chip router model is based on the RTL models available at [their repository](https://github.com/GaphGroup/hemps). 

## Licensing

See ``LICENSE.MD`` for details. 

## Contact

For now, I ([andersondomingues](https://github.com/andersondomingues)) am the only contributor to this project. Feel free to [mail me](mailto:ti.andersondomingues@gmail.com).

NOTICE: This repository is under construction, so expect missing references and documentation. May an asset be urgent to your cause, please feel free to contact me.
