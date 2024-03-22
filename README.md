# HVNetService
Hyper-V Network Service

This is a demonstration of exporting a Windows Host network interface / adapter for use in WSL2 using:
 - windows side: AF_HYPERV sockets, Npcap;
 - linux side: AF_VSOCK and tuntap mode tap.

The windows side app is written in Delphi 5. Yes, 32bit. Why? Because I can. The only downside of this (32bit) is that computecore.dll is not available for 32bit so the hcsdiag.ee output is used to get the running VMs. The running VMs list is necessary in order to get the GUID to bind the AF_HYPERV socket to. Moreover (not sure why - ask MS) Hcs enum calls (hence hcsdiag.exe) require admin privileges - so the app has to be run with those provided.

The linux side is a small program that opens a tap device and connects to the windows (host) side via VSOCK and bridges both file descriptors.

# Prerequisites
Install NPcap. Bind it (if not already bound) to the adapters that you will share with WSL2. Get the %windir%\syswow64\npcap\packet.dll and wpcap.dll files and place them in the folder where the app is.

# Usage
Start WSL2
Start the windows app. Double click the WSL row from the list of VMs. This will start a listening socket for the VM to connect to. The port is 130.

In WSL2:
- vsocktap VLAN123 vlan123
VLAN123 is the friendly name of the network adapter as seen in Windows Network connections. vlan123 is the name of the tap adapter that will be created (if not already created) in linux.
- vsocktap VLAN130 vlan123
- vsocktap .... - as many as one might wish
Bring the links up and add ip addresses.

If you do not want for the linux adapters to disappear when vsocktap exits, you can create, up and configure them beforehand. Example:
ip tuntap add vlan123 mode tap
ip link set dev vlan123 up
ip addr add dev vlan123 192.168.123.222/24

# Building
WSL: gcc vsocktap.c -o vsocktap
Windows: use Delphi 5. I suppose this can easily be ported to Lazarus and build it for 64bit. Release is here.
