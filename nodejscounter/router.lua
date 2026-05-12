local function is_node_up(backend_name, server_name)
    local b = core.backends[backend_name]
    if b then
        local s = b.servers[server_name]
        if s then
            local st = s:get_stats()
            local status = st["status"]
            if status and (status == "UP" or status:sub(1, 2) == "UP") then
                return true
            end
        end
    end
    return false
end

core.register_action("do_routing", { "http-req" }, function(txn)
    local target = "node2" -- default fallback

    local tcp = core.tcp()
    tcp:settimeout(1)
    
    if tcp:connect("127.0.0.1", 8081) then
        local request = "GET /count HTTP/1.1\r\nHost: localhost\r\nConnection: close\r\n\r\n"
        tcp:send(request)

        local response = ""
        while true do
            local chunk = tcp:receive("*l")
            if not chunk or chunk == "" then break end
            response = response .. chunk .. "\n"
        end
        local body_chunk = tcp:receive("*a")
        if body_chunk then response = response .. "\n\n" .. body_chunk end
        tcp:close()

        local count = nil
        for line in response:gmatch("[^\r\n]+") do
            local n = tonumber(line)
            if n then count = n end
        end
        
        if count then
            if count % 2 ~= 0 then
                target = "node1"
            else
                target = "node2"
            end
        end
    end

    -- Health check logic
    local s_name = target == "node1" and "s1" or "s2"
    if not is_node_up(target, s_name) then
        core.Alert("ROUTING LOG: " .. target .. " is DOWN. Triggering fallback.")
        -- Fallback to the other node
        if target == "node1" then
            target = "node2"
        else
            target = "node1"
        end
    else
        core.Info("ROUTING LOG: " .. target .. " is UP. Routing successfully.")
    end

    txn.set_var(txn, "txn.target_node", target)
end)


core.register_action("do_redis_routing", { "http-req" }, function(txn)
    local backend = "node1"
    local tcp = core.tcp()
    tcp:settimeout(0.1)

    -- CONNECT REDIS
    if not tcp:connect("127.0.0.1", 6379) then
        txn.set_var(txn, "txn.target_node", "node2")
        return
    end

    -- Redis GET oo_node1_users
    tcp:send("*2\r\n$3\r\nGET\r\n$14\r\noo_node1_users\r\n")

    -- RESP line 1: $size
    local size_line = tcp:receive("*l")

    -- RESP line 2: actual value
    local value_line = tcp:receive("*l")

    tcp:close()

    local count = tonumber(value_line)

    -- Routing logic
    if count and count > 10 then
        backend = "node2"
    end

    txn.set_var(txn, "txn.target_node", backend)
end)
