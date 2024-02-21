
-- tcp消息管理器
local ChatConfig = require("data.clanData.ChatConfig")
local ClanManager = util_require("manager.System.ClanManager"):getInstance()
local TcpNetConfig = require("network.socket_tcp.TcpNetConfig")
local TcpNewClient = require("network.socket_tcp.TcpNewClient")
local TcpNewManager = class("TcpNewManager")
function TcpNewManager:getInstance()
    if not self._instance then
		self._instance = TcpNewManager.new()
		self._instance:init()
    end
    return self._instance
end

function TcpNewManager:init()
	self.m_socketList = {}
	self.m_checkSocketAddressList = {}
end

function TcpNewManager:clearSocket(name)
	if name and self.m_socketList[name] then
		self.m_socketList[name]:clearData()
		self.m_socketList[name] = nil
	end
end

function TcpNewManager:reConnect(name)
	if name and self.m_socketList[name] then
		self.m_socketList[name]:reconnectSocket()
	end
end

function TcpNewManager:checkConnectClient(name,connectFunc)
	if not name then
		return
	end
	self.m_connectFunc = connectFunc
	if not self.m_socketList[name] then
		local serverInfo = TcpNetConfig.SERVER_LIST[name]
		assert(serverInfo and serverInfo.host and serverInfo.port, "服务器配置错误")
		self.m_socketList[name] = TcpNewClient.new()
		self.m_socketList[name]:init(name,serverInfo.host, serverInfo.port,handler(self,self.updateSocketStatus))
	end
end
--更新状态
function TcpNewManager:updateSocketStatus(name,status,response)
	if status == TcpNetConfig.UPDATE_STATUS.CONNECTED then
		self:onConnectedCallBack(name,response)
	elseif status == TcpNetConfig.UPDATE_STATUS.RECEIVE then
		self:onRecvMsgCallBack(name,response)
	elseif status == TcpNetConfig.UPDATE_STATUS.ERROR then
		self:onErrorCallBack(name,response)
	elseif status == TcpNetConfig.UPDATE_STATUS.GO_CLOSE then
		gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ClOSE_CLEAR_TCP, name)
	elseif status == TcpNetConfig.UPDATE_STATUS.TRY_NEXT_ADDRESS then
		gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ClOSE_CLEAR_TCP, name)
		self:onTryConnectNextAddress(name)
	end
end
--连接回调
function TcpNewManager:onConnectedCallBack(name,isConnected)
	if self.m_connectFunc then
		self.m_connectFunc(name,isConnected)
	end
end
--接受消息回调
function TcpNewManager:onRecvMsgCallBack(name,response)
	if name == "clan_chat" then
		--聊天信息
		gLobalNoticManager:postNotification(ChatConfig.EVENT_NAME.NOTIFY_CLAN_CHAT_REFCEIVE, response)
	end
end
--失败回调
function TcpNewManager:onErrorCallBack(name,errorMsg)
	local errorMsgInfo = loadstring(errorMsg)()
	if type(errorMsgInfo) ~= "table" then
		return
	end
	-- "return {type = %d,code = %d,sockID = %d,state = %d,msg = \"%s\"}"
	-- socket报错断链顺便切换下地址吧，看另一个地址有没有问题 (发送和接收 检测的数据<= 0在考虑换地址)
	if (errorMsgInfo.type == 2 or errorMsgInfo.type == 3) and errorMsgInfo.code == 6 then
		local logStr = cjson.encode(errorMsgInfo)
		-- util_sendToSplunkMsg("SocketErrorLog", logStr)
		self:updateSocketStatus(TcpNetConfig.SERVER_KEY.CLAN_CHAT, TcpNetConfig.UPDATE_STATUS.TRY_NEXT_ADDRESS)
	end
end
function TcpNewManager:onTryConnectNextAddress(_name)
	if not TcpNetConfig.SERVER_LIST_NEW or not TcpNetConfig.SERVER_LIST_NEW[_name] then
		-- self:updateSocketStatus(_name, TcpNetConfig.UPDATE_STATUS.GO_CLOSE)
		return
	end

	self:clearSocket(_name)
	self:updateCheckAddressCount(_name)
	if self.m_checkSocketAddressList[_name] > (#TcpNetConfig.SERVER_LIST_NEW[_name]*2) then
		self.m_checkSocketAddressList[_name] = 0
		-- self:updateSocketStatus(_name, TcpNetConfig.UPDATE_STATUS.GO_CLOSE)
		if DEBUG == 0 then
			util_sendToSplunkMsg("TeamSocketErrorLog", "socket列表循环了2遍还是连不上！！！")
		end
		util_printLog(string.format("cxc--socket--列表循环了2遍还是连不上，看看自己的网吧"), true)
		ClanManager:requestHttpChatInfo()
		return
	end
	local host, port = self:getNewserverInfo(_name) 
	util_printLog(string.format("cxc--socket--切换新地址--%s", string.format("%s:%s", host, port)), true)
	if not host or not port then
		-- self:updateSocketStatus(_name, TcpNetConfig.UPDATE_STATUS.GO_CLOSE)
		util_printLog(string.format("cxc--socket--切换地址, 服务器给的地址不合法啊，不连了"), true)
		return
	end
	self.m_socketList[_name] = TcpNewClient.new()
	self.m_socketList[_name]:init(_name, host, port,handler(self,self.updateSocketStatus))
end
--发送消息
function TcpNewManager:sendMessage(name,msgID,body)
	if name and self.m_socketList[name] then 
		self.m_socketList[name]:sendStringMessage(msgID,body)
	end
end


function TcpNewManager:getSocketState(name)
    if name and self.m_socketList[name] then 
		return self.m_socketList[name]:getSocketState()
	end
end

-- 换新的地址次数
function TcpNewManager:updateCheckAddressCount(_name)
	if not self.m_checkSocketAddressList then
		self.m_checkSocketAddressList = {}
	end
	if not self.m_checkSocketAddressList[_name] then
		self.m_checkSocketAddressList[_name] = 0
	end
	self.m_checkSocketAddressList[_name] = self.m_checkSocketAddressList[_name] + 1
end

-- 获取 链接地址 host port
function TcpNewManager:getNewserverInfo(_name)
	-- repeated ClanChatServer chatServers = 4; //chatServers  (二维数组)
    -- message ClanChatServer {
    --     repeated string servers = 1; //servers
    --   }
	local serverInfoList = TcpNetConfig.SERVER_LIST_NEW[_name] or {} -- 二维数组
	if #serverInfoList == 0 then
		return
	end
	local idx = self.m_checkSocketAddressList[_name] % #serverInfoList + 1
	local clanChatServerData = serverInfoList[idx] or {}
	local serverInfoArr = clanChatServerData.servers or {}
	local addressStr = serverInfoArr[util_random(1, #serverInfoArr)] or ""
	local host = string.split(addressStr, ":")[1]
	local port = string.split(addressStr, ":")[2]
	return host, port
end

return TcpNewManager