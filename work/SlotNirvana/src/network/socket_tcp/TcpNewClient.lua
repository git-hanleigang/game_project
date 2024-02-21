
-- tcp消息连接
local TcpNetConfig = require("network.socket_tcp.TcpNetConfig")
local TcpNewClient = class("TcpNewClient")
TcpNewClient.m_name = nil		--名字唯一ID
TcpNewClient.m_host = nil			--IP地址
TcpNewClient.m_port = nil		--端口
TcpNewClient.m_updateFunc = nil	--更新状态
TcpNewClient.m_isConnect = nil	--是否连接成功
TcpNewClient.m_tcpSocket = nil	--句柄
TcpNewClient.m_isDeleted = nil	--是否已经删除
local DEBUG_LOG_FLAG = true		--测试打印

function TcpNewClient:ctor()

end
--"172.16.4.64", 9005  reconnectSocket
--初始化
function TcpNewClient:init(name,host,port,updateFunc)
	self.m_name = name						--名字唯一ID
	self.m_host = host							--IP地址
	self.m_port = port						--端口
	self.m_updateFunc = updateFunc			--更新状态
	self.m_isConnect = nil					--是否连接成功
	self.m_tcpSocket = self:createSocket()	--句柄
	self.m_isDeleted = nil
	self.m_reConnectMaxCount = 1 				-- 重连次数
end
--创建socket
function TcpNewClient:createSocket()
	local tcpSocket = xcyy.XCTcpClient:create(self.m_host, self.m_port)
	tcpSocket:setSocketStateCallBack(handler(self,self.onSocketStateCallBack))
	tcpSocket:setRecvMsgCallBack(handler(self,self.onRecvMsgCallBack))
	tcpSocket:setErrorCallBack(handler(self,self.onErrorCallBack))
	tcpSocket:createSocket()
	return tcpSocket
end

function TcpNewClient:clearData()
	if self.m_tcpSocket then
		self.m_tcpSocket:release()
		self.m_tcpSocket = nil
	end
	self.m_isDeleted = true
end

--获取状态
function TcpNewClient:getSocketState()
	if not self.m_tcpSocket then
		return TcpNetConfig.XCTCP_STATUS.CLOSED
	end

	return self.m_tcpSocket:getSocketState()
end

--断线重连
function TcpNewClient:reconnectSocket()
	if self.m_isDeleted then
		return
	end

	if self.m_reConnectMaxCount <= 0 then
		-- self.m_updateFunc(self.m_name, TcpNetConfig.UPDATE_STATUS.GO_CLOSE)
		self:printLog(string.format("cxc--socket--断线重连失败了去切换地址--%s", string.format("%s:%s",self.m_host, self.m_port)))
		if DEBUG == 0 then
			util_sendToSplunkMsg("TeamSocketErrorLog", string.format("断线重连失败了去切换地址--%s", string.format("%s:%s",self.m_host, self.m_port)))
		end
		self.m_updateFunc(self.m_name, TcpNetConfig.UPDATE_STATUS.TRY_NEXT_ADDRESS)
		return
	end

	--这里需要检查状态
	if self:getSocketState() ~= TcpNetConfig.XCTCP_STATUS.CONNECTING then
		self.m_tcpSocket:reconnectSocket()
		self.m_reConnectMaxCount = self.m_reConnectMaxCount - 1
		self:printLog(string.format("cxc--socket--断线重连中--%s", string.format("%s:%s",self.m_host, self.m_port)))
	end
end
--发送消息
function TcpNewClient:sendStringMessage(msgID,response)
	if self.m_isDeleted then
		return
	end
	if not self.m_isConnect then
		return
	end
	self.m_tcpSocket:sendStringMessage(msgID,response)
end
--连接成功
function TcpNewClient:onSocketStateCallBack(stateMsg)
	if self.m_isDeleted then
		return
	end
	local stateInfo = loadstring(stateMsg)()
	local state = stateInfo.state
	printLog("--------------------------onSocketStateCallBack state = " .. tostring(state))
	--关闭
	if state == TcpNetConfig.XCTCP_STATUS.CLOSED then
		self.m_isConnect = false
		-- 心跳里边回去检测 不要频繁去重连
		-- self:reconnectSocket()
	--连接成功
	elseif state == TcpNetConfig.XCTCP_STATUS.CONNECTED then
		self.m_isConnect = true
		self.m_reConnectMaxCount = 3 				-- 重连次数
		self.m_updateFunc(self.m_name,TcpNetConfig.UPDATE_STATUS.CONNECTED,self.m_isConnect)
		self:printLog(string.format("cxc--socket--连接上了--%s", string.format("%s:%s",self.m_host, self.m_port)))
	end
end
--返回消息
function TcpNewClient:onRecvMsgCallBack(msgID,netMsg)
	if self.m_isDeleted then
		return
	end
	printLog("--------------------------onRecvMsgCallBack msgID = "..msgID)
	local strNetMsg = self:parseSocktNetMsg(netMsg)
	local response = {}
	response.msgId = msgID
	response.data = strNetMsg
	if #netMsg ~= #strNetMsg then
		if #strNetMsg > 0 then
			self:sendSocketLog(netMsg, strNetMsg)
		end
		return
	end
	printLog("--------------------------onRecvMsgCallBack strNetMsg = "..strNetMsg)
	self.m_updateFunc(self.m_name,TcpNetConfig.UPDATE_STATUS.RECEIVE,response)
end

function TcpNewClient:parseSocktNetMsg(netMsg)
	local strNetMsg = ""
	xpcall(
		function()
			local curCount = #netMsg
			local msgList = {}
			local maxCount = 2048
			local startIndex = 1
			while curCount>maxCount do
				local endIndex = startIndex+maxCount-1
				strNetMsg = strNetMsg .. string.char(unpack(netMsg,startIndex,endIndex))
				startIndex = startIndex + maxCount
				curCount = curCount - maxCount
			end
			if curCount>0 then
				local endIndex = startIndex+curCount-1
				strNetMsg = strNetMsg .. string.char(unpack(netMsg,startIndex,endIndex))
			end
		end,
		function()
			strNetMsg = ""
			self:sendSocketLog(netMsg)
		end
	)

	return strNetMsg
end

function TcpNewClient:sendSocketLog(netMsg, strNetMsg)
	if not netMsg then
		return
	end

	local logInfo = {}
	logInfo["logName"] = "CLIENT_SOCKET_TEST"
	logInfo["logType"] = strNetMsg and "1" or "2" 
	if strNetMsg then
		logInfo["destNetMsgCount"] = #strNetMsg
		logInfo["destMsg"] = strNetMsg
	end	
	logInfo["sourceNetMsgCount"] = #netMsg
	local sourceMsg = ""
	for i=1, #netMsg do
		local byteInt = netMsg[i]
		local formatStr = "%d,"
		if i== #netMsg then
			formatStr = "%d"
		end
		sourceMsg = sourceMsg .. string.format(formatStr, byteInt)
	end
	logInfo["sourceMsg"] = sourceMsg

	local logStr = cjson.encode(logInfo)
	release_print("cxc-----socketpushLog----------" .. logStr)
	util_sendToSplunkMsg("SocketTestLog", logStr)
end

--返回错误信息
function TcpNewClient:onErrorCallBack(errorMsg)
	if self.m_isDeleted then
		return
	end
	printLog("--------------------------onErrorCallBack errorMsg = "..errorMsg)
	self.m_updateFunc(self.m_name,TcpNetConfig.UPDATE_STATUS.ERROR,errorMsg)
	
	-- 错误
	self:sendSocketErrorLog(errorMsg)
end

-- socket链接错误报送
function TcpNewClient:sendSocketErrorLog(_errorMsg)
	local errorInfo = loadstring(_errorMsg)()
	if type(errorInfo) ~= "table" then
		return
	end
	-- "return {type = %d,code = %d,sockID = %d,state = %d,msg = \"%s\"}"
	-- enum class XCTcpErrorType
    -- {
    --     CREATESOCKET,
    --     CONNECTSOCKET,
    --     SENDMESSAGE,
    --     RECVMESSAGE
    -- };
	if errorInfo.type ~= 0 and errorInfo.type ~= 1 then
		return
	end

	if errorInfo.type == 1 and errorInfo.code == 2 then
		-- isStopAllThread 现成已停的不用管
		return
	end

	if self.m_reConnectMaxCount ~= 3 then
		-- 中途断线重连 不换地址
		return
	end
	if DEBUG == 0 then
		util_sendToSplunkMsg("TeamSocketErrorLog", string.format("socket连接失败了去切换地址--%s", string.format("%s:%s",self.m_host, self.m_port)))
	end
	self:printLog(string.format("cxc--socket--连接失败了去切换地址--%s", string.format("%s:%s",self.m_host, self.m_port)))
	self.m_updateFunc(self.m_name, TcpNetConfig.UPDATE_STATUS.TRY_NEXT_ADDRESS)
end
--打印信息
function TcpNewClient:printLog(msg)
	if not DEBUG_LOG_FLAG or not msg then
		return
	end
	release_print(msg)
	print(msg)
end
return TcpNewClient