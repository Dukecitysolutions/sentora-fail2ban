#!/usr/bin/env bash

echo ""
echo "############################################################"
echo "#  Fail2Ban for Sentora 1.0.0 or 1.0.3  #"
echo "############################################################"

echo -e "\nChecking that minimal requirements are ok"

# Ensure the OS is compatible with the launcher
if [ -f /etc/centos-release ]; then
   OS="CentOs"
   VERFULL=$(sed 's/^.*release //;s/ (Fin.*$//' /etc/centos-release)
   VER=${VERFULL:0:1} # return 6 or 7
elif [ -f /etc/lsb-release ]; then
   OS=$(grep DISTRIB_ID /etc/lsb-release | sed 's/^.*=//')
   VER=$(grep DISTRIB_RELEASE /etc/lsb-release | sed 's/^.*=//')
else
   OS=$(uname -s)
   VER=$(uname -r)
fi
ARCH=$(uname -m)

echo "Detected : $OS  $VER  $ARCH"

if [[ "$OS" = "CentOs" && ("$VER" = "6" || "$VER" = "7" ) ]] ; then
   echo "Ok."
else
   echo "Sorry, this OS is not supported."
   exit 1
fi

## Disable Firewalld 
systemctl stop firewalld
systemctl mask firewalld

## Install other services needed
yum install unzip
yum install wget

## Install iptables and enable services
yum install iptables-services
systemctl enable iptables

## Setup iptable default Sentora Ports
iptables -A INPUT -i lo -j ACCEPT
iptables -A INPUT -p tcp -m tcp --dport 21 -j ACCEPT
iptables -A INPUT -p tcp -m tcp --dport 80 -j ACCEPT
iptables -A INPUT -p tcp -m tcp --dport 443 -j ACCEPT
iptables -A INPUT -p tcp -m tcp --dport 25 -j ACCEPT
iptables -A INPUT -p tcp -m tcp --dport 465 -j ACCEPT
iptables -A INPUT -p tcp -m tcp --dport 110 -j ACCEPT
iptables -A INPUT -p tcp -m tcp --dport 995 -j ACCEPT
iptables -A INPUT -p tcp -m tcp --dport 143 -j ACCEPT
iptables -A INPUT -p tcp -m tcp --dport 993 -j ACCEPT
service iptables save

## Install Fail2ban 
yum install fail2ban

## Make Fail2ban Module folder in Sentora modules
mkdir /etc/sentora/panel/modules/fail2ban
cd /etc/sentora/panel/modules/fail2ban

## Disabled for now
wget -O sentora-fail2ban.zip http://zppy-repo.dukecitysolutions.com/repo/fail2ban/sentora-fail2ban.zip
unzip sentora-fail2ban.zip
cp -f /etc/sentora/panel/modules/fail2ban/sentora-fail2ban/filter.d/*.conf /etc/fail2ban/filter.d/
cp -f /etc/sentora/panel/modules/fail2ban/sentora-fail2ban/config/centos.jail.local /etc/fail2ban/
mv /etc/fail2ban/centos.jail.local /etc/fail2ban/jail.local
chmod 777 /etc/fail2ban/jail.local

## Add fail2ban to cron - Not sure what this does yet
#cp -f /etc/sentora/panel/modules/fail2ban/sentora-fail2ban-centos /etc/cron.daily/

## Check fail2ban Config and start iptables
chkconfig --level 23 fail2ban on
systemctl start iptables
systemctl restart fail2ban