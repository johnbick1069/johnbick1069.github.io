#!/bin/bash -e
if [[ $(id -u) -ne 0 ]]; then echo "Please run as root (e.g. sudo ./path/to/this/script)"; exit 1; fi

read -p "VPN username (same as entered on server): " VPNUSERNAME
while true; do
read -s -p "VPN password (same as entered on server): " VPNPASSWORD
echo
read -s -p "Confirm VPN password: " VPNPASSWORD2
echo
[ "$VPNPASSWORD" = "$VPNPASSWORD2" ] && break
echo "Passwords didn't match -- please try again"
done

apt-get install -y strongswan libstrongswan-standard-plugins libcharon-extra-plugins
apt-get install -y libcharon-standard-plugins || true  # 17.04+ only

ln -f -s /etc/ssl/certs/DST_Root_CA_X3.pem /etc/ipsec.d/cacerts/

grep -Fq 'jawj/IKEv2-setup' /etc/ipsec.conf || echo "
# https://github.com/jawj/IKEv2-setup
conn ikev2vpn
        ikelifetime=60m
        keylife=20m
        rekeymargin=3m
        keyingtries=1
        keyexchange=ikev2
        ike=aes256gcm16-sha256-ecp521!
        esp=aes256gcm16-sha256!
        leftsourceip=%config
        leftauth=eap-mschapv2
        eap_identity=${VPNUSERNAME}
        right=micou.top
        rightauth=pubkey
        rightid=@micou.top
        rightsubnet=0.0.0.0/0
        auto=add  # or auto=start to bring up automatically
" >> /etc/ipsec.conf

grep -Fq 'jawj/IKEv2-setup' /etc/ipsec.secrets || echo "
# https://github.com/jawj/IKEv2-setup
${VPNUSERNAME} %any : EAP \"${VPNPASSWORD}\"
" >> /etc/ipsec.secrets

ipsec restart
sleep 5  # is there a better way?

echo "Bringing up VPN ..."
ipsec up ikev2vpn
ipsec statusall

echo
echo -n "Testing IP address ... "
VPNIP=$(dig -4 +short micou.top)
ACTUALIP=$(curl -s ifconfig.co)
if [[ "$VPNIP" == "$ACTUALIP" ]]; then echo "PASSED (IP: ${VPNIP})"; else echo "FAILED (IP: ${ACTUALIP}, VPN IP: ${VPNIP})"; fi

echo
echo "To disconnect: ipsec down ikev2vpn"
echo "To resconnect: ipsec up ikev2vpn"
echo "To connect automatically: change auto=add to auto=start in /etc/ipsec.conf"
