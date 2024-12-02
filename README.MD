# Wi-Not: a script to test per-frequency signal reliability

### Usage
On the laptop used to run the experiment, install the hostapd and iproute2 packages before usage.

1. Place the `hostapd.conf` file in the directory /etc/hostapd/
2. Enable hostapd by running the command `systemctl unmask hostapd.service`
3. Run the script `wi-not.sh` as root with the command `sudo bash wi-not.sh`
4. Run the experiment, checking output as needed.