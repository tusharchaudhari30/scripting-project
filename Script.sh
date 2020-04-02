#!/bin/bash

# Interupt and Exit Function
control_c()
{
   clear
   echo -e "Would you like to block connections with a client?\n"
   echo -e "Enter y or n: "
   read yn

    if [ "$yn" == "y" ]; then

      echo -e "\nEnter Ip Address to Block: \n"
      read ip

                if [ -n $ip ]; then

                        echo -e "\nNow retrieving mac address to block...\n"
                        ping -c 1 $ip > /dev/null
                        mac=`arp $ip | grep ether | awk '{ print $3 }'`

                        if [ -z $mac ]; then
                                clear
                                echo -e "\n***Client does not exist or is no longer\
                                         on this network***"
                                echo -e "\nSkipping action and resuming monitoring.\n\n"
                                sleep 2
                                bash leecher.sh
                                exit 0

                        else
                                iptables -A INPUT -m mac --mac-source $mac -j DROP
                                clear
                                echo -e "\nClient with mac address $mac is now\
                                          blocked.\n"
                                echo -e "We will continue monitoring for changes\
                                         in clients\n\n"
                                sleep 2
                                bash leecher.sh
                                exit 0
                        fi
                fi


    else
          clear
          echo -e "\n\nLeecher has exited\n\n"
          setterm -cursor on
          rm -f $pid
          exit 0
    fi
}

# Print the scan from the engine()
twice(){
  g=0
  len=${#second[@]}
  for (( g = 0; g < $len; g++ ));
  do
       echo -e "${second[$g]}\n"
  done
}

# If there's a change in the network, ask to block ips.
interupt(){
   clear
   echo -e "\nList of Clients has Changed!\n"
   twice
   echo -e '\a'
   echo -e "Would you like to block connections with a client?\n"
   echo -e "Enter y or n: "
   read yn

   if [ "$yn" == "y" ]; then

      echo -e "\nEnter Ip Address to Block: \n"
      read ip
                if [ -n $ip ]; then
                        ping -c 1 $ip > /dev/null
                        mac=`arp $ip | grep ether | awk '{ print $3 }'`

                        if [ -z $mac ]; then
                                clear
                                echo -e "\n***Client does not exist or is no longer on\
                                         this network***"
                                echo -e "\nSkipping action and resuming monitoring.\n\n"
                        else
                                iptables -A INPUT -m mac --mac-source $mac -j DROP
                                clear
                                echo -e "\nClient with mac address $mac is now blocked.\n"
                                echo -e "We will continue monitoring for changes\
                                         in clients\n\n"
                                echo -e "Current clients are: \n"
                                twice
                                echo -e "\nResuming monitoring..."
                        fi
                fi
    else
           clear
           echo -e "Current clients are: \n"
           twice
           echo -e "Resuming monitoring..."
    fi
}

# Function to keep monitoring for any changes
engine()
{
        # Scan networks again for comparison of changes.
        for subnet in $(/sbin/ifconfig | awk '/inet addr/ && !/127.0.0.1/ && !a[$2]++\
                        {print substr($2,6)}')
        do
                  second+=( "$(nmap -sP ${subnet%.*}.0/24 | awk 'index(__g5_token5e85b9740349f,t)\
                  { print $i }' t="$t" i="$i" )" )
                  sleep 1
        done
}

# Make sure user is logged in as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

# Check if nmap is installed
ifnmap=`type -p nmap`
        if [ -z $ifnmap ]; then

                echo -e "\n\nNmap must be installed for this program to work\n"
                echo -e "Only Nmap 5.00 and 5.21 are supported at this time\n"
                echo -e "Please install and try again"
                exit 0
        fi

clear
echo -e "\nNow finding clients on your local network(s)"
echo -e "Press Control-C at any time to block additional clients or exit\n"


# Remove temp files on exit and allow Control-C to exit.
trap control_c SIGINT

# Turn off cursor
setterm -cursor off

# Make some arrays and variables
declare -a first
declare -a second
sid=5.21

# Check for which version of nmap
if [ 5.21 = $(nmap --version | awk '/Nmap/ { print $3 }') ]; then
    i=5  t=report
else
    i=2  t=Host
fi

# Get ip's from interfaces and run the first scan
for subnet in $(/sbin/ifconfig | awk '/inet addr/ && !/127.0.0.1/ && !a[$2]++ {print \
                substr($2,6)}')
do
          first+=( "$(nmap -sP ${subnet%.*}.0/24 | awk 'index(__g5_token5e85b9740349f,t) { print $i }' \
                  t="$t" i="$i" )" )
          sleep 1
done

                echo -e "Current clients are: \n"

                        #Display array elements and add new lines
                        e=0
                        len=${#first[@]}
                        for (( e = 0; e < $len; e++ ));
                        do
                                echo -e "${first[$e]}\n"
                        done

                echo -e "Leecher is now monitoring for new clients."
                echo -e "\nAny changes with clients will be reported by the system bell."
                echo -e "If bell is not enabled details will log to this console."

# Forever loop to keep monitoring constant
for ((  ;  ; ))
do
        engine

        if [[ ${first[@]} == ${second[@]} ]]; then

                second=( )
        else
                interupt
                sleep 1
                first=( )
                first=("${second[@]}")
                second=( )
        fi

done