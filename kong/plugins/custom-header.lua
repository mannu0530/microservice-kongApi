-- =============================================================================
# Custom Kong Lua Plugin: Response Header Injection
# =============================================================================
# This plugin adds custom headers to all responses
# Header: X-Platform: SecureAPI
# =============================================================================

local kong = kong
local type = type

-- Plugin configuration schema
local schema = {
  fields = {
    header_name = {
      type = "string",
      default = "X-Platform",
      required = false,
    },
    header_value = {
      type = "string",
      default = "SecureAPI",
      required = false,
    },
    include_on_error = {
      type = "boolean",
      default = true,
      required = false,
    },
  },
}

-- Plugin handler
local CustomHeaderHandler = {
  PRIORITY = 1000,
  VERSION = "1.0.0",
}

-- Function to add headers to response
function CustomHeaderHandler:access(conf)
  -- Store configuration in context for logging phase
  kong.ctx.shared.custom_header_config = conf
end

-- Function executed after the response is received from the upstream service
function CustomHeaderHandler:header_filter(conf)
  local config = kong.ctx.shared.custom_header_config or conf
  
  -- Add custom header to response
  local header_name = config.header_name
  local header_value = config.header_value
  
  if type(header_name) == "string" and type(header_value) == "string" then
    kong.response.set_header(header_name, header_value)
  end
  
  -- Add additional informational headers
  kong.response.set_header("X-Processed-By", "Kong-Custom-Plugin")
end

-- Return the plugin schema and handler
return {
  schema = schema,
  handler = CustomHeaderHandler,
}
