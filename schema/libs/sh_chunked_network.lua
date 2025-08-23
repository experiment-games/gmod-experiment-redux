--[[
	Library to send possibly large amounts of data over the network in smaller chunks.
	This helps prevent reaching the Network Library limit.
	It sends chunks with some delay to avoid causing 'reliable buffer overflow' for clients.
--]]

Schema.chunkedNetwork = ix.util.GetOrCreateLibrary("chunkedNetwork")

--- Delay between sending data chunks over network (to prevent reliable buffer overflow)
Schema.chunkedNetwork.DefaultChunkSize = 50
Schema.chunkedNetwork.DefaultDelay = 0.05

-- Registry of message handlers
Schema.chunkedNetwork.handlers = Schema.chunkedNetwork.handlers or {}
Schema.chunkedNetwork.activeOperations = Schema.chunkedNetwork.activeOperations or {}

--- @see Schema.chunkedNetwork.Register
--- @see Schema.chunkedNetwork.RegisterFireAndForget
local function createChunkedNetworkConfig(messageName, chunkSize, delay, networkNames)
  local config = {
    messageName = messageName,
    chunkSize = chunkSize or Schema.chunkedNetwork.DefaultChunkSize,
    delay = delay or Schema.chunkedNetwork.DefaultDelay,
    headerName = "exp" .. messageName .. "Header"
  }

  -- Add the additional network names to config
  for key, value in pairs(networkNames) do
    config[key] = value
  end

  Schema.chunkedNetwork.handlers[messageName] = config

  if (SERVER) then
    -- Register all network strings
    util.AddNetworkString(config.headerName)
    for _, networkString in pairs(networkNames) do
      util.AddNetworkString(networkString)
    end
  else
    -- Setup net.Receive
    Schema.chunkedNetwork.SetupClientReceiver(messageName)
  end

  return config
end

--- Register a chunked network message and the associated network strings:
--- - {messageName}Header is a metadata packet with information about the chunked data
--- - {messageName}Data are the actual data packets being sent
--- - {messageName}Request is a request packet to initiate the chunked transfer and calls back when the transfer is complete
--- You'll need to call this in a shared file so that both the client and server are aware of the message.
--- The network message names will be prefixed with exp to reduce the chance of collisions with addons.
--- @param messageName string - The base name for the message
--- @param chunkSize number - Optional chunk size override
--- @param delay number - Optional delay override
function Schema.chunkedNetwork.Register(messageName, chunkSize, delay)
  local networkNames = {
    dataName = "exp" .. messageName .. "Data",
    requestName = "exp" .. messageName .. "Request"
  }
  return createChunkedNetworkConfig(messageName, chunkSize, delay, networkNames)
end

--- Register a chunked network message and the associated network strings:
--- - {messageName}Header is a metadata packet with information about the chunked data
--- - {messageName}Send is a fire-and-forget packet header for sending data without expecting a response
--- - {messageName}SendData are the actual data packets for fire-and-forget sending
--- You'll need to call this in a shared file so that both the client and server are aware of the message.
--- The network message names will be prefixed with exp to reduce the chance of collisions with addons.
--- @param messageName string - The base name for the message
--- @param chunkSize number - Optional chunk size override
--- @param delay number - Optional delay override
function Schema.chunkedNetwork.RegisterFireAndForget(messageName, chunkSize, delay)
  local networkNames = {
    sendName = "exp" .. messageName .. "Send",
    sendDataName = "exp" .. messageName .. "SendData"
  }
  return createChunkedNetworkConfig(messageName, chunkSize, delay, networkNames)
end

if (SERVER) then
  ---	Send chunked data to a client. Not directly callback because you should use the respond
  --- function in the closure of HandleRequest to send response data instead.
  ---	@param messageName string The registered message name
  ---	@param client Player The client to send to
  ---	@param data table The data to send (will be chunked automatically)
  ---	@param extraData? table Optional extra data to send with header (e.g., steamID)
  ---	@return number # Delay in seconds for complete transmission
  local function sendResponse(messageName, client, data, extraData)
    local config = Schema.chunkedNetwork.handlers[messageName]

    if (not config) then
      error("Schema.chunkedNetwork Response: Message '" .. messageName .. "' not registered!")
    end

    extraData = extraData or {}
    local jsonified = false

    if (not Schema.IsArrayLike(data)) then
      -- If it's not a sequential array we turn it into pretty printed JSON, such that it can be chunked
      data = util.TableToJSON(data, true):Explode("\n")
      jsonified = true
    end

    local messageAmount = #data

    -- Send header
    net.Start(config.headerName)
    net.WriteUInt(messageAmount, 16)
    net.WriteBool(jsonified) -- Indicate if data was JSONified
    net.WriteTable(extraData)
    net.Send(client)

    if (messageAmount == 0) then
      return 0
    end

    -- Use Schema.ScopedChunkData to send the data
    local delayInSeconds = Schema.ScopedChunkData(
      client,
      messageName,
      data,
      config.chunkSize,
      config.delay,
      function(chunk, chunkIndex, chunkAmount)
        for _, entry in ipairs(chunk) do
          net.Start(config.dataName)
          net.WriteType(entry)
          net.Send(client)
        end
      end
    )

    return delayInSeconds
  end

  ---	Handle incoming requests for chunked data. The provided callback is given a respond function, use that
  --- to send response data back to the client.
  ---	@param messageName string The registered message name
  ---	@param callback fun(client: Player, respond: fun(data: table, extraData?: table), requestData: table) Callback to call when request received
  function Schema.chunkedNetwork.HandleRequest(messageName, callback)
    local config = Schema.chunkedNetwork.handlers[messageName]

    if (not config) then
      error("Schema.chunkedNetwork: Message '" .. messageName .. "' not registered!")
    end

    net.Receive(config.requestName, function(len, client)
      local requestData = {}

      local iterations = 0

      -- Read until we run out of data
      while (net.BytesLeft() > 0) do
        local key = net.ReadString()
        local value = net.ReadType()

        requestData[key] = value
        iterations = iterations + 1

        if (iterations > 100000) then
          print(client, messageName, len, requestData)
          PrintTable(requestData)
          error("Schema.chunkedNetwork: Infinite loop detected!")
          return
        end
      end

      local respond = function(data, extraData)
        sendResponse(messageName, client, data, extraData)
      end

      callback(client, respond, requestData)
    end)
  end

  ---	Send chunked data to client(s) without expecting a response (fire and forget)
  ---	@param messageName string The registered message name
  ---	@param target Player|table|nil The client(s) to send to, nil for all clients
  ---	@param data table The data to send (will be chunked automatically)
  ---	@param extraData? table Optional extra data to send with header
  ---	@return number # Delay in seconds for complete transmission
  function Schema.chunkedNetwork.Send(messageName, target, data, extraData)
    local config = Schema.chunkedNetwork.handlers[messageName]

    if (not config) then
      error("Schema.chunkedNetwork Send: Message '" .. messageName .. "' not registered!")
    end

    extraData = extraData or {}
    local jsonified = false

    if (not Schema.IsArrayLike(data)) then
      -- If it's not a sequential array we turn it into pretty printed JSON, such that it can be chunked
      data = util.TableToJSON(data, true):Explode("\n")
      jsonified = true
    end

    local messageAmount = #data

    -- Send header
    net.Start(config.sendName)
    net.WriteUInt(messageAmount, 16)
    net.WriteBool(jsonified) -- Indicate if data was JSONified
    net.WriteTable(extraData)

    if (target) then
      net.Send(target)
    else
      net.Broadcast()
    end

    if (messageAmount == 0) then
      return 0
    end

    -- Handle different target types for Schema.ScopedChunkData
    local delayInSeconds = 0

    if (not target) then
      -- Broadcast to all - use game as scope
      delayInSeconds = Schema.ScopedChunkData(
        game.GetWorld(),
        messageName .. "_send_broadcast",
        data,
        config.chunkSize,
        config.delay,
        function(chunk, chunkIndex, chunkAmount)
          for _, entry in ipairs(chunk) do
            net.Start(config.sendDataName)
            net.WriteType(entry)
            net.Broadcast()
          end
        end
      )
    elseif (istable(target)) then
      -- Multiple targets - process each one
      for _, client in ipairs(target) do
        if (IsValid(client)) then
          delayInSeconds = math.max(delayInSeconds, Schema.ScopedChunkData(
            client,
            messageName .. "_send",
            data,
            config.chunkSize,
            config.delay,
            function(chunk, chunkIndex, chunkAmount)
              for _, entry in ipairs(chunk) do
                net.Start(config.sendDataName)
                net.WriteType(entry)
                net.Send(client)
              end
            end
          ))
        end
      end
    else
      -- Single target
      delayInSeconds = Schema.ScopedChunkData(
        target,
        messageName .. "_send",
        data,
        config.chunkSize,
        config.delay,
        function(chunk, chunkIndex, chunkAmount)
          for _, entry in ipairs(chunk) do
            net.Start(config.sendDataName)
            net.WriteType(entry)
            net.Send(target)
          end
        end
      )
    end

    return delayInSeconds
  end

  ---	Handle incoming fire-and-forget chunked data from clients
  ---	@param messageName string The registered message name
  ---	@param callback fun(client: Player, receivedData: table, extraData: table) Callback when data is fully received
  function Schema.chunkedNetwork.HandleSend(messageName, callback)
    local config = Schema.chunkedNetwork.handlers[messageName]

    if (not config) then
      error("Schema.chunkedNetwork HandleSend: Message '" .. messageName .. "' not registered!")
    end

    -- Store active receive operations per client
    local activeReceives = {}

    -- Header receiver
    net.Receive(config.sendName, function(length, client)
      local messageAmount = net.ReadUInt(16)
      local jsonified = net.ReadBool()
      local extraData = net.ReadTable()

      if (messageAmount == 0) then
        -- No data, call callback immediately
        callback(client, {}, extraData)
        return
      end

      -- Store operation for this client
      activeReceives[client] = {
        callback = callback,
        receivedData = {},
        jsonified = jsonified,
        extraData = extraData,
        remainingMessages = messageAmount,
      }
    end)

    -- Data receiver
    net.Receive(config.sendDataName, function(length, client)
      local entry = net.ReadType()
      local operation = activeReceives[client]

      if (not operation) then
        print("Schema.chunkedNetwork: Received send data for '" ..
          messageName .. "' from " .. tostring(client) .. " but no active operation!")
        return
      end

      table.insert(operation.receivedData, entry)
      operation.remainingMessages = operation.remainingMessages - 1

      -- Check if we've received all data
      if (operation.remainingMessages <= 0) then
        local receivedData = operation.receivedData
        local extraData = operation.extraData
        local callbackFunc = operation.callback

        if (operation.jsonified) then
          -- If the data was JSONified, we need to decode it
          receivedData = util.JSONToTable(table.concat(receivedData, "\n"))
        end

        activeReceives[client] = nil
        callbackFunc(client, receivedData, extraData)
      end
    end)
  end
elseif (CLIENT) then
  ---	Send a request for chunked data
  ---
  ---	@param messageName string The registered message name
  ---	@param requestData table The data to send with the request
  ---	@param callback fun(receivedData: table, extraData: table) Callback to call when data is received
  function Schema.chunkedNetwork.Request(messageName, requestData, callback)
    local config = Schema.chunkedNetwork.handlers[messageName]
    if (not config) then
      error("Schema.chunkedNetwork: Message '" .. messageName .. "' not registered!")
    end

    -- Store the callback for when we receive the response
    Schema.chunkedNetwork.activeOperations[messageName] = {
      callback = callback,
      receivedData = {},
      extraData = {},
      remainingMessages = 0
    }

    -- Send the request
    net.Start(config.requestName)

    requestData = requestData or {}

    for key, value in pairs(requestData) do
      net.WriteString(key)
      net.WriteType(value)
    end

    net.SendToServer()
  end

  ---	Send chunked data to server without expecting a response (fire and forget)
  ---	@param messageName string The registered message name
  ---	@param data table The data to send (will be chunked automatically)
  ---	@param extraData? table Optional extra data to send with header
  ---	@return number # Delay in seconds for complete transmission
  function Schema.chunkedNetwork.Send(messageName, data, extraData)
    local config = Schema.chunkedNetwork.handlers[messageName]

    if (not config) then
      error("Schema.chunkedNetwork Send: Message '" .. messageName .. "' not registered!")
    end

    extraData = extraData or {}
    local jsonified = false

    if (not Schema.IsArrayLike(data)) then
      -- If it's not a sequential array we turn it into pretty printed JSON, such that it can be chunked
      data = util.TableToJSON(data, true):Explode("\n")
      jsonified = true
    end

    local messageAmount = #data

    -- Send header
    net.Start(config.sendName)
    net.WriteUInt(messageAmount, 16)
    net.WriteBool(jsonified) -- Indicate if data was JSONified
    net.WriteTable(extraData)
    net.SendToServer()

    if (messageAmount == 0) then
      return 0
    end

    -- Use Schema.ScopedChunkData to send the data
    local delayInSeconds = Schema.ScopedChunkData(
      LocalPlayer(),
      messageName .. "_send",
      data,
      config.chunkSize,
      config.delay,
      function(chunk, chunkIndex, chunkAmount)
        for _, entry in ipairs(chunk) do
          net.Start(config.sendDataName)
          net.WriteType(entry)
          net.SendToServer()
        end
      end
    )

    return delayInSeconds
  end

  ---	Handle incoming fire-and-forget chunked data from server
  ---	@param messageName string The registered message name
  ---	@param callback fun(receivedData: table, extraData: table) Callback when data is fully received
  function Schema.chunkedNetwork.HandleSend(messageName, callback)
    local config = Schema.chunkedNetwork.handlers[messageName]

    if (not config) then
      error("Schema.chunkedNetwork HandleSend: Message '" .. messageName .. "' not registered!")
    end

    -- Store active receive operation (only one since it's from server)
    local activeReceive = nil

    -- Header receiver
    net.Receive(config.sendName, function(length)
      local messageAmount = net.ReadUInt(16)
      local jsonified = net.ReadBool() -- Read if data was JSONified
      local extraData = net.ReadTable()

      if (messageAmount == 0) then
        -- No data, call callback immediately
        callback({}, extraData)
        return
      end

      -- Store operation
      activeReceive = {
        callback = callback,
        receivedData = {},
        jsonified = jsonified,
        extraData = extraData,
        remainingMessages = messageAmount,
      }
    end)

    -- Data receiver
    net.Receive(config.sendDataName, function(length)
      local entry = net.ReadType()

      if (not activeReceive) then
        print("Schema.chunkedNetwork: Received send data for '" .. messageName .. "' but no active operation!")
        return
      end

      table.insert(activeReceive.receivedData, entry)
      activeReceive.remainingMessages = activeReceive.remainingMessages - 1

      -- Check if we've received all data
      if (activeReceive.remainingMessages <= 0) then
        local receivedData = activeReceive.receivedData
        local extraData = activeReceive.extraData
        local callbackFunc = activeReceive.callback

        if (activeReceive.jsonified) then
          -- If the data was JSONified, we need to decode it
          receivedData = util.JSONToTable(table.concat(receivedData, "\n"))
        end

        activeReceive = nil
        callbackFunc(receivedData, extraData)
      end
    end)
  end

  ---	Set up the client-side receivers for a registered message
  ---	This is called automatically when registering on client
  ---	@param messageName string The registered message name
  function Schema.chunkedNetwork.SetupClientReceiver(messageName)
    local config = Schema.chunkedNetwork.handlers[messageName]

    -- Header receiver (for request/response)
    net.Receive(config.headerName, function(length)
      local messageAmount = net.ReadUInt(16)
      local jsonified = net.ReadBool() -- Read if data was JSONified
      local operation = Schema.chunkedNetwork.activeOperations[messageName]

      if (not operation) then
        print("Schema.chunkedNetwork: Received header for '" .. messageName .. "' but no active operation!")
        return
      end

      -- Read extra data that was sent with header
      operation.extraData = net.ReadTable()
      operation.jsonified = jsonified

      if (messageAmount == 0) then
        -- No data, call callback immediately
        operation.callback(operation.receivedData, operation.extraData)
        Schema.chunkedNetwork.activeOperations[messageName] = nil
        return
      end

      operation.remainingMessages = messageAmount
      operation.receivedData = {}
    end)

    if (config.dataName) then
      -- Data receiver (for request/response)
      net.Receive(config.dataName, function(length)
        local entry = net.ReadType()
        local operation = Schema.chunkedNetwork.activeOperations[messageName]

        if (not operation) then
          print("Schema.chunkedNetwork: Received data for '" .. messageName .. "' but no active operation!")
          return
        end

        table.insert(operation.receivedData, entry)
        operation.remainingMessages = operation.remainingMessages - 1

        -- Check if we've received all data
        if (operation.remainingMessages <= 0) then
          local receivedData = operation.receivedData
          local extraData = operation.extraData
          local callback = operation.callback

          if (operation.jsonified) then
            -- If the data was JSONified, we need to decode it
            receivedData = util.JSONToTable(table.concat(receivedData, "\n"))
          end

          Schema.chunkedNetwork.activeOperations[messageName] = nil
          callback(receivedData, extraData)
        end
      end)
    end
  end
end

--- Cleanup function for when operations need to be cancelled
--- @param messageName? string The registered message name
function Schema.chunkedNetwork.Cleanup(messageName)
  if (messageName) then
    Schema.chunkedNetwork.activeOperations[messageName] = nil
  else
    Schema.chunkedNetwork.activeOperations = {}
  end
end
