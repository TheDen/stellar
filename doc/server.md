# Server-side installation

_Stellar_ is available  as a set of  Docker containers, installed and  run by an
orchestration  script.  These  containers  communicate via  REST  API calls  and
exchange data through a host volume, that must be mounted inside the containers.

The server installation comprises the following modules:
- backend (actuall pipeline)
- config ui, ingestion and indexing access
- search ui, search access
- notebook server

## Supported server environment

Currently, for official  _Stellar_ installations, only __deployment  on a single
machine__ is supported.

### Hardware requirements

The server machine must fulfill these __minimal hardware requirements__:

- A  fairly recent _Intel_  64 bit  server-class CPU, e.g.  Xeon E7 v3,  4 cores
  (recommended Xeon E7 v4, 8 cores)
- 16 GB of RAM (32+ GB recommended)

These requirements are typically sufficient  to run graph fulfilling the current
data specifications (50000 nodes).

#### Additional hardware requirements

If the server machine is to be remotely accessed by the clients, as described in
[Remote access](remote.md)),  a permanent, low-latency,  large-bandwidth network
connection between server and clients is required, such as _Gigabit Ethernet_.

To install or upgrade _Stellar_ modules from their online repositories ([Data61
DockerHub](https://hub.docker.com/r/data61/) and [Data61
GitHub](https://github.com/data61)) an Internet connection is required during
the installation.

### Software requirements

The server machine must be __equipped with the following base software__:

- Operating system: 64 bit _Ubuntu Server 16.04 LTS_ (Xenial Xerus)
- _Docker_ engine version 17.12.1-ce (or a later, compatible version)
- Docker orchestration  system  _docker-compose_ version  1.18.0  (or a  later,
  compatible version)
- Jupyter/iPython

It is responsibility of the users to provide suitable installations of the above
listed packages, in  compliance with their IT policies.

A  [detailed  guide](aws.md)  is  provided to  help  installing  these  software
packages and running Stellar on a cloud-hosted server.

#### Additional software requirements

If the server machine is to be  remotely accessed by the clients as described in
[Remote  access](remote.md))  an  SSH  server  installation  is  required,  like
[OpenSSH](https://www.openssh.com/).
