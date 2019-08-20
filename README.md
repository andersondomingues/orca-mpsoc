# Welcome to the home of ORCA MPSoC project!

This repository holds the project for the hardware of ORCA MPSoC platform. The software counterpart of this repository can be found at [https://github.com/andersondomingues/ursa].

## The ORCA Platform

![Top-level architecture of ORCA platform](https://raw.githubusercontent.com/andersondomingues/orca-mpsoc/master/docs/orca-mpsoc.png)

## Repository organization

This repository is organized as follows.

- `docs`: Folder containing general information about the platform.
- `models`
   - `vhdl`: Folder containing hardware models to use with RTL tools, described in VHDL language. These models were developed for using with Mentor's Questa software, although they should work in other tools with minimal changes to the compilation or simulation scripts.
   - `ursa`: Folder containing hardware models to use with URSA API. More information on URSA can be found at [https://github.com/andersondomingues/ursa] 
- `sim`
   - `questa`: Folder containing simulation script to use with Mentor's Questa software. Please refer to the README in that folder for more information on how to simulate ORCA using Questa.
   - `ursa`: Folder containing compilation scripts and simulator based on URSA. Please refer to the README in that folder for more information on how to simulate ORCA using URSA.
   
## Third-Party Work

- HF-RISCV. The hf-riscv core is maintained by Sergio Johann (sjohann81). More information on his work can be found at [his repository](https://github.com/sjohann81). Also, our model of hf-riscv core is very based on the one provided by him. 

- HEMPS (and HERMES). The GAPH group maintains the HEMPS project. More information on their work can be found at [their website](http://www.inf.pucrs.br/hemps/getting_started.html). Provided network-on-chip router model is based on the RTL models available at [their repository](https://github.com/GaphGroup/hemps). 

- HELLFIREOS. We use [sjohann81's HellfireOS operating system](https://github.com/sjohann81) within the processing tiles of the ORCA platform. 

## Licensing

See ``LICENSE.MD`` for details. 

## Contact

For now, I ([andersondomingues](https://github.com/andersondomingues)) am the only contributor to this project. Feel free to [mail me](mailto:ti.andersondomingues@gmail.com).

NOTICE: This repository is under construction, so expect missing references and documentation. May an asset be urgent to your cause, please feel free to contact me.
