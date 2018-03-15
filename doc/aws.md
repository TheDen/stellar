# EC2 instance setup

This page details  how to setup a _Stellar_ server  using a cloud-based machine.
The installation procedure refers to Amazon public cloud service AWS.

## Instance launch

For a _Stellar_ server Amazon EC2 (a service within AWS) is used. The general
procedure for launching an EC2 server (_instance_) is covered by [Amazon's
documentation](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/LaunchingAndUsingInstances.html).

Select an instance type that fulfills _Stellar_ [server
requirements](server.md).  For the operating system (Ubuntu Server 16.04 LTS)
the Amazon AMI with code ami-33ab5251 is recommended.

Without  further  configuration,  EC2  instances  can be  reached  via  SSH  und
key-pair-based  authentication. This  configuration  is  sufficient for  running
_Stellar_.

## Basic install as user ubuntu

The following steps are necessary to install  all the software which is not part
of _Stellar_ server installation, but is required to complete it.

These steps are performed as the  user `ubuntu`, which has administrative rights
on the EC2 Ubuntu instances.

Connecting to the remote instance requires an [SSH client](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/AccessingInstancesLinux.html).

For instance,  under Linux or  OSX, from a  terminal use the  following command,
where `<EC2IP>` is the IP address and  the `<EC2KEY>` is the private key (`.pem`
file) provided by AWS upon launch:

```bash
ssh -i <EC2KEY> ubuntu@<EC2IP>
```

If succesful, the command will present a remote terminal.  All following
commands should be issued inside the remote terminal.u

### Install additional Ubuntu packages

Install the following packages, which are officially part of the Ubuntu server
16.04 distribution. Issue in sequence the commands:

```bash
# Update package list.
sudo apt-get update

# Get tools needed for installation/maintenance.
sudo apt-get install -y \
  aptitude \
  apt-transport-https \
  ca-certificates \
  curl \
  wget \
  less \
  screen

# Install python.
sudo apt-get install -y \
  ipython3 \
  ipython3-notebook \
  python3-pip

# Install a web browser.
sudo apt-get install -y firefox
```

### Install Docker

To install _Docker_ issue these commands:

```bash
curl -fsSL https://download.docker.com/linux/ubuntu/gpg > docker.key

sudo apt-key add docker.key

sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"

sudo apt-get update

sudo apt-get install -y docker-ce

sudo usermod -aG docker ubuntu
```

Close the  SSH connection with  `exit` and connect  again. Then test  the Docker
installation with:

```bash
docker run hello-world
```

A Docker container should get downloaded and executed. It will print the message
`Hello from Docker!` and additional useful information.

### Install docker-compose

To install _docker-compose_ issue this commands:

```bash
sudo curl -L https://github.com/docker/compose/releases/download/1.18.0/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose

sudo chmod +x /usr/local/bin/docker-compose

sudo ln -s /usr/local/bin/docker-compose /usr/bin

docker-compose --version
```

### Create the stellar user

Create the user `stellar` which will run the _Stellar_ platform.

```bash
sudo addgroup --gid 1001 stellar
sudo adduser --uid 1001 --gid 1001 --disabled-password --gecos stellar,,,, stellar
sudo usermod -aG docker stellar
```

Complete the new user setup.

```bash
# Become user stellar
sudo -i -u stellar

# Create an directory for user executables
mkdir -p ~/bin

# Generate and activate a key pair for stellar
ssh-keygen -t rsa -C "stellar@localhost"
# Press enter at all questions.
cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys
```

Go back to being user `ubuntu` and retrieve the new user's access credentials:

```bash
exit
sudo cp /home/stellar/.ssh/id_rsa /home/ubuntu/stellar.pem
sudo chown ubuntu:ubuntu /home/ubuntu/stellar.pem
```

### Create Stellar working directory

```bash
sudo rm -rf /opt/stellar

sudo mkdir -p /opt/stellar

sudo chown -R stellar:stellar /opt/stellar
```

### Install NodeJS and cloudcmd (optional)

The _NodeJS_  package _cloudcmd_  is not strictly  necessary for  _Stellar_, but
offers a convenient way of remotely exchanging data between client and server.

If  this package  is not  installed, users  is supposed  to have  a remote  copy
utility on  their clients (e.g.  _scp_, _Filezilla_)  to exchange data  with the
server.

```bash
wget https://nodejs.org/dist/v8.10.0/node-v8.10.0-linux-x64.tar.xz

sudo -i

mkdir -p /opt/sw

cd /opt/sw

tar xJvf /home/ubuntu/node-v8.10.0-linux-x64.tar.xz

PATH=/opt/sw/node-v8.10.0-linux-x64/bin:$PATH npm i cloudcmd -g

exit
```

### Logout from server

Leave the server with command `exit` or closing the SSH client application.

Before continuing  it the  user must  retrieve the new  connection key  that was
created for the  user `stellar`.  It was saved  as `/home/ubuntu/stellar.pem` on
the server  and it  can be  retrieved with  a remote  copy client  (e.g.  _scp_,
_Filezilla_). For instance, on Linux or OSX this command can be used to copy the
key in the current directory:

```bash
scp -i <EC2KEY> ubuntu@<EC2IP>:/home/ubuntu/stellar.pem .
```

__Note:__ it is  advisable to store the key  in a safe place and  remove it from
the server.

## Final install as user stellar

After completing the previous steps, the system is ready for a user to log in as
user `stellar` to finalize the installation  and start the _Stellar_ platform on
the server.

Connect to the server again, as `stellar` user. For instance, under Linxu or OSX
issue:

```bash
ssh -i stellar.pem stellar@<EC2IP>
```

After connecting complete the following steps.

### Install Jupyter and Stellar python client

```bash
# Install jupyter
pip3 install --user jupyter pandas

# Get python client and install it
wget https://github.com/data61/stellar-py/archive/v0.2.2.tar.gz
tar xzvf v0.2.2.tar.gz
cd stellar-py-0.2.2
pip3 install --user .
```

### Retrieve Stellar installation script

```bash
# Retrieve the scripts
cd ~/bin
wget https://github.com/data61/stellar/archive/v0.1.0.tar.gz
tar xzvf v0.1.0.tar.gz
rm v0.1.0.tar.gz

# Create a launcher
echo -e "#"'!'"/usr/bin/env bash\nbash /home/stellar/bin/stellar-0.1.0/scripts/docker/stellar.sh \"\$@\"\n" > stellar
chmod +x stellar
cd
```

### Launch stellar

It is now possible to launch _Stellar_. Issue the command

```bash
stellar start
```

The  first startup  may  take  several minutes,  as  the  Docker containers  are
downloaded. To stop _Stellar_ use:

```bash
stellar stop
```

### Launch the Jupyter notebook server (optional)

It is optional, but  recommended to launch a Jupyter notebook  server. 

Create the Jupyter configuration for the server:

```bash
mkdir -p ~/.jupyter
echo "c.NotebookApp.token = ''" > ~/.jupyter/jupyter_notebook_config.py
echo "c.NotebookApp.password = ''" >> ~/.jupyter/jupyter_notebook_config.py

```

Start Jupyter. It is also recommended  to start it within a terminal multiplexer
(like _GNU screen_), with:

```bash
screen -dmS jupyter bash -c 'jupyter notebook --no-browser ~/stellar-py-0.2.2/examples'
```

### Launch cloudcmd (optional)

This step is  optional, but can make remote file  exchange much more convenient.
It is  recommended to start  cloudcmd within  a terminal multiplexer  (like _GNU
screen_), with:

```bash
screen -dmS cloudcmd bash -c 'PATH=/opt/sw/node-v8.10.0-linux-x64/bin:$PATH cloudcmd --port 7777 --root /opt/stellar/data --no-console --no-terminal --no-vim --one-panel-mode --no-config-dialog'
```

## Use Stellar

_Stellar is now ready on your server_.

### Copy data files

You may copy over data files using cloudcmd if installed or with a remote copy client.

For instance on Linux and OSX do:

```bash
scp -i stellar.pem stellar@<EC2IP>:my-example.csv /opt/stellar/data
```

### Connect to Stellar

To use _Stellar_ UI or the python notebook follow the instructions [here](./remote.md#connecting-with-a-web-browser).

__Note__: if you followed these instructions to install on a local Ubuntu workstation, instead of an AWS remote instance, you can now use that same machine as client. Just point your browser to:
* [Web UI](http://127.0.0.1:6161)
* [File transfer - if installed](http://127.0.0.1:7777)
* [Python notebook](http://127.0.0.1:8888)
* [Search UI](http://127.0.0.1:3010)
