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

There is a stricter sibling to this rule (9514170) in paranoia level 2, where the burst counter check (`IP:DOS_BURST_COUNTER`) hits at greater equal 1.

### Blocking

The blocking is executed in phase 1: When an IP attempts to connect to the server, if the Lua script detects that the IP exists in the blockListIP.txt file, the IP will be blocked. At the same time, the request will be dropped without sending any response

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

Set full write permissions for the blockListIP.txt file

## Contacts

Email: `ducdh1906@gmail.com`