# Server-side installation

_Stellar_ is available as a set  of Docker containers.  These require mounting a
shared data exchange area  in the form of __a host volume,  writable by the user
who starts _Stellar_.__

The server installation comprises the following modules:
- backend (actuall pipeline)
- config ui, ingestion and indexing access
- search ui, search access
- notebook server

Please note that  _Stellar distribution_ packages contain the  Docker images and
source code  of all modules on  a physical medium,  such as Blu-ray disc  or USB
flash drive. 


## Supported server environment

Currently, for official  _Stellar_ installations, only __deployment  on a single
machine__ is supported.

### Hardware requirements

The server machine must fulfill these __minimal hardware requirements__:

- A  fairly recent _Intel_  64 bit  server-class CPU, e.g.  Xeon E7 v3,  4 cores
  (reccommended Xeon E7 v4, 8 cores)
- 16 GB of RAM (32+ GB reccommended)

__Note:__ the minimal configuration is sufficient to run the current
pipeline
work with the provided example datasets.

Larger datasets and/or more complex combinations of analytics will incur
greater memory and/or CPU consumption.

#### Additional hardware requirements

If the server  machine is to be  remotely accessed by the clients  (using one of
the options described in  [Remote access](remote.md)), a permanent, low-latency,
large-bandwidth network connection between server  and clients is required, such
as _Gigabit Ethernet_.

If  _Stellar_  modules  are  to  be installed  or  upgraded  from  their  online
repositories   ([Data61  DockerHub](https://hub.docker.com/r/data61/),   [Data61
GitHub](https://github.com/data61)) an  Internet connection is  required. During
the installation.

### Software requirements

The server machine must be __equipped with the following base software__:

- Operating system: 64 bit _Ubuntu Server 16.04 LTS_ (Xenial Xerus)
- _Docker_ engine version 17.12.1-ce (or a later, compatible version)
- Docker orchestration  system  _docker-compose_ version  1.18.0  (or a  later,
  compatible version)

- Jupyther/iPython

It is responsibility of the users to provide suitable installations of the above
listed packages, in  compliance with their IT policies.  This document describes
how _Docker_ and _Jupyter_ can be installed on a 

assuming that an Internet connection is provided.

Fully operational, cloud-hosted [test installations](aws.md) will be provided to
stakeholders of the _Investigative Analytics_ project.

#### Additional software requirements

If the server  machine is to be  remotely accessed by the clients  (using one of
the  options described  in [Remote  access](remote.md)), additional  software is
required.

- An  [OpenSSH](https://www.openssh.com/) server installation, to  enable remote
  console  access and,  potentially, forward  services  to the  clients over  an
  encrypted channel.
- Optionally, a [VNC](https://www.tightvnc.com/) server installation, to offer a
  remote server desktop to clients.


If _Stellar_ is to be installed from the networ

If  _Stellar_  modules  are  to  be installed  or  upgraded  from  their  online
repositories   ([Data61  DockerHub](https://hub.docker.com/r/data61/),   [Data61
GitHub](https://github.com/data61)) an  Internet connection is  required. During
the installation.


wget, git, text editor and development tools to get source distribution.


### Machine preparation

Stellar distribution all that you need.
If build from sources additional tools may be needed. Refer to the individual modules.

Network for installation.




export DEMOIP=52.63.170.31

ssh -X -i ~/Keys/stellar-demos.pem ubuntu@$DEMOIP
ssh -X -i ~/Keys/stellar-dev.pem ubuntu@$DEMOIP


sudo apt-get update

sudo apt-get install -y \
aptitude \
apt-transport-https \
ca-certificates \
curl \
wget \
software-properties-common \
openjdk-8-jdk \
build-essential \
emacs-nox \
xsel \
git \
less \
screen \
firefox

## Docker

curl -fsSL https://download.docker.com/linux/ubuntu/gpg > docker.key
sudo apt-key add docker.key
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt-get update
sudo apt-get install -y docker-ce

Add user to docker group (requires relogging in or using su - in terminal)
sudo usermod -aG docker ubuntu

Log out and in again...

Test Docker installation
docker run hello-world

## Docker Compose

sudo curl -L https://github.com/docker/compose/releases/download/1.18.0/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
sudo ln -s /usr/local/bin/docker-compose /usr/bin
docker-compose --version


## Jupyter
sudo apt-get install -y ipython3 ipython3-notebook python3-pip

pip3 install --user jupyter

git clone https://github.com/data61/stellar-py.git
(must pick the right branch)

pip3 install --user .

jupyter notebook --no-browser --port=8889



