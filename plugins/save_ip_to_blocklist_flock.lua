local blocklist_file = "/etc/apache2/modsecurity.d/owasp-crs/plugins/plugin-dos-protection-modsecurity/plugins/blockListIP.txt"
local max_retries = 5  -- Number of retries if the file cannot be locked
local retry_delay = 0.1  -- Time to wait between retries (in seconds)

function main()
    -- Get the client IP address from ModSecurity
    local ip = m.getvar("REMOTE_ADDR")
    if not ip then
        return nil  -- No IP to process
    end

    -- Try to open the blocklist file and attempt to lock it
    local retries = 0
    local success = false
    while retries < max_retries do
        -- Use the `flock` system command to lock the file
        local result = os.execute("flock -w " .. retry_delay .. " " .. blocklist_file .. " -c 'cat " .. blocklist_file .. " | grep -q " .. ip .. " || echo " .. ip .. " >> " .. blocklist_file .. "'")

        -- Check if the command was successful (lock successful and IP written)
        if result == 0 then
            success = true
            break  -- If the lock is successful, exit the loop
        else
            retries = retries + 1  -- Increment the retry count
            os.execute("sleep " .. retry_delay)  -- Wait before retrying
        end
    end

    -- If the file could not be locked after the maximum retries, exit
    if not success then
        return nil  -- Could not lock the file after "max_retries" attempts
    end

    -- Return nil to signal successful execution
    return nil
end
