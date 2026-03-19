# FortiGate Toolkit

Scripts, configs, and reference docs for FortiGate firewalls, FortiClient deployment, SD-WAN, and more.

---

## Contents

- [FortiClient Deployment](#forticlient-deployment)
- [Firewall Policies](#firewall-policies)
- [Static Routes](#static-routes)
- [SD-WAN Configuration](#sd-wan-configuration)
- [WAN Failover](#wan-failover)
- [Threat Feeds](#threat-feeds)
- [Automation Stitches](#automation-stitches)
- [CLI Quick Reference](#cli-quick-reference)
- [Backup & Restore](#backup--restore)
- [Troubleshooting](#troubleshooting)

---

## FortiClient Deployment

### deploy.ps1

Deploys FortiClient IPsec VPN configuration via GPO startup script.

**How it works:**
1. Copies VPN XML config from network share to local machine
2. Imports config using `fcconfig.exe`
3. Creates marker file to prevent re-import on subsequent boots

**GPO Setup:**
- Create scheduled task: At startup + at login
- Program: `powershell`
- Arguments: `-ExecutionPolicy Bypass -File "\\SERVER\share\deploy.ps1"`

**Export VPN Config (from configured machine):**
```powershell
& "C:\Program Files\Fortinet\FortiClient\fcconfig.exe" -m vpn -o export -f "C:\Temp\vpn.xml" -p "YourPassword"
```

**Import VPN Config:**
```powershell
& "C:\Program Files\Fortinet\FortiClient\fcconfig.exe" -m vpn -o import -f "C:\Temp\vpn.xml" -p "YourPassword"
```

---

## Firewall Policies

### View Policies

```bash
# Show all policies
show firewall policy

# Get policy summary
get firewall policy

# Show specific policy by ID
show firewall policy 5

# Check policy hit count
diagnose firewall iprope list 100004
```

### Basic Policy Structure

```bash
config firewall policy
    edit 0
        set name "LAN-to-Internet"
        set srcintf "lan"
        set dstintf "wan1"
        set srcaddr "all"
        set dstaddr "all"
        set action accept
        set schedule "always"
        set service "ALL"
        set nat enable
        set logtraffic all
    next
end
```

### Policy with Security Profiles

```bash
config firewall policy
    edit 0
        set name "Secure-Web-Access"
        set srcintf "lan"
        set dstintf "wan1"
        set srcaddr "LAN_Subnet"
        set dstaddr "all"
        set action accept
        set schedule "always"
        set service "HTTP" "HTTPS"
        set utm-status enable
        set av-profile "default"
        set webfilter-profile "default"
        set ips-sensor "default"
        set ssl-ssh-profile "certificate-inspection"
        set nat enable
        set logtraffic all
    next
end
```

### Address Objects

```bash
# Create address object
config firewall address
    edit "Server-10.0.0.50"
        set subnet 10.0.0.50 255.255.255.255
    next
    edit "LAN_Subnet"
        set subnet 192.168.1.0 255.255.255.0
    next
    edit "Remote-Office"
        set subnet 10.10.0.0 255.255.0.0
    next
end

# Create address group
config firewall addrgrp
    edit "Internal-Servers"
        set member "Server-10.0.0.50" "Server-10.0.0.51"
    next
end

# FQDN address
config firewall address
    edit "Google-DNS"
        set type fqdn
        set fqdn "dns.google"
    next
end
```

### Service Objects

```bash
# Custom service
config firewall service custom
    edit "Custom-App-8080"
        set tcp-portrange 8080
    next
    edit "Custom-App-Range"
        set tcp-portrange 8000-8100
    next
    edit "Custom-UDP"
        set udp-portrange 5000-5100
    next
end

# Service group
config firewall service group
    edit "Web-Services"
        set member "HTTP" "HTTPS" "Custom-App-8080"
    next
end
```

### Policy Order & Management

```bash
# Move policy (order matters - first match wins)
config firewall policy
    move 10 before 5
end

# Delete policy
config firewall policy
    delete 15
end

# Clone/copy a policy (edit 0 creates new)
# First show the policy you want to copy, then recreate it
```

### Deny Policies & Logging

```bash
# Explicit deny with logging
config firewall policy
    edit 0
        set name "Block-BadStuff"
        set srcintf "wan1"
        set dstintf "lan"
        set srcaddr "Blocked-IPs"
        set dstaddr "all"
        set action deny
        set schedule "always"
        set service "ALL"
        set logtraffic all
    next
end
```

---

## Static Routes

### View Routes

```bash
# Show all routes
get router info routing-table all

# Show route details
get router info routing-table details

# Show static routes config
show router static

# Check specific route
get router info routing-table database
```

### Basic Static Routes

```bash
config router static
    # Default route via WAN1
    edit 1
        set dst 0.0.0.0/0
        set gateway 192.168.1.1
        set device "wan1"
        set distance 10
        set priority 0
    next

    # Default route via WAN2 (backup, higher distance)
    edit 2
        set dst 0.0.0.0/0
        set gateway 10.0.0.1
        set device "wan2"
        set distance 20
        set priority 0
    next

    # Route to remote network via VPN
    edit 3
        set dst 10.10.0.0/16
        set device "vpn-tunnel1"
    next

    # Blackhole route (drop traffic)
    edit 4
        set dst 192.168.99.0/24
        set blackhole enable
    next
end
```

### Routes with Link Health Monitor

```bash
# Create link monitor
config system link-monitor
    edit "WAN1-Monitor"
        set srcintf "wan1"
        set server "8.8.8.8" "1.1.1.1"
        set protocol ping
        set gateway-ip 192.168.1.1
        set interval 500
        set failtime 3
        set recoverytime 3
        set update-static-route enable
    next
end

# Static route tied to link monitor
config router static
    edit 1
        set dst 0.0.0.0/0
        set gateway 192.168.1.1
        set device "wan1"
        set link-monitor-exempt enable
    next
end
```

### Policy-Based Routing

```bash
# Force specific traffic out a specific interface
config router policy
    edit 1
        set input-device "lan"
        set src "192.168.1.100/32"
        set dst "0.0.0.0/0"
        set output-device "wan2"
        set gateway 10.0.0.1
    next
end
```

### Weighted ECMP (Load Balancing)

```bash
config router static
    edit 1
        set dst 0.0.0.0/0
        set gateway 192.168.1.1
        set device "wan1"
        set distance 10
        set weight 3    # 75% of traffic
    next
    edit 2
        set dst 0.0.0.0/0
        set gateway 10.0.0.1
        set device "wan2"
        set distance 10
        set weight 1    # 25% of traffic
    next
end

# Enable ECMP
config system settings
    set v4-ecmp-mode weight-based
end
```

---

## SD-WAN Configuration

### Basic SD-WAN Setup

```bash
# Create SD-WAN zone
config system sdwan
    set status enable
    config zone
        edit "virtual-wan-link"
        next
    end
end

# Add interfaces to SD-WAN
config system sdwan
    config members
        edit 1
            set interface "wan1"
            set gateway 192.168.1.1
            set cost 0
        next
        edit 2
            set interface "wan2"
            set gateway 10.0.0.1
            set cost 10
        next
    end
end
```

### Health Check / Performance SLA

```bash
config system sdwan
    config health-check
        edit "Google-DNS"
            set server "8.8.8.8"
            set protocol ping
            set interval 500
            set failtime 3
            set recoverytime 3
            set members 1 2
        next
        edit "Cloudflare"
            set server "1.1.1.1"
            set protocol ping
            set members 1 2
        next
        edit "HTTP-Check"
            set server "www.google.com"
            set protocol http
            set port 80
            set members 1 2
        next
    end
end
```

### SD-WAN Rules (Traffic Steering)

```bash
config system sdwan
    config service
        edit 1
            set name "Critical-Apps"
            set mode priority
            set dst "all"
            set src "all"
            set priority-members 1 2
            set health-check "Google-DNS"
        next
        edit 2
            set name "VoIP-Traffic"
            set mode sla
            set dst "all"
            set internet-service enable
            set internet-service-app-ctrl 16354 16355  # MS Teams, Zoom
            config sla
                edit "Google-DNS"
                    set latency-threshold 100
                    set jitter-threshold 20
                    set packetloss-threshold 1
                next
            end
            set priority-members 1
        next
        edit 3
            set name "Bulk-Downloads"
            set mode load-balance
            set dst "all"
            set internet-service enable
            set internet-service-app-ctrl 33182  # Downloads
            set priority-members 1 2
        next
    end
end
```

### Monitor SD-WAN Status

```bash
diagnose sys sdwan health-check
diagnose sys sdwan member
diagnose sys sdwan service
diagnose sys sdwan intf-sla-log
get router info routing-table all
```

---

## WAN Failover

### Simple Link Monitor Failover (Non-SD-WAN)

For basic active/standby WAN failover without full SD-WAN:

```bash
# Create link monitors for each WAN
config system link-monitor
    edit "WAN1-Failover"
        set srcintf "wan1"
        set server "8.8.8.8" "1.1.1.1"
        set protocol ping
        set gateway-ip 192.168.1.1
        set interval 500
        set failtime 3
        set recoverytime 3
        set update-static-route enable
    next
    edit "WAN2-Failover"
        set srcintf "wan2"
        set server "8.8.8.8" "1.1.1.1"
        set protocol ping
        set gateway-ip 10.0.0.1
        set interval 500
        set failtime 3
        set recoverytime 3
        set update-static-route enable
    next
end

# Static routes with distance (lower = preferred)
config router static
    edit 1
        set dst 0.0.0.0/0
        set gateway 192.168.1.1
        set device "wan1"
        set distance 10
    next
    edit 2
        set dst 0.0.0.0/0
        set gateway 10.0.0.1
        set device "wan2"
        set distance 20
    next
end
```

### SD-WAN Failover (Recommended)

```bash
config system sdwan
    set status enable

    config members
        edit 1
            set interface "wan1"
            set gateway 192.168.1.1
            set priority 0
        next
        edit 2
            set interface "wan2"
            set gateway 10.0.0.1
            set priority 10
        next
    end

    config health-check
        edit "Failover-Check"
            set server "8.8.8.8" "1.1.1.1"
            set protocol ping
            set interval 500
            set failtime 3
            set recoverytime 3
            set members 1 2
        next
    end

    config service
        edit 1
            set name "Primary-WAN1-Failover-WAN2"
            set mode priority
            set dst "all"
            set src "all"
            set health-check "Failover-Check"
            set priority-members 1 2
        next
    end
end
```

### Monitor Failover Status

```bash
# Check link monitor status
diagnose sys link-monitor interface

# Check which WAN is active
get router info routing-table all

# SD-WAN member status
diagnose sys sdwan member

# Real-time failover events
diagnose sys sdwan health-check

# Check failover history in logs
execute log filter category event
execute log filter field msg "link-monitor"
execute log display
```

### Session Handling on Failover

```bash
# Enable session pickup on failover (keeps connections alive)
config system ha
    set session-pickup enable
end

# Or for SD-WAN, sessions re-establish automatically
# Check active sessions
diagnose sys session list
```

---

## Threat Feeds

External threat intelligence feeds for blocking malicious IPs, domains, and URLs.

### External IP Block List

```bash
# Create external threat feed connector
config system external-resource
    edit "Malicious-IPs"
        set type address
        set resource "https://example.com/threat-feed/malicious-ips.txt"
        set refresh-rate 60
    next
    edit "TOR-Exit-Nodes"
        set type address
        set resource "https://check.torproject.org/torbulkexitlist"
        set refresh-rate 1440
    next
end

# Use in firewall policy
config firewall policy
    edit 0
        set name "Block-Threat-Feed"
        set srcintf "wan1"
        set dstintf "lan"
        set srcaddr "Malicious-IPs" "TOR-Exit-Nodes"
        set dstaddr "all"
        set action deny
        set schedule "always"
        set service "ALL"
        set logtraffic all
    next
end
```

### External Domain Block List (DNS Filter)

```bash
config system external-resource
    edit "Malicious-Domains"
        set type domain
        set resource "https://example.com/threat-feed/malicious-domains.txt"
        set refresh-rate 60
    next
end

# Use in DNS filter profile
config dnsfilter profile
    edit "Block-Malicious"
        config ftgd-dns
            # Enable categories as needed
        end
        set external-ip-blocklist "Malicious-Domains"
    next
end
```

### FortiGuard Threat Feeds (Built-in)

```bash
# Enable FortiGuard outbreak prevention
config ips global
    set fail-open enable
end

config ips sensor
    edit "Default"
        set scan-botnet-connections block
    next
end

# Internet Service Database (ISDB) for app control
# Used in SD-WAN and policies automatically
get firewall internet-service-name
```

### Popular Public Threat Feeds

| Feed | URL | Type |
|------|-----|------|
| Abuse.ch Feodo Tracker | `https://feodotracker.abuse.ch/downloads/ipblocklist.txt` | IPs |
| Spamhaus DROP | `https://www.spamhaus.org/drop/drop.txt` | CIDRs |
| TOR Exit Nodes | `https://check.torproject.org/torbulkexitlist` | IPs |
| Emerging Threats | `https://rules.emergingthreats.net/fwrules/emerging-Block-IPs.txt` | IPs |

### Check Threat Feed Status

```bash
# View external resources
diagnose sys external-resource list
diagnose sys external-resource entry list <name>

# Force refresh
diagnose sys external-resource update <name>
```

---

## Automation Stitches

Automation stitches let you trigger actions based on events (logs, schedules, etc.). Great for automated responses to security events, notifications, and custom workflows.

### Components

- **Trigger**: Event that starts the automation (log event, schedule, etc.)
- **Action**: What happens when triggered (email, webhook, CLI script, etc.)
- **Stitch**: Combines trigger + action(s)

### Create a Trigger

```bash
# Event-based trigger (e.g., admin login)
config system automation-trigger
    edit "Admin-Login-Trigger"
        set event-type event-log
        set logid 32001  # Admin login event
    next
end

# IPS attack trigger
config system automation-trigger
    edit "IPS-Critical-Alert"
        set event-type event-log
        set logid 16384
        config fields
            edit 1
                set name "severity"
                set value "critical"
            next
        end
    next
end

# Schedule trigger (daily at 6am)
config system automation-trigger
    edit "Daily-6AM"
        set trigger-type scheduled
        set trigger-frequency daily
        set trigger-hour 6
        set trigger-minute 0
    next
end

# Incoming webhook trigger
config system automation-trigger
    edit "Webhook-Trigger"
        set trigger-type incoming-webhook
    next
end

# HA failover trigger
config system automation-trigger
    edit "HA-Failover"
        set event-type ha-failover
    next
end

# FortiGuard update trigger
config system automation-trigger
    edit "AV-DB-Updated"
        set event-type faz-event
        set event-name "av-db-update"
    next
end
```

### Create Actions

```bash
# Email notification
config system automation-action
    edit "Email-Admin"
        set action-type email
        set email-to "admin@company.com"
        set email-from "fortigate@company.com"
        set email-subject "FortiGate Alert: %%log.logdesc%%"
        set message "Event: %%log.logdesc%%\nSource: %%log.srcip%%\nTime: %%log.date%% %%log.time%%"
    next
end

# Webhook/API call
config system automation-action
    edit "Slack-Webhook"
        set action-type webhook
        set uri "https://hooks.slack.com/services/xxx/yyy/zzz"
        set http-body "{\"text\": \"FortiGate Alert: %%log.logdesc%% from %%log.srcip%%\"}"
        set port 443
        set protocol https
        set method post
    next
end

# Teams webhook
config system automation-action
    edit "Teams-Alert"
        set action-type webhook
        set uri "https://outlook.office.com/webhook/xxx"
        set http-body "{\"text\": \"**FortiGate Alert**\\n\\nEvent: %%log.logdesc%%\\nSource: %%log.srcip%%\"}"
        set port 443
        set protocol https
        set method post
    next
end

# Run CLI script
config system automation-action
    edit "Block-Attacker-IP"
        set action-type cli-script
        set script "config firewall address
    edit \"blocked-%%log.srcip%%\"
        set subnet %%log.srcip%%/32
    next
end
config firewall addrgrp
    edit \"Auto-Blocked\"
        append member \"blocked-%%log.srcip%%\"
    next
end"
    next
end

# Quarantine host
config system automation-action
    edit "Quarantine-Host"
        set action-type quarantine
        set quarantine-host-mac %%log.srcmac%%
    next
end

# Ban IP
config system automation-action
    edit "Ban-IP"
        set action-type ip-ban
    next
end

# AWS Lambda
config system automation-action
    edit "AWS-Lambda"
        set action-type aws-lambda
        set aws-api-id "your-api-id"
        set aws-region "us-east-1"
        set aws-api-key "your-key"
    next
end
```

### Create Stitch (Combine Trigger + Actions)

```bash
config system automation-stitch
    edit "Alert-On-IPS-Critical"
        set status enable
        set trigger "IPS-Critical-Alert"
        config actions
            edit 1
                set action "Email-Admin"
                set required enable
            next
            edit 2
                set action "Slack-Webhook"
            next
        end
    next
end

# Auto-block attacker
config system automation-stitch
    edit "Auto-Block-Brute-Force"
        set status enable
        set trigger "Brute-Force-Detected"
        config actions
            edit 1
                set action "Block-Attacker-IP"
                set required enable
            next
            edit 2
                set action "Email-Admin"
            next
        end
    next
end

# Daily backup via webhook
config system automation-stitch
    edit "Daily-Backup-Notify"
        set status enable
        set trigger "Daily-6AM"
        config actions
            edit 1
                set action "Backup-Webhook"
            next
        end
    next
end
```

### Common Log IDs for Triggers

| Event | Log ID |
|-------|--------|
| Admin login | 32001 |
| Admin logout | 32002 |
| Failed admin login | 32003 |
| Config change | 32102 |
| IPS alert | 16384 |
| AV detection | 8192 |
| Web filter block | 12288 |
| VPN tunnel up | 37138 |
| VPN tunnel down | 37139 |
| HA failover | 41216 |
| Interface up | 20480 |
| Interface down | 20481 |

### Replacement Variables

Use these in action messages:

| Variable | Description |
|----------|-------------|
| `%%log.srcip%%` | Source IP |
| `%%log.dstip%%` | Destination IP |
| `%%log.srcport%%` | Source port |
| `%%log.dstport%%` | Destination port |
| `%%log.srcmac%%` | Source MAC |
| `%%log.action%%` | Action taken |
| `%%log.logdesc%%` | Log description |
| `%%log.msg%%` | Log message |
| `%%log.date%%` | Date |
| `%%log.time%%` | Time |
| `%%log.user%%` | Username |
| `%%log.devname%%` | Device name |

### View & Debug Automation

```bash
# Show triggers
show system automation-trigger

# Show actions
show system automation-action

# Show stitches
show system automation-stitch

# Check automation status
diagnose automation test <stitch-name>

# Debug automation
diagnose debug application autod -1
diagnose debug enable
```

---

## CLI Quick Reference

### System

```bash
# Show system status
get system status
get system performance status

# Reboot
execute reboot

# Firmware upgrade
execute restore image tftp <filename> <tftp-server-ip>

# Factory reset
execute factoryreset
```

### Interfaces

```bash
# Show interfaces
get system interface
show system interface

# Bring interface up/down
config system interface
    edit "wan1"
        set status up
    next
end
```

### VPN

```bash
# IPsec tunnel status
get vpn ipsec tunnel summary
diagnose vpn ike gateway list
diagnose vpn tunnel list

# SSL VPN
get vpn ssl monitor
diagnose vpn ssl list
```

### Sessions & Traffic

```bash
# Active sessions
get system session list
diagnose sys session filter clear
diagnose sys session filter dport 443
diagnose sys session list

# Sniffer
diagnose sniffer packet any "host 192.168.1.100" 4 0 l
diagnose sniffer packet wan1 "port 443" 4 100
```

---

## Backup & Restore

### Backup Config

```bash
# Via CLI (to TFTP)
execute backup config tftp <filename> <tftp-server-ip>

# Via CLI (to USB)
execute backup config usb <filename>
```

### Restore Config

```bash
execute restore config tftp <filename> <tftp-server-ip>
execute restore config usb <filename>
```

### Scheduled Backup (via FortiManager or Script)

```bash
# SCP backup example (from external host)
scp admin@<fortigate-ip>:sys_config /backups/fortigate-$(date +%Y%m%d).conf
```

---

## Troubleshooting

### Debug Commands

```bash
# Enable debug
diagnose debug enable
diagnose debug console timestamp enable

# Debug flow (traffic)
diagnose debug flow filter addr 192.168.1.100
diagnose debug flow trace start 100
diagnose debug flow trace stop

# Debug IPsec
diagnose vpn ike log filter dst-addr4 <peer-ip>
diagnose debug app ike -1
diagnose debug enable

# Stop all debug
diagnose debug disable
diagnose debug reset
```

### Common Issues

| Issue | Command |
|-------|---------|
| Policy not matching | `diagnose debug flow trace start 100` |
| IPsec tunnel down | `diagnose vpn ike gateway list` |
| High CPU | `get system performance top` |
| Session table full | `get system session status` |
| DNS issues | `execute ping-options source <interface>` then `execute ping 8.8.8.8` |
| Failover not working | `diagnose sys link-monitor interface` |
| SD-WAN issues | `diagnose sys sdwan health-check` |

### Log Commands

```bash
# View logs
execute log filter category event
execute log filter device disk
execute log display

# Real-time log
execute log filter field action deny
execute log display
```

---

## Resources

- [FortiGate Admin Guide](https://docs.fortinet.com/product/fortigate/)
- [FortiOS CLI Reference](https://docs.fortinet.com/document/fortigate/7.4.0/cli-reference/)
- [Fortinet Community](https://community.fortinet.com/)
- [FortiGuard Threat Encyclopedia](https://www.fortiguard.com/encyclopedia)

---

## License

MIT - Do whatever you want with it.
