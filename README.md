# Privatedns
Project to setup an ad-blocking, DoT DNS server with openvpnclient and gateway fw rules.
This project was built using a Debian OS and assumes that the host to be managed are running at least:
* apt
* iptables
* System-D
To be on the safe side, use a Debian like system running System-D!
Some parts of this project needs to be configured by you the user before use! Look through the group_vars folder and files and fill in configuration correctly. For sensetive information Ansible Vault is recommended! Also there are som vars folders where you can put sensitive information and override the group_vars ones if you don't want the other roles to see those variables at all.

# Parts covered
This project is structured in such a way that the four main points can be implemented sepparatly from each other.
The parts that this project provides are the following:
* Ad-blocking DNS server using the Pi-hole server found over at https://pi-hole.net 
* DoT stub DNS server found over at https://dnsprivacy.org/wiki/display/DP/DNS+Privacy+Daemon+-+Stubby
* OpenVPN client setup using OpenVPN found over at https://openvpn.net/

## Pi-hole
Pi-hole is a DNS service that provide blocklists that are maintaned by the community. You can add your own list source, or blacklist/whitelist domains as you please. Pi-hole can gather a lot of statistics as well if that is something wanted. For the vpn-gateway part of this to work, you need to specifiy your vpn-gatewat as the standard gateway in your dhcp server. Pi-hole comes equiped with an able DHCP server which will allow you to do this. In the default configuration Pi-hole is configured to use a local instance of Stubby as upstream DNS provider.

## Stubby
Stubbt provides DNS over TLS (DoT) support. In this project Stubby is preconfigured to use Cloudflare (1.1.1.1) DNS as upstream DNS provider. And to deliver information down over standard DNS (UDP port 53) only to localhost.

## OpenVPN
The OpenVPN client installation needs to be correctly configured. But that is outside of the scope of this project. If you which to use the VPN abilities (including the gateway) you need to know what files to reconfigure in the openvpnclient part of this project to match you providers configuration.

## Gateway
The Gateway setsup iptables rules to forward all traffic from the local network into a vpn-tunnel. It will allow DNS to 1.1.1.1 and 1.0.0.1 (Cloudflare) to resolve VPN enpoints as standard. It will also allow all localhost and local net traffic. It will however block all traffic trying to go from local net interface out on the internet (except what was previously specified).
