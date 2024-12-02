#!/bin/bash

switch_channel() {
  echo Switching to channel $1
  sed -i "s/^channel=[0-9]\+/channel=$1/" /etc/hostapd/hostapd.conf
  systemctl reset-failed hostapd # Bypasses the systemd start limit
  systemctl restart hostapd
}

switch_band() {
  echo Switching to band $1
  sed -i "s/^hw_mode=.*/hw_mode=$1/" /etc/hostapd/hostapd.conf
}

wait_for_connection() {
  echo Waiting for device to reconnect
  local attempt=0
  local max_attempts=30

  while ! ping -c 1 -W 1 192.168.1.2 &> /dev/null; do
    ((attempt++))
    if [ $attempt -ge $max_attempts ]; then
      echo "Device did not reconnect after $max_attempts attempts."
      return 1
    fi
  done

  echo "Device reconnected."
  return 0
}


# Check for root
if [[ $EUID > 0 ]]; then
  echo "This script needs to be run as root!!"
  exit
fi

# Stop NetworkManager and wpa_supplicant
systemctl stop NetworkManager wpa_supplicant

# Start hostapd
systemctl start hostapd

# Set static IP address
ip addr add 192.168.1.1/24 dev wlan0

# Create logs folder (if missing)
mkdir -p logs

# Get device distance
read -p "Device distance: " distance

# 2.4GHz channels
switch_band "g"
for ((i=1; i<=11; i++)); do
  switch_channel $i
  echo \{\"band\":\"g\",\"channel\":$i,\"distance\":$distance\} | tee -a logs/g_${i}_${distance}.log
  wait_for_connection
  if [ $? -eq 0 ]; then
    ping -i 0.2 -W 1 -c 100 192.168.1.2 | tee -a logs/g_${i}_${distance}.log
  else
    echo DNC | tee -a logs/g_${i}_${distance}.log
  fi
  echo
done

# 5GHz lower channels
switch_band "a"
for ((i=36; i<=48; i+=4)); do
  switch_channel $i
  echo \{\"band\":\"a\",\"channel\":$i,\"distance\":$distance\} | tee -a logs/a_${i}_${distance}.log
  wait_for_connection
  if [ $? -eq 0 ]; then
    ping -i 0.2 -W 1 -c 100 192.168.1.2 | tee -a logs/a_${i}_${distance}.log
  else
    echo DNC | tee -a logs/a_${i}_${distance}.log
  fi
  echo
done

# 5GHz upper channels
for ((i=149; i<=165; i+=4)); do
  switch_channel $i
  echo \{\"band\":\"a\",\"channel\":$i,\"distance\":$distance\} | tee -a logs/a_${i}_${distance}.log
  wait_for_connection
  if [ $? -eq 0 ]; then
    ping -i 0.2 -W 1 -c 100 192.168.1.2 | tee -a logs/a_${i}_${distance}.log
  else
    echo DNC | tee -a logs/a_${i}_${distance}.log
  fi
  echo
done

# Return system to normal state
systemctl stop hostapd
systemctl restart NetworkManager wpa_supplicant


echo "############################"
echo "#                          #"
echo "#  TEST ROUND COMPLETE!!!  #"
echo "#                          #"
echo "############################"
