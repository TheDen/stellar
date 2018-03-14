# Connecting to your Stellar Demo Platform

The following instructions can be used  to connect to a _Stellar_ server, either
to get console access (to install, start,  stop or configure the platform) or to
gain browser access to the UI and Python notebook.

For the latter _port forwarding_ to the  client is the recommended method, as it
offers key-pair-based  authentication and  creates an encrypted  channel between
client and server.

After forwarding ports  (or creating a _tunnel_) using  these instructions, open
the following addresses on your local web browser:

- [Web UI](http://127.0.0.1:6161)
- [Python notebook](http://127.0.0.1:8888)
- [File transfer - if installed](http://127.0.0.1:7777)

## Connecting from Windows 

Download and install PuTTY <https://www.putty.org>. You will need PuTTYgen and the PuTTY SSH client itself to connect to the remote machine.

### PuTTYgen

If you have a _.pem_ file, the private key format generate by AWS EC2, you can convert it into a format that can be used by PuTTY using PuTTYgen (_.ppk_). 

To convert your private key:

1. Start PuTTYgen.
2. Under **Type of key to generate**, choose **RSA** 

    ![.](pics/windows-puttygen-rsa.png "PuTTYgen")

3. Import the _.pem_ file.

    ![.](pics/windows-puttygen-import.png "PuTTYgen")

4. Save private key.

    ![.](pics/windows-puttygen-save.png "PuTTYgen")

### PuTTY

You can now connect to the remote machine via PuTTY.

1. Start PuTTY.
2. Fill in the host name.

    ![.](pics/windows-putty-host.png "PuTTY")

3. Navigate to the _Auth_ section and locate your private key file for authentication.

    ![.](pics/windows-putty-auth.png "PuTTY")

4. Navigate to the _Tunnels_ section to add 6161, 7777, and 8888 as new forwarded ports.

    ![.](pics/windows-putty-ports.png "PuTTY")

5. Click **Open** to connect.

    ![.](pics/windows-ssh-success.png "Success")


## Connecting from MacOS

1. Open a terminal.
2. Use the **ssh** command to connect to the remote machine.

    ![.](pics/macOS-ssh-success.png "Success")

3. Forward ports 6161, 7777, and 8888.

    ![.](pics/macOS-ssh-ports.png "Ports")

