
-- tcp消息体&控制类

require("network.socket_tcp.SQTools")
local socket = require("socket")
local TcpNetConfig = require("network.socket_tcp.TcpNetConfig")
local TcpClient = class("TcpClient")

local sharedScheduler = cc.Director:getInstance():getScheduler()

-- sharedScheduler:unscheduleScriptEntry(handle)



function TcpClient:ctor( ip, port )
    self:init(ip, port)
end

function TcpClient:init( ip, port )
    if ip and port then
        self.ip = ip
        self.port = port
        self.socket = nil
        self._state = TcpNetConfig.LINK_STATE.DISCONNECT
        self:createTimer()
        self.m_name = nil
    end
end

-- 设置链接的名称（用途）
function TcpClient:setName( name )
    self.m_name = name
end

-- 获取链接的名称（用途）
function TcpClient:getName()
    return self.m_name
end

-- 创建tcp连接
function TcpClient:createTcp()
    if not self.socket then
        local socket, error = self:createSocket()
        if socket then
            self.socket = socket
        else
            printError(error)
        end
    end
end

-- 开启计时器
function TcpClient:createTimer()
    if not self.scheduleId then
        self.scheduleId = sharedScheduler:scheduleScriptFunc(handler(self, self.update), 0.1, false)
    end
end

-- 获取消息实体
function TcpClient:createSocket()
    local addrinfo, err = socket.dns.getaddrinfo(self.ip)
    if not addrinfo then
        return nil, err
    end

    local sock, err
    err = "获取地址信息失败"
    for i,alt in ipairs(addrinfo) do
        if alt.family == "inet" then
            sock, err = socket.tcp()
            break
        elseif alt.family == "inet6" then
            sock, err = socket.tcp6()
            break
        end
    end

    if not sock then
        return sock, err
    end
    
    sock:setoption("keepalive",true)
    sock:setoption("tcp-nodelay",true)
    sock:settimeout(0)

    return sock
end

-- 建立连接
function TcpClient:connect()
    if not self.socket then
        self:createTcp()
    end

    local success,status = self.socket:connect(self.ip,self.port)
    if success or status == TcpNetConfig.LINK_MSG.CONNECTED then   -- 注意 这里的判定是socket返回的状态
        self:changeState(TcpNetConfig.LINK_STATE.ON_CONNECT)
    else
        if self:getState() ~= TcpNetConfig.LINK_STATE.TRY_CONNECT then
            self:changeState(TcpNetConfig.LINK_STATE.TRY_CONNECT)
        end
        
    end

    if not self.scheduleId then
        self:createTimer()
    end
    
    -- sharedScheduler:resumeTarget(self)
end

-- 网络重连 
function TcpClient:reConnect()
    self:connect()
end

function TcpClient:closeConnect()
    if self.socket then
        self.socket:close()
        self.socket = nil
    end
end

function TcpClient:checkConnecting()
    if self.socket then
        -- local success,status = self.tcpSocket:connect(self.ip,self.port)
		-- if success or status == kSQTcpClient_ConnectMsg_HasConnected then
		-- 	self:__setNetState(kSQTcpClient_TcpState_Connected)
		-- else
		-- 	local timeout = socket.gettime() - self.connectStartTime
		-- 	if (status == kSQTcpClient_ConnectMsg_TimeOut or status == kSQTcpClient_ConnectMsg_Connneting) and 
		-- 		timeout < SQGlobalCfg.netTimeOutTime then
		-- 			self:__setNetState(kSQTcpClient_TcpState_Connecting)
		-- 	--超时
		-- 	else
		-- 		self:__closeConnect(kSQTcpClient_TcpState_ConnectTimeOut)
		-- 	end
		-- end
    end
end

-- 定时刷新连接状态
function TcpClient:update()
    if self:getState() == TcpNetConfig.LINK_STATE.DISCONNECT 
        or self:getState() == TcpNetConfig.LINK_STATE.CLOSE_CONNECT then
            return
    end
    
    if self:getState() == TcpNetConfig.LINK_STATE.TRY_CONNECT then
        local success,status = self.socket:connect(self.ip,self.port)
        if success or status == TcpNetConfig.LINK_MSG.CONNECTED then
            self:changeState(TcpNetConfig.LINK_STATE.ON_CONNECT)
        end
    elseif self:getState() == TcpNetConfig.LINK_STATE.ON_CONNECT then
        self:receive()
    elseif self:getState() == TcpNetConfig.LINK_STATE.TIME_OUT then
        self:changeState(TcpNetConfig.LINK_STATE.TRY_CONNECT)
    end
    
end

-- 获取连接状态
function TcpClient:getState()
    return self._state
end

-- 设置状态
function TcpClient:setState( state )
    self._state = state
end

-- 切换状态
function TcpClient:changeState( state )
    if state == self._state then
        return
    end

    self:setState(state)
    -- 各种状态的处理逻辑
    if state == TcpNetConfig.LINK_STATE.DISCONNECT then
        self:closeConnect()
    elseif state == TcpNetConfig.LINK_STATE.TRY_CONNECT then
        self:connect()
    elseif state == TcpNetConfig.LINK_STATE.ON_CONNECT then

    elseif state == TcpNetConfig.LINK_STATE.TIME_OUT then

    elseif state == TcpNetConfig.LINK_STATE.CLOSE_CONNECT then
        self:setState(TcpNetConfig.LINK_STATE.DISCONNECT)
    end
end

function TcpClient:send( msg )
    if self:getState() == TcpNetConfig.LINK_STATE.ON_CONNECT then
        while #msg > 0 do
            local splitMsg = string.sub(msg, 1, TcpNetConfig.buffer_size)
            msg = string.sub(msg, TcpNetConfig.buffer_size + 1, #msg)
            if #splitMsg > 0 then
                local num, err, num2 = self.socket:send(splitMsg)
                if err then
                    -- 连接失败
                    self:changeState(TcpNetConfig.LINK_STATE.DISCONNECT)
                    return false
                end
            end
        end
    else
        self:changeState(TcpNetConfig.LINK_STATE.TRY_CONNECT)
    end
end

function TcpClient:receive()
    if not self.socket then
        return
    end

    -- 接收数据
    local recvData = ""
    while true do
        local body,status,partial = self.socket:receive("*a")
        if status == TcpNetConfig.LINK_MSG.CLOSED or status == TcpNetConfig.LINK_MSG.DISCONNECT then
            self:changeState(TcpNetConfig.LINK_STATE.CLOSE_CONNECT)
            break
        end
        
        if partial then
            recvData = recvData .. partial
        end
        if (body and string.len(body) == 0) or
            (partial and string.len(partial) == 0) then
            break
        end
    end
    if recvData and recvData ~= "" then
        print("recvData " .. recvData)
        local TcpNetManager = require("network.socket_tcp.TcpNetManager")
        TcpNetManager:getInstance():onReceive(recvData)
    end
    
    -- gApp:getMsgDispatcher():broadcastMsg(kSQGlobalMsgType_Net,kSQTcpClient_NetMsg_RecvData,recvData)
end

function TcpClient:setOnReceivedCall( func )
    self.m_onReceivedCall = func
end

function TcpClient:onExit()
    self:closeConnect()
end

return TcpClient