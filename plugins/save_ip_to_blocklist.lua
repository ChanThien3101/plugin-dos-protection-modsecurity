local M = require 'posix.fcntl'
local S = require 'posix.sys.stat'
local U = require 'posix.unistd'

-- Get file path and IP from ModSecurity
local file_path = m.getvar("tx.blocklist_file")
local ip_to_add = m.getvar("REMOTE_ADDR")

-- Validate inputs
if not file_path or not ip_to_add then
    return nil -- Missing required inputs
end

-- Open the file
local fd = M.open(
    file_path,
    M.O_CREAT + M.O_RDWR,
    S.S_IRUSR + S.S_IWUSR + S.S_IRGRP + S.S_IROTH
)

if not fd then
    return nil -- Failed to open file
end

-- Set lock on file
local lock = {
    l_type = M.F_WRLCK,     -- Exclusive lock
    l_whence = M.SEEK_SET,  -- Relative to beginning of file
    l_start = 0,            -- Start from 1st byte
    l_len = 0               -- Lock whole file
}

local max_retries = 5
local retry_interval = 0.2 -- Seconds

local success = false

for _ = 1, max_retries do
    if M.fcntl(fd, M.F_SETLK, lock) ~= nil then
        success = true
        break
    else
        U.sleep(retry_interval) -- Wait before retrying
    end
end

if success then
    -- Read the file content to check if IP already exists
    local current_size = U.lseek(fd, 0, U.SEEK_END) -- Move to the end of the file
    if current_size then
        U.lseek(fd, 0, U.SEEK_SET) -- Reset position to the beginning of the file

        local content = U.read(fd, current_size) -- Read the whole file
        if content and not content:find(ip_to_add, 1, true) then
            -- Write IP to the file
            U.lseek(fd, 0, U.SEEK_END) -- Move to the end of the file again
            U.write(fd, ip_to_add .. "\n") -- Append the IP address to the file
        end
    end
end

-- Release the lock
lock.l_type = M.F_UNLCK
M.fcntl(fd, M.F_SETLK, lock)

-- Close the file
U.close(fd)
