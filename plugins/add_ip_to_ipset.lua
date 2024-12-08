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
        return nil -- Invalid IP
    end

    -- Retrieve the ban time (configurable via ModSecurity or use the default)
    local ban_time = 3600
    if not is_valid_ban_time(ban_time) then
        return nil -- Invalid ban time
    end

    -- Construct the ipset command
    local command = string.format("sudo /sbin/ipset add blocklistip %s timeout %d", ip, ban_time)

    -- Execute the command
    local result = os.execute(command)

    -- Check the execution result
    if result ~= 0 then
        return nil -- Error while executing the ipset command
    end

    return nil -- Success
end
