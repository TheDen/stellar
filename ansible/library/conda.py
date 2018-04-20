#!/usr/bin/python

DOCUMENTATION = """
---
module: conda
short_description: Manage conda packages
description: >
  Manage packages via conda.
  Can install, update, and remove packages.
author: Terry Moschou (@tmoschou)
notes: >
  Requires conda to already be installed. Packages specified using with_items
  are passed all at once, so that conda will install in a single transaction
options:
  name:
    description: >
      The name of a conda library to install. A package spec may be using
      when state=present. E.g. conda=4.2.* or conda=4.*. If no package is
      specified, all will be updated (requires state=latest)
    required: false
  state:
    description: >
      State in which to leave the Python package.
    required: false
    default: present
    choices: [ "present", "absent", "latest" ]
  channels:
    description: >
      List of extra channels to use when installing packages. Specified
      in priority order
    required: false
  executable:
    description: >
      Path to the conda executable to use. Default is search PATH, else
      /usr/local/conda/bin for the executable
    required: false
  update_dependencies:
    description: >
      Whether to update dependencies when installing/updating. The default is to
      update dependencies if state=latest, otherwise not to if state=present
    required: false
  prefix:
    description: The prefix of conda installation to manage. Mutually exclusive to env.
    required: false
  env:
    description: The conda environment to manage. Mutually exclusive to prefix.
    required: false
"""

EXAMPLES = """
- name: Update all conda packages
  conda:
    state: latest
- name: Install matplotlib 1.5.*
  conda:
    name: matplotlib=1.5.*"
    state: latest
- name: remove matplotlib from conda
  conda:
    name: matplotlib
    state: absent
- name: install packages in single transaction
  conda:
    name: "{{ item }}"
    state: present
  with_items: [a, b, c]
"""

import json
import re

def _add_channels_to_command(module, conda_args):
    """
    Add extra channels to a conda command by splitting the channels
    and putting "--channel" before each one.
    """
    channels = module.params['channels']
    if channels:
        for channel in channels:
            conda_args.append('--channel')
            conda_args.append(channel)


def _get_lookup_func(module, conda, conda_args):
    list_command = [conda, 'list', '--full-name'] + conda_args
    pattern = re.compile(r"(?P<channel>.*::)?(?P<name>.*)-(?P<version>[^-]*)-(?P<revision>[^-]*)")

    def lookup(package):
        command = list_command + [package]
        rc, stdout, stderr = module.run_command(command)
        list = json.loads(stdout)
        result = {'name': package}
        if len(list) == 1:
            item = list[0]
            if type(item) is unicode: # Conda 4.2 format
                match = pattern.match(item)
                if match:
                    result['channel'] = match.group('channel')
                    result['version'] = match.group('version')
            else: # Conda 4.3+ format
                result['channel'] = item['channel']
                result['version'] = item['version']
            result['installed'] = True
        else:
            result['installed'] = False
        return result

    return lookup


def _remove_package(module, conda, conda_args, to_remove):
    """
    Use conda to remove a given package if it is installed.
    """

    if len(to_remove) == 0:
        module.exit_json(changed=False, msg="No packages to remove")

    add_mutable_command_args(module, conda_args)

    remove_command = [conda, 'remove'] + conda_args + to_remove

    rc, stdout, stderr = module.run_command(remove_command)

    # Bug in 4.4.10 where they don't respect the --quiet with --json flag
    # they emit lots of progress json blobs
    # '{"fetch":"openssl 1.0.2n","finished":false,"maxval":1,"progress":0.995565}'
    # delimited by '\0' the null character. Grab the last blob.
    stdout = stdout.split("\0")[-1]

    result = json.loads(stdout)

    if rc != 0 or not result.get('success', False):
        module.fail_json(
            msg='failed to remove packages',
            packages=to_remove,
            rc=rc,
            command=remove_command,
            stdout_json=result,
            stderr=stderr
        )

    changed = did_change(result)
    module.exit_json(
        changed=changed,
        uninstalled=to_remove,
        command=remove_command,
        stdout_json=result,
        stderr=stderr
    )


def _install_package(module, conda, conda_args, to_install):
    """
    Install a package at a specific version, or install a missing package at
    the latest version if no version is specified.
    """
    if len(to_install) == 0:
        module.exit_json(changed=False, msg="no packages to install")

    add_mutable_command_args(module, conda_args)

    if module.params['update_dependencies'] is not None:
        if module.params['update_dependencies']:
            conda_args.append('--update-dependencies')
        else:
            conda_args.append('--no-update-dependencies')
    else:
        if module.params['state'] == 'latest':
            conda_args.append('--update-dependencies')
        else:
            conda_args.append('--no-update-dependencies')


    install_command = [conda, 'install'] + conda_args + to_install

    rc, stdout, stderr = module.run_command(install_command)

    # Bug in 4.4.10 where they don't respect the --quiet with --json flag
    # they emit lots of progress json blobs
    # '{"fetch":"openssl 1.0.2n","finished":false,"maxval":1,"progress":0.995565}'
    # delimited by '\0' the null character. Grab the last blob.
    stdout = stdout.split("\0")[-1]

    result = json.loads(stdout)

    if rc != 0 or not result.get('success', False):
        module.fail_json(
            msg='failed to remove packages',
            packages=to_install,
            rc=rc,
            command=install_command,
            stdout_json=result,
            stderr=stderr
        )

    changed = did_change(result)
    module.exit_json(
        changed=changed,
        installed=to_install,
        command=install_command,
        stdout_json=result,
        stderr=stderr
    )


def add_mutable_command_args(module, conda_args):
    conda_args.extend(['--yes', '--quiet'])

    if module.check_mode:
        conda_args.append('--dry-run')

    _add_channels_to_command(module, conda_args)


def did_change(result):

    actions = result.get('actions', {})

    # Bug in certain versions of conda. in dry-run mode, actions is wrapped in a singleton list
    if type(actions) is list:
        if actions: # if not empty
            actions = actions[0]

    link = actions.get('LINK')
    unlink = actions.get('UNLINK')
    symlink_conda = actions.get('SYMLINK_CONDA')

    return bool(link) or bool(unlink) or bool(symlink_conda)



def main():
    module = AnsibleModule(
        argument_spec={
            'prefix': {'required': False, 'type': 'path'},
            'env': {'required': False, 'type': 'path'},
            'name': {'required': True, 'type': 'list'},
            'state': {
                'default': 'present',
                'required': False,
                'choices': ['present', 'absent', 'latest']
            },
            'channels': {'default': None, 'required': False, 'type': 'list'},
            'update_dependencies': {'required': False, 'type': 'bool', 'default': None},
            'executable': {'default': None, 'type': 'path'},
            'force':  {'default': False, 'type': 'bool'},
        },
        mutually_exclusive=[['prefix', 'env']],
        supports_check_mode=True
    )

    conda = module.params['executable'] or module.get_bin_path(
        "conda",
        required=True,
        opt_dirs=['/usr/local/conda/bin']
    )

    packages = module.params['name']
    state = module.params['state']

    conda_args = ['--json']

    if module.params.get('prefix'):
        conda_args.extend(['--prefix', module.params['prefix']])
    elif module.params.get('env'):
        conda_args.extend(['--name', module.params['env']])

    lookup_func = _get_lookup_func(module, conda, conda_args)

    if module.params.get('force'):
        conda_args.append('--force')

    if state == 'absent':
        lookups = [lookup_func(x) for x in packages]
        to_remove = [package['name'] for package in lookups if package['installed']]
        _remove_package(module, conda, conda_args, to_remove)
    elif state == 'present':
        # We need to install packages that are not installed, or if installed but with a version specifier
        lookups = [(package_sepc, lookup_func(package_sepc.split('=', 1)[0])) for package_sepc in packages]
        to_install = [package_sepc for package_sepc, lookup in lookups if '=' in package_sepc or not lookup['installed']]
        _install_package(module, conda, conda_args, to_install)
    elif state == 'latest':
        _install_package(module, conda, conda_args, packages)


# import module snippets
from ansible.module_utils.basic import *


if __name__ == '__main__':
    main()
