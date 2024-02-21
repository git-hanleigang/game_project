
-- tcp消息管理器

local TcpNetConfig = require("network.socket_tcp.TcpNetConfig")
local TcpClient = require("network.socket_tcp.TcpClient")
local TcpNetManager = class("TcpNetManager")

function TcpNetManager:getInstance()
    if not self._instance then
		self._instance = TcpNetManager.new()
		self._instance:init()
    end
    return self._instance
end

-- 初始化相关
function TcpNetManager:init()
	self.m_clientList = {}
	self:__setSeqID(0)
	self:__setRecvData("")
end

function TcpNetManager:__setSeqID( id )
	self.seqID = id
end

function TcpNetManager:__addSeqID()
	self:__setSeqID(self.seqID + 1)
end

-- 初始化Tcp消息体 初始化几个备用？
function TcpNetManager:createTcpClient( key, ip, host )
	if not key or key == "" then
		printInfo("------>    TcpNetManager:createTcpClient 创建一个不明用途的链接，最好不要这样做。")
		key = "default"
		return
	end

	self.m_clientList[key] = TcpClient.new(ip, host)
	if not self.m_clientList[key] then
		printError("创建tcp链接出错")
		return
	end
	
	self.m_clientList[key]:connect()
	return self.m_clientList[key]
end

function TcpNetManager:closeTcpClient( key )
	if not key or key == "" then
		return
	end

	if not self.m_clientList or not self.m_clientList[key] then
		return
	end
	
	self.m_clientList[key]:closeConnect()	
end

-- TODO 没有空闲的就新建 
function TcpNetManager:getClient( key )
	if not key or key == "" then
		printInfo("------>    TcpNetManager:getClient 获取一个位置用途的链接，将返回一个默认的client。")
		key = "default"
	end

	if self.m_clientList and self.m_clientList[key] then
		local state = self.m_clientList[key]:getState()
		if state ~= TcpNetConfig.LINK_STATE.TRY_CONNECT or state ~= TcpNetConfig.LINK_STATE.ON_CONNECT then
			self.m_clientList[key]:connect()
		end
		return self.m_clientList[key]
	end
    -- if not self.m_clientList or not self.m_clientList[key] then
	-- 	return self:createTcpClient(key)
	-- else
	-- 	return self.m_clientList[key]
	-- end
end

function TcpNetManager:getClientReady( key )
	if self.m_clientList[key] then
		return self.m_clientList[key]:getState() == TcpNetConfig.LINK_STATE.ON_CONNECT
	end 
end

-- 发消息
function TcpNetManager:sendMessage(key,msgID,msgInfo)
	local packetData = self:packet(msgID,msgInfo)
	local client = self:getClient(key)
	if not client then
		printInfo("TcpNetManager 没有正确的消息链接 啥也干不了")
		return
	end
	if client:getState() == TcpNetConfig.LINK_STATE.ON_CONNECT then
		local bl_success = client:send(packetData)
		if bl_success == false then
			-- 发送失败的处理
		end
	end
end

-- 收消息
function TcpNetManager:onReceive(data)
	-- 处理指令
	local dataLen = #data
	if dataLen > 0 or #self.recvData > 4 then
		self:__addRecvData(data)
		local recvData = s
		local count = 0 -- 最多处理10条就跳出来，省得卡死
		while #self.recvData >= 4 and count < 10 do
			local length = SQTools.readint(self.recvData,1)
			-- length = kSQNetManager_MathTools:SQF_xorOp(length,2018)
			if #self.recvData <= length then
				break
			end
			count = count + 1
			self:unpacket(self.recvData)
		end
	end
end

function TcpNetManager:__setRecvData(data)
	self.recvData = data
end

function TcpNetManager:__addRecvData(data)
	self.recvData = self.recvData..data
end

-- 装包 组装一个可以发给服务器的数据包
function TcpNetManager:packet( msgId, msgData )
	if not msgId or not msgData then
		printError("TcpNetManager:packet 数据检查出错")
		return
	end

	local msgLen = string.len(msgData)

	local char_table = {}
	for i=1,msgLen do
        table.insert(char_table, string.byte(string.sub(msgData, i, i)))
    end
	local rc4_table = xcyy.SlotsUtil:getRC4ValueFromBin(char_table)
	local encryptMsgData = ""
	for i=1,#rc4_table do
		encryptMsgData = encryptMsgData .. string.char(rc4_table[i])
	end
	-- local msgDataLen = kSQNetManager_MathTools:SQF_xorOp(realMsgLen,2018)
	self:__addSeqID()

	local totalLen = 2 + 4 + 1 + 1 + 8 + msgLen			-- 数据流2-7的长度
	local title_ret = ""
	local xx = SQTools.num2int(totalLen)
	for i=1,#xx do
		print(xx[i])
	end
	title_ret = title_ret .. SQTools.num2int(totalLen) .. SQTools.num2short(msgId) .. SQTools.num2int(self.seqID)

	local crc_table = {}
	for i=1,#title_ret do
		local a = title_ret[i]
		table.insert(crc_table, a)
	end
	for i=1,#char_table do
		table.insert(crc_table, char_table[i])
	end
	local crcData = xcyy.SlotsUtil:getCRCValueFromBin(char_table)
	-- 数据流
	-- * 1、协议长度(4字节)
	-- * 2、消息ID(2字节)
	-- * 3、包序号(4字节)
	-- * 4、冗余字段(1字节)
	-- * 5、压缩标志(1字节)
	-- * 6、crc32值(协议长度+消息ID+包序号+协议内容)(8个字节)
	-- * 7、协议内容(读取协议长度)
	local ret = ""
	ret = ret .. SQTools.num2int(totalLen)				-- msessage length
	ret = ret .. SQTools.num2short(msgId)				-- message id
	ret = ret .. SQTools.num2int(self.seqID)			-- sequence id
	ret = ret .. SQTools.num2byte(0)					-- empty a byte
	ret = ret .. SQTools.num2byte(0)					-- flag for compress and etc.
	ret = ret .. SQTools.num2long(crcData)				-- crc32 value
	ret = ret .. encryptMsgData
	return ret
end

-- 解包 拆解出一个客户端使用的数据结构
function TcpNetManager:unpacket(recvData)
    -- * 1.协议长度(4字节)
	-- * 2.消息ID(2字节)
	-- * 3.包序(4字节)
	-- * 4.压缩标志(1字节)0:压缩1:没压缩
	-- * 5.crc32值(长度+消息ID+包序号+协议内容)(8字节)
	-- * 6.协议内容(读取协议长度)
	local msgDataLen = SQTools.readint(recvData, 1)
	-- msgDataLen = kSQNetManager_MathTools:SQF_xorOp(msgDataLen,2018)
	local msgID = SQTools.readshort(recvData, 1 + 4)
	local seqId = SQTools.readint(recvData, 1 + 4 + 2)
	local zipFlag = SQTools.readbyte(recvData, 1 + 4 + 2 + 4)
	local recvCRCData = SQTools.readlong(recvData, 1 + 4 + 2 + 4 + 1)
	local dataOffset = 1 + 4 + 2 + 4 + 1 + 8
	local encryptMsgData = string.sub(recvData,dataOffset,dataOffset + msgDataLen - 1)
	
	local msgData = xcyy.SlotsUtil:getRC4ValueFromBin(encryptMsgData)
	local crcCheckData = tostring(msgDataLen)..tostring(msgID)..tostring(seqId)..msgData
	local crcData = xcyy.SlotsUtil:getCRCValueFromBin(crcCheckData)
	-- local strMsgID = SQProtoStrMessageID[msgID]
	-- local msgName = SQProtoS2C[strMsgID]
	-- if msgName == nil then
	-- 	SQLog.e(string.format("msg mapping error msgID = %d,strMsgID = %s",msgID,strMsgID))
	-- end
	-- local protoClassName = "net_protocol.".. (msgName or "")
	-- local responseData = protobuf.decode(protoClassName,msgData)
	-- if responseData ~= nil and type(responseData) == "table" then
	-- 	local recvHopeMsgFlag = self.protoSendInfo:recvMsg(msgID,responseData)
	-- 	--处理接收到等待的消息
	-- 	if recvHopeMsgFlag then
	-- 		SQUITools.closeWaitting()
	-- 	end
		self:__setRecvData(string.sub(recvData,dataOffset + msgDataLen))
	-- 	gApp:handleNetMsg(msgID,responseData)
	-- end
	--CRC校验不一致
	if crcData ~= recvCRCData then
		printError("TcpNetManager:unpacket 检测数据不一致")
		return
	end

	dump(msgData, "msgData")

end

function TcpNetManager:sequenceId(  )
    
end

return TcpNetManager