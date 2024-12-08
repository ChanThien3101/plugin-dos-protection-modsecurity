# CRS - DoS Protection Plugin for ModSecurity

## Plugin Expectations: Suitability and Scale

ModSecurity and CRS are suited to protect against small-scale, application level denial-of-service (DoS) attacks. DoS attacks at the network level, distributed DoS (DDoS) attacks, and larger DoS attacks are hard to fight with ModSecurity. The reason for this is that the means of ModSecurity degrade under load and hence its ability to effectively handle DoS attacks degrades as well.

In such a situation, CRS proposes the use of one or several of the following options:

- `mod_reqtimeout` on Apache to deal with request delaying attacks like [Slowloris](https://en.wikipedia.org/wiki/Slowloris_(computer_security))
- `mod_evasive` on Apache since it's been around for more than 20 years
- `mod_qos` on Apache which provides granular control over clients hammering the server
- Using a load balancer / traffic washer with DoS capabilities
- A DoS protection service and/or content delivery network

## Description of Mechanics

When a request hits a non-static resource (`TX:STATIC_EXTENSIONS`), then a counter for the IP address is being raised (`IP:DOS_COUNTER`). If the counter (`IP:DOS_COUNTER`) hits a limit (`TX:DOS_COUNTER_THRESHOLD`), then a burst is identified (`IP:DOS_BURST_COUNTER`) and the counter (`IP:DOS_COUNTER`) is reset. The burst counter expires within a timeout period (`TX:DOS_BURST_TIME_SLICE`).

If the burst counter (IP:DOS_BURST_COUNTER) is greater than or equal to 2, the blocking flag (`IP:DOS_BLOCK_IP`) will be set. The blocking flag (`IP:DOS_BLOCK_IP`) will expire after a timeout period (`TX:DOS_BLOCK_TIMEOUT`). Subsequently, ModSecurity will invoke a Lua script to add the IP address to the blockListIP.txt file so that the IP can be blocked during the next access attempt. This entire process takes place in phase 5.

There is a stricter sibling to this rule (9523151) in paranoia level 2, where the burst counter check (`IP:DOS_BURST_COUNTER`) hits at greater equal 1.

### Blocking with blockListIP.txt

If you want to use rule 9523990 to block the IP without using ipset and apply blocking through iptables, the blocking is executed in phase 1: When an IP attempts to connect to the server, if the Lua script detects that the IP exists in the blockListIP.txt file, the IP will be blocked. At the same time, the request will be dropped without sending any response.

### Blocking with ipset and iptables

If you want to add the offending IP to the ipset blocklist and apply blocking through iptables, we will use rules 9523150 or 9523151. Additionally, disable rule 9523990 as it is not necessary in this case. To set this up, we need the following steps:

- Create an ipset blocklist to block IPs

```
sudo ipset create blocklistip hash:ip timeout 3600
```

- Configure iptables to use the ipset

```
sudo iptables -A INPUT -m set --match-set blocklistip src -j DROP
```

- Save iptables rules (if desired)

```
sudo mkdir -p /etc/iptables
sudo iptables-save > /etc/iptables/rules.v4
```

- Save the ipset list to persist and restore it upon reboot (if desired)

```
sudo ipset save > /etc/ipset.rules
```

You also need to create a script with root privileges and then allow ModSecurity to call this script via sudo. To do this, ensure that the user under which ModSecurity runs (usually www-data on Apache) has permission to run the command with sudo without requiring a password.

- Edit the sudoers file to allow the www-data user to run the script without a password prompt and add to allow www-data to run the script without a password

```
sudo visudo
www-data ALL=(ALL) NOPASSWD: /sbin/ipset add blocklistip * timeout *
```

### Variables

| Variable                   | Description                                                 |
| -------------------------- | ----------------------------------------------------------- |
| `IP:DOS_BLOCK_IP`          | Flag if an IP address should be blocked                     |
| `IP:DOS_BURST_COUNTER`     | Burst counter                                               |
| `IP:DOS_COUNTER`           | Request counter (static resources are ignored)              |
| `TX:DOS_BLOCK_TIMEOUT`     | Period in seconds a blocked IP will be blocked              |
| `TX:DOS_COUNTER_THRESHOLD` | Limit of requests, where a burst is identified              |
| `TX:DOS_BURST_TIME_SLICE`  | Period in seconds when we will forget a burst               |
| `TX:STATIC_EXTENSIONS`     | Paths which can be ignored with regards to DoS              |

As a precondition for these rules, please set the following three variables in `dos-protection-config.conf`:

- `TX:DOS_BLOCK_TIMEOUT`
- `TX:DOS_COUNTER_THRESHOLD`
- `TX:DOS_BURST_TIME_SLICE`

And make sure that `TX:STATIC_EXTENSIONS` is set as required, also in `dos-protection-config.conf`.

## Testing

Hit the service quickly enough (within the set time slice) and frequently enough (exceeding the set threshold) and observe that connections are then dropped.

Be sure that the test connections are _not_ hitting an exempt static extension, as this will not trigger a block and will not be a valid test.

## License

Please see the enclosed LICENSE file for full details.

## Notes

Set full write permissions for the blockListIP.txt file if you want to use rule 9523990 to block the IP.

ipset and iptables rules will be lost when you shut down or reboot, so you need to back them up before shutting down.

Set up www-data for ModSecurity.

## Contacts

Email: `ducdh1906@gmail.com`