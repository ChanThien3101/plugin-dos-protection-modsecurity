function main()
    local ip = m.getvar("REMOTE_ADDR")
    if not ip then
        return nil -- Không có IP để xử lý
    end

    -- Thời gian chặn IP (giây)
    local ban_time = 3600

    -- Lệnh để gọi script shell với sudo
    local command = "sudo /usr/local/bin/add_ip_to_ipset.sh " .. ip .. " " .. ban_time

    -- Thực thi lệnh
    os.execute(command)

    return nil
end
