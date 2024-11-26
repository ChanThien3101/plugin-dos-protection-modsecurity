-- Path to the blocklist file
local blocklist_file = "/etc/apache2/modsecurity.d/owasp-crs/plugins/plugin-dos-protection-modsecurity/plugins/blockListIP.txt"

function main()
    -- Get client IP from ModSecurity
    local ip = m.getvar("REMOTE_ADDR")
    if not ip then
        return nil -- No IP to check
    end

    -- Open the blocklist file for reading
    local file = io.open(blocklist_file, "r")
    if not file then
        return nil -- Cannot open blocklist file
    end

    -- Check if the IP exists in the blocklist
    for line in file:lines() do
        if line == ip then
            file:close()
            return "Blocked IP found in blocklist: " .. ip
        end
    end

    -- Close the file if IP not found
    file:close()
    return nil -- IP not in blocklist
end
