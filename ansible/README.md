# Ansible
This subdirectory contains the Ansible playbooks used for automation of the the deployment, configuration and management 
of the stellar system on end-user machines. 

References: https://docs.ansible.com/ansible/latest/user_guide/index.html

## Supported Systems

We officially support
* Ubuntu 16.04 LTs 64-bit

We provide best effort support with no guarantees for
* CentOS 7.4 64-bit

We do not support (but may still work as for the most part equivalent to CentOS)
*  Red Hat Enterprise Linux (RHEL) 7.4 64-bit

Note that Docker _only_ supports the Enterprise Edition (EE) on RHEL. The Community Edition (CE) is
explicitly not supported by Docker on RHEL according to https://docs.docker.com/install/linux/docker-ee/rhel/.
However the CE is supported by docker on CentOS - so use at your own peril.

We do however test the Ansible plays (and Docker CE) against Vagrant Ubuntu, CentOS and RHEL boxes.
Testing against RHEL requires registering for a developer account - See Developing below.

## Prerequisites

* Ansible 2.5+

Ansible manages machines in an agent(daemon)-less manner, using by default the SSH protocol.
Ansible is decentralized – it relies on your existing OS credentials to control access to remote machines. If needed,
Ansible can easily connect with Kerberos, LDAP, and other centralized authentication management systems.

You only need to install Ansible on one machine, called the control machine (which could easily be a laptop)
and it can manage an entire fleet of remote machines from that central point. It can be run from any machine with Python 2
(versions 2.6 or 2.7) or Python 3 (versions 3.5 and higher) installed (Windows isn’t supported
for the control machine).

For instructions for installing Ansible on the control machine - see 
http://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html
for details. It includes many installation options including ones for those that do not have
administrative privileges for the control machine. 

In addition to the installation methods in the above link, Mac users can also install via
Homebrew package manager (`brew install ansible`).

## Inventory
Before running Ansible, you need to define an inventory which tells Ansible which hosts to manage and how to
connect to it. **Note:** if you are using Vagrant for testing/development you do not need to do this as Vagrant will
automatically generate an inventory.

Otherwise edit the file named `inventory` located in this `ansible` directory. Your inventory need only contain
a single line defining your hostname or alias of the machine you wish to manage. Examples
```
stellar-server.example.com     # fully qualified hostname or alias, or
stellar-server                 # hostname or alias
```

**Note:** The current version of stellar is only installed on one machine. Future versions may require you to define
multiple servers and their groups hierarchically. E.g.

```
[stellar-cluster]
stellar-node1.example.com
stellar-node2.example.com
stellar-node3.example.com

[stellar-ui]
stellar.example.com

[stellar:children]
stellar-cluster
stellar-ui
...
```

### Inventory variables
Ansible allows you to specify variables that are defined on a per host setting or on groups. 
It is important to define the behavioral inventory variables that define how to connect to the managed host
such as the the
* ssh user name and password (or private key) to use
* IP address (if using an hostname alias without a DNS entry) and
* sudo user name and password for privilege escalation of the remote machine to manage if required

This can be done in the inventory file as KEY=VALUE pairs, but it is advised to define these in separate files.

Create a vars file located at `ansible/host_vars/<hostname>/vars.yml`, where `<hostname>` is the entry in your
inventory file. See `host_vars/stellar-server.example.com/vars.yml` for example and 
http://docs.ansible.com/ansible/latest/user_guide/intro_inventory.html#list-of-behavioral-inventory-parameters
for list of all behavioural inventory parameters. 

Variables containing passwords and other sensitive secrets should
instead go in `ansible/host_vars/<hostname>/vault.yml` where `vault.yml` is encrypted using the `ansible-vault` command.
See http://docs.ansible.com/ansible/latest/user_guide/playbooks_vault.html, 
http://docs.ansible.com/ansible/latest/user_guide/vault.html and
https://docs.ansible.com/ansible/latest/user_guide/playbooks_best_practices.html#best-practices-for-variables-and-vaults

Usually the control machine is different from the machines that are managed in the inventory, however 
Ansible does support non-ssh connection types such as the `local` connection type for managing the same host that
Ansible is run from. This may be preferable to define `ansible_connection: local` if you do not have access to
another non-Windows work station to run Ansible from and you wish instead to run ansible on the machine you wish to
manage (not recommended).

If you are provisioning on Ubuntu 16.04 LTS you will also need to set `ansible_python_interpreter: /usr/bin/python3`
as the default Ansible python interpreter `/usr/bin/python` does not exist.

## Running

To test your inventory is correct run from the `ansible` directory
```
ansible -i inventory --become --check --module-name [--ask-vault-pass] setup all
```

If you have created any encrypted files or variables you will need to specify --ask-vault-pass and specify the 
decryption password used when encrypting the files with `ansible-vault`, when prompted on the command line.

This will run the `setup` module as an ad-hoc task and print a list of facts about all the defined hosts.
 
**Optional step for Redhat users.**
Your redhat system must be subscribed - the `redhat.yml` playbook can do this for you and requires you to define
account `username` and `password` (vaulted) under the `rhel` key in your inventory. I.e.
```yaml
rhel:
  username: <redhat-account-username>
  password: <redhat-account-password>
```

And then register your Red Hat subscription with  
```commandline
ansible-playbook -i inventory --ask-vault-pass redhat.yml
```
You Red Hat Administrator may have already done this for you.

To run the stellar playbook, run
```
ansible-playbook -i inventory [--verbose] stellar.yml 
```

This will run a sequence of tasks.

At the end of the playbook run you will see a synopsis of the number of tasks that either
 * resulted in a change in state on the managed machine (yellow) - e.g. file edited, package installed 
 * no change in state; already in the correct state, (green) or
 * skipped (cyan), e.g task not applicable for debian or centos/redhat

Any subsequent re-runs of the stellar.yml playbook should result in no change of state - i.e the tasks are
idempotent.

To print extra information on what was changed for each task, you can supply the `--verbose` parameter.

## Developing

In addition to ansible, need to install Vagrant.

On MacOS
```commandline
brew cask install vagrant vagrant-manager virtualbox
```

Then install required plugins
```
vagrant plugin install vagrant-hostmanager
vagrant plugin install vagrant-persistent-storage
```

Testing against the RHEL vagrant box requires registering for a free Red Hat Developer Program account - see
[https://developers.redhat.com/](https://developers.redhat.com/). You should then add to `host_vars/vagrant-rhel/vault.yml`
the following
```yaml
rhel:
  username: <redhat-account-username>
  password: <redhat-account-password>
```
and encrypt the file using `ansible-vault` 

Then to create an Ubuntu, CentOS and RHEL virtual machines and test provisioning them with ansible (in parallel), run
```
vagrant up
```

To re-provision machines with ansible that are already up, run
```
vagrant provision
```

To destroy the machines so that you test provisioning from a fresh clean state run 
```commandline
vagrant destroy
```

You may also wish to destroy the persistence additional docker storage for the VMs at
`ansible/.vagrant/docker-storage/*.vdi` as these are not destroyed by vagrant.

To have Vagrant run Ansible in verbose mode, uncomment the setting `ansible.verbose = true` in the
`Vagrantfile`.

You can ssh into the vagrant boxes with `vagrant ssh vagrant-{centos|ubuntu|rhel}`
