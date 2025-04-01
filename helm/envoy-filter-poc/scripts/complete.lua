local function get_auth_protocol()
  return os.getenv("AUTH_PROTOCOL") or "HTTP"
end

local function get_auth_host()
  return os.getenv("AUTH_HOST")
end

function envoy_on_request(request_handle)

  local auth_header = request_handle:headers():get("Authorization")
  
  if auth_header == nil then
    return
  end

  request_handle:headers():replace("Authorization", "Filter works nicely")

  local auth_protocol = get_auth_protocol()
  local auth_host = get_auth_host()
  
  local headers = {
    [":method"] = "GET",
    [":path"] = "/auth",
    [":authority"] = auth_host,
    ["Authorization"] = auth_header
  }
  
  if auth_protocol == "HTTP" then
    local json_headers = http_call(auth_host, headers, "", 5000)
    if json_headers ~= nil then
      merge_headers(request_handle:headers(), json_headers)
    end
  elseif auth_protocol == "GRPC" then
    -- TODO: Iplement gRPC 
    request_handle:logWarn("Unknown auth protocol: " .. auth_protocol)
  end
end

function parse_json(json_string)
  if json_string == nil or json_string == "" then
    return nil
  end
  
  -- Envoys built-in JSON
  local success, result = pcall(function()
    return json.unmarshal(json_string)
  end)
  
  if not success then
    request_handle:logWarn("Failed to parse JSON response: " .. tostring(result))
    return nil
  end
  
  return result
end

function merge_headers(request_headers, new_headers)
  for header_name, header_value in pairs(new_headers) do
    request_headers:replace(header_name, header_value)
  end
end

function http_call(host, headers, body, timeout)
    local response_headers, response_body = request_handle:httpCall("cluster." .. auth_host:gsub(":", "_"), headers, "", 5000, false)
    
    if response_headers[":status"] ~= "200" then
      return nil
    end

    local json_headers = parse_json(response_body)
    return json_headers
end