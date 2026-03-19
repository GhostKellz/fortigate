# FortiGate CLI Cheatsheet

Quick reference for FortiOS CLI commands.

---

## Navigation & Basics

```bash
# Get help
?                           # Show available commands
command ?                   # Show options for command

# Tab completion
<Tab>                       # Auto-complete command

# Show vs Get vs Diagnose
show                        # Display configuration
get                         # Display status/info
diagnose                    # Debug/diagnostic commands
execute                     # Run operations
config                      # Enter configuration mode

# Tree navigation
config system interface     # Enter config context
    edit "wan1"            # Edit specific item
    set status up          # Set value
    next                   # Save and move to next
    end                    # Exit config context

# Abort changes
abort                       # Discard changes and exit

# Search in config
show | grep -i "pattern"
show full-configuration | grep -f "pattern"
```

---

## System

```bash
# Status
get system status
get system performance status
get system performance top
get system performance top 20 1    # Top 20, 1 iteration

# Hardware/model info
get hardware nic
get hardware memory
get hardware cpu

# Hostname/DNS
config system global
    set hostname "FW-01"
    set timezone "America/Los_Angeles"
end

config system dns
    set primary 8.8.8.8
    set secondary 1.1.1.1
end

# NTP
config system ntp
    set ntpsync enable
    set type custom
    config ntpserver
        edit 1
            set server "pool.ntp.org"
        next
    end
end

# Date/time
execute date                # Show date
execute time                # Show time
execute date 2024-06-15     # Set date
execute time 14:30:00       # Set time

# Uptime
get system performance status | grep Uptime

# Shutdown/reboot
execute shutdown
execute reboot

# Factory reset
execute factoryreset
execute factoryreset keepvmlicense   # Keep VM license
```

---

## Interfaces

```bash
# View
get system interface
get system interface physical
show system interface
diagnose hardware deviceinfo nic wan1

# Status
get system interface | grep wan1
diagnose netlink interface list wan1

# Configure
config system interface
    edit "wan1"
        set mode static
        set ip 192.168.1.10 255.255.255.0
        set allowaccess ping https ssh
        set alias "Primary-WAN"
        set description "ISP Connection"
        set status up
    next
    edit "lan"
        set mode static
        set ip 10.0.0.1 255.255.255.0
        set allowaccess ping https ssh http
        set device-identification enable
    next
end

# DHCP mode
config system interface
    edit "wan1"
        set mode dhcp
    next
end

# PPPoE
config system interface
    edit "wan1"
        set mode pppoe
        set username "user@isp.com"
        set password "password"
    next
end

# VLAN
config system interface
    edit "vlan100"
        set vdom "root"
        set interface "lan"
        set vlanid 100
        set ip 10.100.0.1 255.255.255.0
    next
end

# LAG/Aggregate
config system interface
    edit "agg1"
        set type aggregate
        set member "port1" "port2"
        set lacp-mode active
    next
end

# Zone
config system zone
    edit "LAN-Zone"
        set interface "lan" "vlan100" "vlan200"
    next
end

# Bring up/down
config system interface
    edit "wan1"
        set status down   # or up
    next
end
```

---

## Routing

```bash
# View routing table
get router info routing-table all
get router info routing-table details
get router info routing-table database
get router info routing-table static

# View config
show router static

# Static routes
config router static
    edit 1
        set dst 0.0.0.0/0
        set gateway 192.168.1.1
        set device "wan1"
        set distance 10
        set weight 1
        set priority 0
        set comment "Default via WAN1"
    next
    edit 2
        set dst 10.0.0.0/8
        set device "vpn-tunnel"
        set distance 10
    next
    edit 3
        set dst 192.168.99.0/24
        set blackhole enable
        set comment "Null route"
    next
end

# Policy routes
config router policy
    edit 1
        set input-device "lan"
        set src "192.168.1.100/32"
        set dst "0.0.0.0/0"
        set output-device "wan2"
        set gateway 10.0.0.1
    next
end

# ECMP
config system settings
    set v4-ecmp-mode source-ip-based    # or weight-based, usage-based
end

# RIP
config router rip
    set default-information-originate enable
    config interface
        edit "internal"
            set send-version 2
            set receive-version 2
        next
    end
    config network
        edit 1
            set prefix 192.168.0.0/16
        next
    end
end

# OSPF
config router ospf
    set router-id 1.1.1.1
    config area
        edit 0.0.0.0
        next
    end
    config network
        edit 1
            set prefix 192.168.0.0/16
        next
    end
    config ospf-interface
        edit "lan"
            set interface "lan"
            set cost 10
        next
    end
end

# BGP
config router bgp
    set as 65001
    set router-id 1.1.1.1
    config neighbor
        edit "192.168.1.2"
            set remote-as 65002
        next
    end
    config network
        edit 1
            set prefix 10.0.0.0/24
        next
    end
end

# Route diagnostics
diagnose ip route list
diagnose ip rtcache list
execute router clear bgp all
```

---

## Firewall Policies

```bash
# View
show firewall policy
get firewall policy
get firewall policy 1       # Specific policy

# Quick view
diagnose firewall policy list

# Create policy
config firewall policy
    edit 0                   # 0 = create new
        set name "Allow-LAN-Internet"
        set srcintf "lan"
        set dstintf "wan1"
        set srcaddr "all"
        set dstaddr "all"
        set action accept
        set schedule "always"
        set service "ALL"
        set nat enable
        set logtraffic all
        set comments "Allow LAN to Internet"
    next
end

# Policy with profiles
config firewall policy
    edit 0
        set name "Secure-Browsing"
        set srcintf "lan"
        set dstintf "wan1"
        set srcaddr "all"
        set dstaddr "all"
        set action accept
        set schedule "always"
        set service "HTTP" "HTTPS" "DNS"
        set utm-status enable
        set ssl-ssh-profile "certificate-inspection"
        set av-profile "default"
        set webfilter-profile "default"
        set ips-sensor "default"
        set application-list "default"
        set nat enable
        set logtraffic all
    next
end

# Deny policy
config firewall policy
    edit 0
        set name "Block-BadTraffic"
        set srcintf "any"
        set dstintf "any"
        set srcaddr "Blocked-IPs"
        set dstaddr "all"
        set action deny
        set schedule "always"
        set service "ALL"
        set logtraffic all
    next
end

# Move policy
config firewall policy
    move 10 before 5
    move 10 after 3
end

# Delete policy
config firewall policy
    delete 10
end

# Clone (show then recreate)
show firewall policy 5

# Policy hit count
get firewall policy | grep hit
diagnose firewall iprope list 100004
```

---

## Address Objects

```bash
# View
show firewall address
get firewall address

# Subnet
config firewall address
    edit "LAN-Network"
        set type ipmask
        set subnet 192.168.1.0 255.255.255.0
    next
end

# Single host
config firewall address
    edit "Server-01"
        set subnet 10.0.0.50 255.255.255.255
    next
end

# Range
config firewall address
    edit "DHCP-Range"
        set type iprange
        set start-ip 192.168.1.100
        set end-ip 192.168.1.200
    next
end

# FQDN
config firewall address
    edit "Google"
        set type fqdn
        set fqdn "google.com"
    next
end

# Wildcard FQDN
config firewall address
    edit "All-Google"
        set type fqdn
        set fqdn "*.google.com"
    next
end

# Geography
config firewall address
    edit "Block-Country"
        set type geography
        set country "RU" "CN" "KP"
    next
end

# MAC address
config firewall address
    edit "Admin-Laptop"
        set type mac
        set macaddr 00:11:22:33:44:55
    next
end

# Address group
config firewall addrgrp
    edit "Internal-Servers"
        set member "Server-01" "Server-02" "Server-03"
    next
end

# Dynamic address (FortiClient EMS)
config firewall address
    edit "EMS-High-Risk"
        set type dynamic
        set sdn "ems"
        set filter "EMS_TAG=high_risk"
    next
end
```

---

## Services

```bash
# View
show firewall service custom
get firewall service custom

# Custom TCP
config firewall service custom
    edit "Custom-8080"
        set tcp-portrange 8080
    next
end

# TCP range
config firewall service custom
    edit "High-Ports"
        set tcp-portrange 8000-9000
    next
end

# UDP
config firewall service custom
    edit "Custom-UDP"
        set udp-portrange 5000-5100
    next
end

# TCP + UDP
config firewall service custom
    edit "DNS-Custom"
        set tcp-portrange 53
        set udp-portrange 53
    next
end

# ICMP
config firewall service custom
    edit "Ping"
        set protocol ICMP
        set icmptype 8
    next
end

# IP protocol
config firewall service custom
    edit "GRE"
        set protocol IP
        set protocol-number 47
    next
end

# Service group
config firewall service group
    edit "Web-Services"
        set member "HTTP" "HTTPS" "Custom-8080"
    next
end
```

---

## NAT

```bash
# Source NAT (in policy)
config firewall policy
    edit 1
        set nat enable
        set ippool enable
        set poolname "External-Pool"
    next
end

# IP Pool (SNAT)
config firewall ippool
    edit "External-Pool"
        set startip 203.0.113.10
        set endip 203.0.113.20
        set type overload           # PAT
    next
    edit "One-to-One-Pool"
        set startip 203.0.113.30
        set endip 203.0.113.30
        set type one-to-one
    next
end

# Destination NAT (VIP)
config firewall vip
    edit "Web-Server-VIP"
        set extip 203.0.113.100
        set mappedip 10.0.0.50
        set extintf "wan1"
        set portforward enable
        set extport 443
        set mappedport 443
    next
end

# VIP - Port range
config firewall vip
    edit "App-Server"
        set extip 203.0.113.101
        set mappedip 10.0.0.60
        set extintf "wan1"
        set portforward enable
        set extport 8000-8100
        set mappedport 8000-8100
    next
end

# VIP - Multiple ports
config firewall vip
    edit "Multi-Port-Server"
        set extip 203.0.113.102
        set mappedip 10.0.0.70
        set extintf "wan1"
        set portforward enable
        config realservers
            edit 1
                set port 80
            next
            edit 2
                set port 443
            next
        end
    next
end

# VIP Group
config firewall vipgrp
    edit "All-VIPs"
        set interface "wan1"
        set member "Web-Server-VIP" "App-Server"
    next
end

# Central NAT
config firewall central-snat-map
    edit 1
        set srcintf "lan"
        set dstintf "wan1"
        set orig-addr "all"
        set dst-addr "all"
        set nat-ippool "External-Pool"
    next
end
```

---

## VPN - IPsec

```bash
# View
get vpn ipsec tunnel summary
diagnose vpn ike gateway list
diagnose vpn tunnel list
show vpn ipsec phase1-interface
show vpn ipsec phase2-interface

# Phase 1 (IKE)
config vpn ipsec phase1-interface
    edit "Site-B-VPN"
        set type static
        set interface "wan1"
        set peertype any
        set remote-gw 203.0.113.200
        set psksecret "YourPreSharedKey"
        set ike-version 2
        set proposal aes256-sha256 aes256gcm-prfsha256
        set dpd on-idle
        set dpd-retrycount 3
        set dpd-retryinterval 10
    next
end

# Phase 2 (IPsec SA)
config vpn ipsec phase2-interface
    edit "Site-B-Phase2"
        set phase1name "Site-B-VPN"
        set proposal aes256-sha256 aes256gcm
        set pfs enable
        set dhgrp 14 5
        set replay enable
        set auto-negotiate enable
        set src-subnet 192.168.1.0 255.255.255.0
        set dst-subnet 10.10.0.0 255.255.255.0
    next
end

# VPN route
config router static
    edit 100
        set dst 10.10.0.0/24
        set device "Site-B-VPN"
    next
end

# VPN firewall policy
config firewall policy
    edit 0
        set name "VPN-Inbound"
        set srcintf "Site-B-VPN"
        set dstintf "lan"
        set srcaddr "Site-B-Network"
        set dstaddr "LAN-Network"
        set action accept
        set schedule "always"
        set service "ALL"
    next
    edit 0
        set name "VPN-Outbound"
        set srcintf "lan"
        set dstintf "Site-B-VPN"
        set srcaddr "LAN-Network"
        set dstaddr "Site-B-Network"
        set action accept
        set schedule "always"
        set service "ALL"
    next
end

# Bring tunnel up/down
diagnose vpn ike gateway flush name "Site-B-VPN"
diagnose vpn tunnel up Site-B-VPN
diagnose vpn tunnel down Site-B-VPN

# Debug
diagnose debug application ike -1
diagnose debug enable
# Stop: diagnose debug disable
```

---

## VPN - SSL

```bash
# View
get vpn ssl monitor
diagnose vpn ssl list

# SSL VPN settings
config vpn ssl settings
    set servercert "Fortinet_SSL"
    set tunnel-ip-pools "SSL-VPN-Pool"
    set port 443
    set source-interface "wan1"
    set source-address "all"
    set default-portal "full-access"
    set dns-suffix "company.local"
    set dns-server1 10.0.0.2
    set wins-server1 10.0.0.2
end

# IP Pool for SSL VPN
config firewall address
    edit "SSL-VPN-Pool"
        set type iprange
        set start-ip 10.212.134.1
        set end-ip 10.212.134.254
    next
end

# Portal
config vpn ssl web portal
    edit "full-access"
        set tunnel-mode enable
        set ip-pools "SSL-VPN-Pool"
        set split-tunneling disable
    next
    edit "web-only"
        set tunnel-mode disable
        set web-mode enable
    next
end

# User group mapping
config vpn ssl web user-group-bookmark
end

# SSL VPN policy
config firewall policy
    edit 0
        set name "SSL-VPN-Access"
        set srcintf "ssl.root"
        set dstintf "lan"
        set srcaddr "SSL-VPN-Pool"
        set dstaddr "LAN-Network"
        set action accept
        set schedule "always"
        set service "ALL"
        set groups "SSL-VPN-Users"
    next
end
```

---

## Users & Authentication

```bash
# Local users
config user local
    edit "admin-user"
        set type password
        set passwd "SecurePassword123"
        set email-to "user@company.com"
        set two-factor fortitoken
    next
end

# User groups
config user group
    edit "VPN-Users"
        set member "user1" "user2" "user3"
    next
    edit "Admins"
        set member "admin-user"
    next
end

# LDAP
config user ldap
    edit "AD-Server"
        set server "10.0.0.10"
        set cnid "sAMAccountName"
        set dn "DC=company,DC=local"
        set type regular
        set username "CN=ldapbind,OU=Service Accounts,DC=company,DC=local"
        set password "LDAPBindPassword"
        set secure ldaps
    next
end

# RADIUS
config user radius
    edit "RADIUS-Server"
        set server "10.0.0.11"
        set secret "RadiusSecret"
        set auth-type auto
    next
end

# LDAP group
config user group
    edit "AD-VPN-Users"
        set member "AD-Server"
        config match
            edit 1
                set server-name "AD-Server"
                set group-name "CN=VPN-Users,OU=Groups,DC=company,DC=local"
            next
        end
    next
end

# Admin accounts
config system admin
    edit "backup-admin"
        set accprofile "super_admin"
        set password "AdminPassword"
        set trusthost1 10.0.0.0/24
        set two-factor fortitoken
    next
end

# Admin profiles
config system accprofile
    edit "ReadOnly"
        set secfabgrp read
        set ftviewgrp read
        set authgrp read
        set sysgrp read
        set netgrp read
        set loggrp read
        set fwgrp read
        set vpngrp read
        set utmgrp read
        set wanoptgrp read
    next
end
```

---

## DHCP

```bash
# View
show system dhcp server
diagnose ip dhcp server list

# DHCP server
config system dhcp server
    edit 1
        set interface "lan"
        set default-gateway 192.168.1.1
        set netmask 255.255.255.0
        set dns-server1 8.8.8.8
        set dns-server2 8.8.4.4
        set ntp-server1 pool.ntp.org
        set domain "company.local"
        set lease-time 86400
        config ip-range
            edit 1
                set start-ip 192.168.1.100
                set end-ip 192.168.1.200
            next
        end
        config reserved-address
            edit 1
                set ip 192.168.1.50
                set mac 00:11:22:33:44:55
                set description "Printer"
            next
        end
        config options
            edit 1
                set code 150
                set type ip
                set ip "10.0.0.100"    # TFTP for phones
            next
        end
    next
end

# DHCP relay
config system dhcp server
    edit 2
        set interface "vlan100"
        set type relay
        set server-type regular
        set relay-agent "10.0.0.50"
    next
end

# View leases
execute dhcp lease-list
```

---

## DNS

```bash
# System DNS
config system dns
    set primary 8.8.8.8
    set secondary 1.1.1.1
    set domain "company.local"
end

# DNS server (local)
config system dns-server
    edit "lan"
        set mode recursive
    next
end

# DNS database (local records)
config system dns-database
    edit "company.local"
        set domain "company.local"
        set type master
        set ttl 300
        set authoritative enable
        config dns-entry
            edit 1
                set hostname "server1"
                set type A
                set ip 10.0.0.50
            next
            edit 2
                set hostname "mail"
                set type MX
                set ip 10.0.0.60
                set preference 10
            next
        end
    next
end

# Split DNS
config system dns
    config server-hostname
        edit 1
            set hostname "internal.company.com"
            set ip 10.0.0.10
        next
    end
end
```

---

## Sessions & Traffic

```bash
# Session table
get system session list
get system session status

# Session filter
diagnose sys session filter clear
diagnose sys session filter src 192.168.1.100
diagnose sys session filter dst 8.8.8.8
diagnose sys session filter dport 443
diagnose sys session filter proto 6     # TCP
diagnose sys session filter policy 5
diagnose sys session list

# Clear sessions
diagnose sys session clear
diagnose sys session filter src 192.168.1.100
diagnose sys session clear

# Packet sniffer
diagnose sniffer packet any "host 192.168.1.100" 4 0 l
diagnose sniffer packet wan1 "port 443" 4 100
diagnose sniffer packet any "host 192.168.1.100 and port 80" 4 0 a
diagnose sniffer packet any "icmp" 4 0 l

# Sniffer verbosity
# 1 = headers only
# 2 = headers + first 32 bytes
# 3 = headers + full packet hex
# 4 = headers + interface name
# 5 = headers + interface name + hex
# 6 = headers + interface name + full packet hex

# Flow debug
diagnose debug enable
diagnose debug flow filter addr 192.168.1.100
diagnose debug flow filter port 443
diagnose debug flow trace start 100
# Watch output...
diagnose debug flow trace stop
diagnose debug disable
```

---

## Logging

```bash
# Log settings
config log setting
    set brief-traffic-format enable
    set log-invalid-packet enable
    set local-in-allow enable
    set local-in-deny-unicast enable
    set local-out enable
end

# Memory logging
config log memory setting
    set status enable
    set diskfull overwrite
end

# Disk logging
config log disk setting
    set status enable
    set diskfull overwrite
    set max-log-file-size 100
    set storage internal
end

# Syslog
config log syslogd setting
    set status enable
    set server "10.0.0.100"
    set port 514
    set facility local7
    set format rfc5424
end

# FortiAnalyzer
config log fortianalyzer setting
    set status enable
    set server "10.0.0.200"
    set serial "FL-2000D-123456"
    set upload-option realtime
end

# View logs
execute log filter category traffic
execute log filter field action deny
execute log display

# Clear logs
execute log delete-all
execute log delete category event

# Log fields
execute log filter field srcip 192.168.1.100
execute log filter field dstip 8.8.8.8
execute log filter field action block
execute log filter field service HTTPS
```

---

## High Availability

```bash
# View HA status
get system ha status
diagnose sys ha status
diagnose sys ha checksum cluster

# HA config (A-P)
config system ha
    set mode a-p                    # or a-a
    set group-name "FW-Cluster"
    set group-id 1
    set password "HAPassword"
    set priority 200                # Higher = primary
    set hbdev "ha1" 50 "ha2" 100
    set session-pickup enable
    set session-pickup-connectionless enable
    set session-pickup-delay enable
    set override disable
    set monitor "wan1" "wan2" "lan"
end

# HA heartbeat interfaces
config system interface
    edit "ha1"
        set ip 10.255.1.1 255.255.255.0
    next
    edit "ha2"
        set ip 10.255.2.1 255.255.255.0
    next
end

# Force failover
diagnose sys ha reset-uptime

# Sync status
diagnose sys ha checksum cluster

# Exec on secondary
execute ha manage 1 admin
execute ha sync start
execute ha sync stop
```

---

## Backup & Firmware

```bash
# Backup config
execute backup config tftp <filename> <tftp-server>
execute backup config ftp <filename> <ftp-server>
execute backup config usb <filename>
execute backup full-config tftp <filename> <tftp-server>

# Restore config
execute restore config tftp <filename> <tftp-server>
execute restore config ftp <filename> <ftp-server>
execute restore config usb <filename>

# Firmware
get system status                    # Current version
execute restore image tftp <filename> <tftp-server>
execute restore image ftp <filename> <ftp-server>
execute restore image usb <filename>

# Dual partition
diagnose sys flash list
execute set-next-reboot secondary
execute reboot
```

---

## Diagnostics & Debug

```bash
# Network tests
execute ping 8.8.8.8
execute ping-options source 192.168.1.1
execute traceroute 8.8.8.8
execute telnet 10.0.0.1 443

# ARP
get system arp
diagnose ip arp list
execute clear system arp table

# DNS
execute nslookup name google.com server 8.8.8.8
diagnose dns list

# CPU/Memory
get system performance status
get system performance top
diagnose sys top

# Hardware
fnsysctl cat /proc/cpuinfo
fnsysctl cat /proc/meminfo
diagnose hardware deviceinfo nic wan1

# Crash logs
diagnose debug crashlog read

# General debug
diagnose debug enable
diagnose debug console timestamp enable
diagnose debug application <app> -1
# Stop
diagnose debug disable
diagnose debug reset

# Common debug apps
# ike - IPsec VPN
# sslvpnd - SSL VPN
# httpsd - HTTP/admin
# fgfmd - FortiManager
# autod - Automation
# hatalk - HA
# wad - Web proxy
# dnsproxy - DNS
```

---

## Useful One-Liners

```bash
# What policy is traffic matching?
diagnose debug flow filter addr 192.168.1.100
diagnose debug flow trace start 10

# Why is IPsec down?
diagnose vpn ike gateway list

# Active SSL VPN users
get vpn ssl monitor

# Who's using bandwidth?
diagnose sys session stat

# Check interface errors
diagnose netlink interface list wan1

# Force route refresh
execute router clear
get router info routing-table all

# Clear all sessions for an IP
diagnose sys session filter src 192.168.1.100
diagnose sys session clear

# Quick performance check
get system performance status

# Show running config
show full-configuration

# Diff current vs startup
diagnose sys config diff

# Test external connectivity
execute ping-options source wan1
execute ping 8.8.8.8
```

---

## Common Log IDs

| Log ID | Event |
|--------|-------|
| 0000000001 | Traffic log |
| 0100032001 | Admin login |
| 0100032002 | Admin logout |
| 0100032003 | Failed admin login |
| 0100032102 | Configuration change |
| 0419016384 | IPS alert |
| 0211008192 | AV detection |
| 0315012288 | Web filter block |
| 0101037138 | VPN tunnel up |
| 0101037139 | VPN tunnel down |
| 0100041216 | HA failover |
| 0100020480 | Interface up |
| 0100020481 | Interface down |

---

## Exit/End Commands

```bash
end                 # Exit config, save changes
abort               # Exit config, discard changes
next                # Save current item, continue editing
Ctrl+C              # Cancel current line
Ctrl+D              # Logout (if at prompt)
```
