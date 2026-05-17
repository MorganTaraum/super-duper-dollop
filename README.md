# Hardware Requirements

Platform (Change to Mac if you are on Mac)
OS: Windows 11 Pro 23H2
CPU: AMD Ryzen 7 5800X 8-Core Processor 3.80 GHz
RAM: 64 GB

Platform Hypervisor	(Change to Fusion if you are on Mac)
VMware® Workstation 16 Pro 16.2.5 build-20904516

Sandbox Host	
OS: Ubuntu 24.04.4 Desktop (64-bit)
Processors: 4
RAM: 16 GB
HDD: 200 GB
Network Adapter: NAT
Virtualize Intel VT-x/EPT or AMD-V/RVI: On
Virtualize CPU performance counters: On

Sandbox Hypervisor	
KVM

Sandbox Guest	
OS: Windows 10 21H2
CPUs: 2
RAM: 8192
HDD: 60 GB


# Steps to follow for installation

## Before doing anything

```bash
sudo apt update && sudo apt upgrade

# Making a place to put scripts and such
mkdir Cape-Sandbox
cd Cape-Sandbox
```

## KVM Installation (The VM thing)

```bash
wget https://raw.githubusercontent.com/Hrztrm/CapaV2-scripts/refs/heads/main/kvm-qemu.sh
sudo chmod a+x kvm-qemu.sh
# Original: sudo ./kvm-qemu.sh all <username> | tee kvm-qemu.log
sudo ./kvm-qemu.sh all $USER | tee kvm-qemu.log # sb is my username, change it to your own created username

# Test whether KVM works or not
kvm-ok

# Expected Output:
# INFO: /dev/kvm exists
# KVM acceleration can be used

# Maybe reboot if needed (Official said so)
sudo shutdown -r now
# Check virt-manager runs without any errors
sudo virt-manager # Firs time only
virt-manager
```

### Troubleshooting I faced

Error when the HypervisorV or something not found when opening virt-manager
```bash
# If the virt-manager didn't auto detect qemu, try:
virt-manager --connect qemu:///system
# If that works but the default doesn't, go to File → Add Connection in virt-manager, select QEMU/KVM, and set it as default
# Could be an error with qemu installation, so we try
# Check your installation log for errors
grep -i "error\|fail\|warn" ~/kvm-qemu.log | head -50

# If there is, hopefully a reinstallation would fix it
sudo ~/Cape-Sandbox/kvm-qemu.sh qemu $USER 2>&1 | tee kvm-qemu-retry.log # Again, change "sb" with your own username


# If you get error about port conflict like
# dnsmasq: failed to create listening socket for port 53: Address already in use
# Time to stop that

# Check what's using port 53
sudo ss -lptn 'sport = :53'

# Usually it's systemd-resolved, disable it
sudo systemctl disable systemd-resolved --now
sudo rm /etc/resolv.conf
echo "nameserver 8.8.8.8" | sudo tee /etc/resolv.conf

# Try to reinstall again
sudo ~/Cape-Sandbox/kvm-qemu.sh qemu $USER 2>&1 | tee kvm-qemu-retry.log # Again, change "sb" with your own username
```

## CAPE Sandbox Installation

```bash
cd /opt
sudo wget https://raw.githubusercontent.com/Hrztrm/CapaV2-scripts/refs/heads/main/cape2.sh
sudo chmod +x cape2.sh
sudo ./cape2.sh all cape | sudo tee cape.log

# A new folder called CAPEv2 should be created at /opt/CAPEv2
```

There could be warnings/errors occuring. But still seems to work fine

## Installing Dependencies (Using Poetry, cuz it is recommended)

Install Poetry (Shuold not need to be done. ALready installed from cape2.sh script) Path for cape2.sh installation is at /etc/poetry/bin/poetry
```bash
curl -sSL https://install.python-poetry.org | python3 -
```

Make poetry easier to use
```bash
# Add poetry to path for all users
sudo ln -s /etc/poetry/bin/poetry /usr/local/bin/poetry

# Restart terminal

cd /opt/CAPEv2

# Install the depedencies
sudo -u cape poetry run poetry install

# Check if it good or not
poetry env list
# Expected: capev2-t2x27zRb-py3.10 (Activated)

# Install additional dependicies if needed
sudo -u cape poetry run pip install -r extra/optional_dependencies.txt
```

### Problems

If you are stuck at `poetry install`. Like nothing is printing our and its been a while. Try this
```bash
export PYTHON_KEYRING_BACKEND=keyring.backends.null.Keyring
poetry install -vvv
```

And hopefully it actually progresses

## Important Note
To actually run the thing, and most of the configuration scripts and programs, you **MUST** run as `cape` user. `cape` user should already been created with the `cape2.sh` script:
```bash
sudo -u cape poetry run python3 cuckoo.py

# Get bash access for the user cape
sudo su - cape -c /bin/bash

```
Exception being installation scripts and utilities scripts like `rooter.py`

## Installing the VM for CAPE

Download the ISO from [Microsoft website](https://www.microsoft.com/en-au/software-download/windows10). Its easier if you download from a Linux OS, because you can just directly download the ISO instead of needing to "build" it like you need to do for Windows OS.


### Troubleshoot 

When creating a VM, you get an error about "Could not start virtual network 'default'...."
Full Error I got:

Could not start virtual network 'default': internal error: Child process (VIR_BRIDGE_NAME=virbr0 /usr/sbin/dnsmasq --conf-file=/var/lib/libvirt/dnsmasq/default.conf --leasefile-ro --dhcp-script=/usr/libexec/libvirt_leaseshelper) unexpected exit status 2: 
dnsmasq: failed to create listening socket for 192.168.122.1: Address already in use

Try
```bash
# Check if it is active or not
sudo virsh net-list --all

# Disable the things using that port/address (This is systemd-resolved)
sudo systemctl disable systemd-resolved --now
sudo systemctl stop systemd-resolved

# This is for dnsmasq
sudo systemctl stop dnsmasq
sudo systemctl disable dnsmasq

# Fis DNS resolver
sudo rm /etc/resolv.conf
echo "nameserver 8.8.8.8" | sudo tee /etc/resolv.conf

# Start the libvirt network
sudo virsh net-start default
sudo virsh net-autostart default

# If there is something else using that port
# Find the offending process
sudo ss -lptn 'sport = :53'
# Kill whatever process is listed
sudo kill -9 <PID>
# Then retry Step 3
```

## VM Settings

Well, follow the thing, espeically the docs. KIV

Windows Activation
```powershell
irm https://get.activated.win | iex
```

Remeber to take snapshots beofre doing these next steps. Just in case ;)

### Reconfiguring/Debloating Windows

Require Tamper Protection to be off first — do that via Settings > Windows Security > Virus & threat protection > Manage settings, or it'll silently ignore the registry writes

Then open with Powershell as Admin

Use win10_reduce_noise.ps1 to reduce the noise in windows 10 VM. This is just a converted version of [disable_win7noise.bat](https://github.com/kevoreilly/CAPEv2/blob/master/installer/disable_win7noise.bat) from CAPE one. 

(Script include debloater from [w4rh4wk](https://github.com/w4rh4wk/debloat-windows-10). So be aware and maybe read the script if you want)

### Unharden Office 2010

For Microsoft Office installation, get the 2010 version at https://massgrave.dev/office_msi_links

To deharden Office 2010. Use the Office-2010-Unhardening.ps1 script. Be sure to run as Powershell Admin!

### Adobe Acrobat Installation

Download the installer https://get.adobe.com/uk/reader/ and install as usual.

But make sure to install the 2 bloatware that comese with it,
1. Adobe Photo Express
2. Mcafee Thing

### Install Sysmon

```powershell
# Install Sysmon with Olafhartong sysmonconfig-with-filedelete config 
# Download Sysmon
Invoke-WebRequest -Uri "https://download.sysinternals.com/files/Sysmon.zip" -OutFile "C:\Sysmon.zip"
Expand-Archive -Path "C:\Sysmon.zip" -DestinationPath "C:\Sysmon"

Invoke-WebRequest -Uri "https://raw.githubusercontent.com/olafhartong/sysmon-modular/master/sysmonconfig-with-filedelete.xml" -OutFile "C:\Sysmon\sysmonconfig.xml"

# Install Sysmon with config
C:\Sysmon\Sysmon64.exe -accepteula -i C:\Sysmon\sysmonconfig.xml

# Delete Sysmon installer after install
Remove-Item -Path "C:\Sysmon.zip" -Force
Remove-Item -Path "C:\Sysmon" -Recurse -Force
```

### Agent Installation and Configure Startup

Install Python (Version Python versions > 3.10 and < 3.13 are preferred.)
```powershell
# https://www.python.org/ftp/python/3.12.10/python-3.12.10.exe
iwr https://www.python.org/ftp/python/3.12.10/python-3.12.10.exe -o C:\python-3.12.10.exe

# Install it as usual
# Make sure to check the "Add python.exe to PATH" during installation

# Check if there is error or not
python --version

# Install additioanl tools for CAPE like pillow 
python -m pip install --upgrade pip
python -m pip install Pillow

```
Download Agent AND Add agent as part of task scheduler (With Powershell as Admin)
```powershell
# 1. Download agent.py
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/kevoreilly/CAPEv2/master/agent/agent.py" `
    -OutFile "C:\origami.pyw" # Change name and path as you like

# 2. Create scheduled task to run agent at logon with highest privileges
$action  = New-ScheduledTaskAction -Execute "pythonw.exe" -Argument "C:\origami.pyw" # Change name and path as you like
$trigger = New-ScheduledTaskTrigger -AtLogOn
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
$principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest

Register-ScheduledTask `
    -TaskName   "Fold Origami" ` # Change this as you like
    -Action     $action `
    -Trigger    $trigger `
    -Settings   $settings `
    -Principal  $principal `
    -Force
```

Test the agent.
1. From the Sandbox host (Linux One) try doing
```bash
curl http://<Sandbox IP>:8000
```

Expected Output:
```bash
sb@sb:/opt/CAPEv2/agent$ curl http://192.168.122.142:8000
{"message": "CAPE Agent!", "version": "0.21", "features": ["execpy", "execute", "pinning", "logs", "largefile", "unicodepath", "mutex", "browser_extension"], "is_user_admin": true}
```

If it is the same, it should be working




# References
https://endsec.au/blog/building-an-automated-malware-sandbox-using-cape/#:~:text=CAPE%20Sandbox%20supports%20a%20variety,VMware%20Fusion%20Pro%2C%20or%20VirtualBox.
