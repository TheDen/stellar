## Instance setup

AMI: 64 bit Ubuntu Server 16.04 LTS (HVM), SSD Volume Type - ami-33ab5251

Add coordinator port to inbound rules.

Also add other port for testing?

## Basic install

export DEMOIP=52.65.88.223

ssh -X -i ~/Keys/stellar-demos.pem ubuntu@$DEMOIP

## Packages

sudo apt-get update

sudo apt-get install -y \
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
screen

## Users

__Don't use for now!__

sudo addgroup --gid 1001 demo
sudo adduser --uid 1001 --gid 1001 --disabled-password --gecos demo,,,, demo
sudo usermod -aG sudo demo

sudo -i demo
mkdir .ssh
sudo cp /home/ubuntu/.ssh/authorized_keys .ssh
sudo chown

mkdir ~/bin

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

## Resources

sudo mkdir -p /data/user
sudo chmod -R 777 /data

## Coordinator

wget http://apache.mirror.amaze.com.au/nifi/1.5.0/nifi-1.5.0-bin.tar.gz
tar xzvf nifi-*.tar.gz

mkdir ~/bin
cd ~/bin
for i in $(ls ~/nifi-*/bin/*.sh); do ln -s $i;done
cd ..

__ON LOCAL MACHINE!!!__
scp -i ~/Keys/stellar-demos.pem /home/amm00b/CSIRO/WORK/Dev/Stellar/stellar-demo/Coordinator/flow.xml.gz ubuntu@$DEMOIP:~/nifi-*/conf/
scp -i ~/Keys/stellar-demos.pem /home/amm00b/CSIRO/WORK/Dev/Stellar/stellar-demo/Coordinator/stellar.properties ubuntu@$DEMOIP:~/nifi-*/conf/

sp=$(find ~/nifi-* -iname stellar.properties); echo $sp
nifi.variable.registry.properties=/path/to/stellar-coordinator/nifi/conf/stellar.properties
ubuntu@ip-172-31-24-27:~/nifi-1.5.0/conf$ --> flow.xml.gz

### Run redis and NiFi
docker run -d -p 6379:6379 --name stellar redis
nifi.sh run

## Ingestor

__ON LOCAL MACHINE!!!__
scp -i ~/Keys/stellar-demos.pem /home/amm00b/CSIRO/WORK/Dev/Stellar/stellar-ingest-dev/target/uberjar/stellar-ingest-0.0.2-SNAPSHOT-standalone.jar ubuntu@$DEMOIP:~/
scp -r -i ~/Keys/stellar-demos.pem /tmp/stellar ubuntu@$DEMOIP:/tmp

java -cp ~/stellar-ingest-0.0.2-SNAPSHOT-standalone.jar stellar_ingest.rest 3000




