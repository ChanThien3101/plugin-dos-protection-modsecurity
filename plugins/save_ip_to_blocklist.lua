local blocklist_file = "/etc/apache2/modsecurity.d/owasp-crs/plugins/plugin-dos-protection-modsecurity/plugins/blockListIP.txt"

function main()
    local ip = m.getvar("REMOTE_ADDR")
    if ip then
        local file = io.open(blocklist_file, "a")
        if file then
            file:write(ip .. "\n")
            file:close()
            print("IP written to blocklist: " .. ip)
        end
    end
    return nil
end
