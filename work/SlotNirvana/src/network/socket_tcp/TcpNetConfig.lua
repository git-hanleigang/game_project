
-- socket相关配置文件

local TcpNetConfig = {}

-- 可能有多个服务器
TcpNetConfig.SERVER_KEY = {
    CLAN_CHAT = "clan_chat",    -- 聊天服务器
}

-- 服务器列表
TcpNetConfig.SERVER_LIST = {
    [TcpNetConfig.SERVER_KEY.CLAN_CHAT] = {
        host = nil,     -- 聊天服务器地址
        port = nil,            -- 聊天服务器端口
    },
}
TcpNetConfig.SERVER_LIST_NEW = {}

TcpNetConfig.buffer_size = 8192    -- 缓冲区大小
TcpNetConfig.time_out = 2 -- 最大响应时长

-- 连接状态
TcpNetConfig.LINK_STATE = {
    DISCONNECT = "disconnect",      -- 连接断开
    TRY_CONNECT = "try_connect",    -- 发起连接
    ON_CONNECT = "on_connect",      -- 已经建立连接
    TIME_OUT = "time_out",          -- 响应超时
    CLOSE_CONNECT = "close_connect",-- 关闭连接
}

-- 连接状态信息
TcpNetConfig.LINK_MSG = {
    CLOSED = "closed",
    DISCONNECT = "Socket is not connected",
    CONNECTED = "already connected",
    TRY_CONNECT = "Operation already in progress",
    TIME_OUT = "timeout",
    REFUSED = "connection refused",
}

TcpNetConfig.UPDATE_STATUS = {
    CONNECTED = "connected",
    RECEIVE = "receive",
    ERROR = "error",
    GO_CLOSE = "go_close",
    TRY_NEXT_ADDRESS = "try_next_address"
}
TcpNetConfig.XCTCP_STATUS = {
    CLOSED = 0,
    CONNECTING = 1,
    CONNECTED = 2,
}

return TcpNetConfig