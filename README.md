# Routing with OSPF
Configuring OSPF routing on a virtual network using shell scripts.

![Figure 1](docs/figure1.PNG)

## Project 🌳
```
OSPFRouting/
├── README.md
├── config
│   ├── VERSION
│   ├── saved <- This is where the ./saved_configs.sh output is!
│   └── generated
│       ├── ATLA_host_interface_config
│       ├── ATLA_host_interface_config_clear
│       ├── ATLA_router_interface_config
│       ├── ATLA_router_interface_config_clear
│       ├── ATLA_router_ospf_config
│       ├── ATLA_router_ospf_config_clear
│       └── and so on...
├── docs
│   ├── figure1.PNG
│   ├── step-10.txt
│   ├── step-11.txt
│   ├── step-12.txt
│   └── step-9.txt
├── logs
│   ├── ping_1_2
│   ├── ping_1_3
│   └── and so on...
└── scripts
    ├── README.md
    ├── activate.sh
    ├── deactivate.sh
    ├── generate_host_interface.sh
    ├── generate_router_interface.sh
    ├── generate_router_ospf.sh
    ├── ssh_clear_config.sh
    ├── ssh_goto_pair.sh
    ├── ssh_measure.sh
    └── ssh_update_config.sh
```

### Usage
The [**config/**](config) subdirectory contains the **network configuration files**.
This is also where the [generated](scripts/generated) addresses and command lines go.
- To generate the addresses, run `generate-configs` while the venv is activated.
- Each file has lines for an interface's configuration to run all as a batch.
- An edited copy is also made which can reverse the same configuration if called.

The [**docs/**](docs) subdirectory contains the text files:
- [docs/step-9.txt](docs/step-9.txt)
- [docs/step-11.txt](docs/step-11.txt)
- [docs/step-12.txt](docs/step-12.txt)
- [docs/step-13.txt](docs/step-13.txt)

The [**logs/**](logs) subdirectory contains pane captures from tests:
- [logs/test_LOND_BOST](logs/test_LOND_BOST) (all tests for a pair)
- [logs/ping_1_6](logs/ping_1_6) (individual test for a pair)
- _and so on..._

_These scripts expect a 'config' file at root (mine is ignored in the repo) that should also be 'included' in '~/.ssh/config'._

## Commands
1. To start the environment use `source scripts/activate.sh` (also includes a deactivate function).
2. To deactivate use `deactivate` in the command line, or `source scripts/deactivate.sh` as a fallback.

_See [scripts/README.md](scripts/README.md) for more info on the virtual environment._
