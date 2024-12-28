-- Validate the IP address format
function is_valid_ip(ip)
    if ip:match("^%d+%.%d+%.%d+%.%d+$") then
        for octet in ip:gmatch("%d+") do
            if tonumber(octet) > 255 then
                return false
            end
        end
        return true
    end
    return false
end

-- Validate the ban time
function is_valid_ban_time(ban_time)
    -- The ban time must be a positive integer and not exceed 86400 seconds (24 hours)
    if tonumber(ban_time) and tonumber(ban_time) > 0 and tonumber(ban_time) <= 86400 then
        return true
    end
    return false
end

function main()
    -- Retrieve the IP address from ModSecurity
    local ip = m.getvar("REMOTE_ADDR")
    if not ip or not is_valid_ip(ip) then
        m.log(2, "Error: Invalid IP address.")
        return nil -- Invalid IP
    end

    -- Retrieve the ban time from ModSecurity configuration
    local ban_time = tonumber(m.getvar("TX.DOS_BLOCK_TIMEOUT", "none")) or 3600
    if not is_valid_ban_time(ban_time) then
        m.log(2, "Error: Invalid ban time.")
        return nil -- Invalid ban time
    end

    -- Construct the ipset command
    local command = string.format("sudo /sbin/ipset add blocklistip %s timeout %d", ip, ban_time)

    -- Execute the command
    local result = os.execute(command)

    -- Check the execution result
    if result ~= 0 then
        m.log(2, string.format("Error: Failed to execute ipset command for IP %s.", ip))
        return nil -- Error while executing the ipset command
    end

    m.log(1, string.format("IP %s added to blocklist with timeout %d seconds.", ip, ban_time))
    return nil -- Success
end
