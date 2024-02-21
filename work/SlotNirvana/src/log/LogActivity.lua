
-- 大活动的日志控制器(整合了 餐厅 大富翁 blast 推币机 集字 等活动)
-- 适用于统一日志模板的大活动

local NetworkLog = require "network.NetworkLog"
local LogActivity = class("LogActivity", NetworkLog)

local ACT_CONFIG = {
	[ACTIVITY_REF.DinnerLand] = {
		key_name = "DinnerLand",
		event_name = "CookPopup",
	},
	[ACTIVITY_REF.RichMan] = {
		key_name = "RichMan",
		event_name = "RichmanPopup",
	},
	[ACTIVITY_REF.Blast] = {
		key_name = "Blast",
		event_name = "BlastPopup",
	},
	[ACTIVITY_REF.CoinPusher] = {
		key_name = "CoinPusher",
		event_name = "PusherPopup",
	},
	[ACTIVITY_REF.Word] = {
		key_name = "Word",
		event_name = "WordPopup",
	},
	[ACTIVITY_REF.NewCoinPusher] = {
		key_name = "NewCoinPusher",
		event_name = "NewPusherPopup",
	},
	[ACTIVITY_REF.EgyptCoinPusher] = {
		key_name = "EgyptCoinPusher",
		event_name = "EgyptPusherPopup",
	},
}

-- local logData = {
-- 	et 		= "",	-- lobby, gamelevel 活动所属场景
-- 	en 		= "",	-- 推送, 升级, 点击按钮等 触发当前页面的情景
-- 	tp 		= "",	-- Open, Click 事件类型
-- 	pn 		= "",	-- 当前页面名称
-- 	eo 		= "",	-- TapOpen, PushOpen 触发当前页面的方式

-- 	name 	= "",	-- 活动名称 key_name .. yyyymmdd
-- 	day 	= "",	-- 活动进行到第几天
-- 	s 		= "",	-- 活动进行到第几轮
-- 	rd 		= "",	-- 活动当前章节
-- }

function LogActivity:ctor()
    NetworkLog.ctor(self)
	self.act_type = nil 
    self.logData = {}
	self.connent = false
end

function LogActivity:setConnect()
	self.connent = true
end

function LogActivity:isConnect()
	return self.connent
end

function LogActivity:setActivityType( _type )
    if _type then
        self.act_type = _type
    end
end

function LogActivity:clear()
    self.logData = {}
    self.recordData = {}
    self.act_type = nil
	self.connent = false
end

-- 注意 这个方法处理的是非操作的弹出(自动弹出方式)
-- _type 活动类型
-- pn 推送页面名称
-- en 触发当前页面的情景 大厅推送loginLobbyPush, 关卡升级levelUpPush, 定时弹出autoPop等
-- eo 触发当前页面的方式 PushOpen
function LogActivity:onPopup(_type, pn, en)
	if self:isConnect() then
		self.logData = clone(self.recordData)
		-- 替换部分信息
		-- self:setActivityType(_type)
		-- self.logData.en = en
		-- self.logData.pn = pn
	else
		self:clear()

		self:setActivityType(_type)
		local entryData = gLobalSendDataManager:getLogIap().m_entryInfo or {}
		self.logData.et = entryData.entryType
		self.logData.en = en
		self.logData.pn = pn
		self.logData.tp = "Open"
		self.logData.eo = "PushOpen"
	
		self.recordData = clone(self.logData)
	end

    self:onEvent()
end

-- click 现阶段只做信息记录 不会发送日志 如果要发送日志 需要指定 pn
-- en 触发点击事件的名称
function LogActivity:onClick(_type, en)
	self.connect = true
	if self:isConnect() then
		self:setActivityType(_type)
		self.logData = clone(self.recordData)
		-- 替换部分信息
		self.logData.en = en
	else
		-- -- 先清空一下数据
		-- self:clear()

		self.connect = false
		self:setActivityType(_type)

		local entryData = gLobalSendDataManager:getLogIap().m_entryInfo or {}
		self.logData.et = entryData.entryType
		self.logData.en = en
		self.logData.tp = "Click"
		-- self.logData.pn = pn	-- 当前页面名称
		self.logData.eo = "TapOpen"
	end
end

-- 注意 这个方法处理的是认为操作的弹出(玩家手动打开)
-- pn 打开页面名称
function LogActivity:onOpen(_type, pn)
	if self:isConnect() then
		self.logData = clone(self.recordData)
		-- 替换部分信息
		-- self:setActivityType(_type)
		-- self.logData.en = en
		-- self.logData.pn = pn
	else
		self:clear()

		self:setActivityType(_type)

		local entryData = gLobalSendDataManager:getLogIap().m_entryInfo or {}
		self.logData.et = entryData.entryType
		-- self.logData.en = en	-- 推送, 升级, 自动弹出, 点击按钮等 触发当前页面的情景
		self.logData.tp = "Click"
		self.logData.pn = pn
		self.logData.eo = "TapOpen"
	
		self.recordData = clone(self.logData)
	end

    self:onEvent()

end

-- 检查数据的完整性
function LogActivity:checkLogData()
	if not self.act_type then
		ptintError("LogActivity 活动类型未指定")
		return
	end
	
	local config_data = ACT_CONFIG[self.act_type]
	if not config_data then
		ptintError("LogActivity 活动配置不明确")
		return
	end

	local gameData = G_GetActivityDataByRef(self.act_type)
	if not gameData or not gameData:isRunning() then
		printInfo("LogActivity 活动未开启或已关闭 不能发送日志")
		return
	end

	assert(gameData.getSequence, "LogActivity 需要数据类型实现 getSequence 方法 获取当前活动进行到第几轮的数据")
	assert(gameData.getCurrent, "LogActivity 需要数据类型实现 getCurrent 方法 获取当前活动进行到第几章节的数据")

	if not self.logData
		or not self.logData.tp 
		or not self.logData.pn 
		or not self.logData.et 
		or not self.logData.en 
		or not self.logData.eo then
			return false
	end
	return true
end

-- 发送日志接口
function LogActivity:onEvent()
	if not self:checkLogData() then
		dump(self.logData, "logData", 2)
		printError("LogActivity 发送日志失败 数据不完整")
		return
	end
	-- 私有方法 玩不不要调用
	self._sendPageLog()
end

-- 发送日志
function LogActivity:_sendPageLog()
	local config_data = ACT_CONFIG[self.act_type]
	local key_name = config_data.key_name
	local event_name = config_data.event_name

	local gameData = G_GetActivityDataByRef(self.act_type)
	self.logData.name = key_name .. self:formatActivityTime(gameData.p_start)
	self.logData.day = self:getDay(gameData.p_start)			-- 天数向上取整
	self.logData.s = tonumber(gameData:getSequence())  	        -- 活动轮数
	self.logData.rd = gameData:getCurrent() 					-- 第几关

	gL_logData:syncEventData(event_name)
	gL_logData.p_data = clone(self.logData)
	self.logData = {}		-- 清空记录
	self:sendLogData()		-- 发送
end

-- 活动开启日期
function LogActivity:formatActivityTime(activityTime)
    if not activityTime then
        return ""
    end
    local year = string.sub(activityTime, 1, 4)
    local month = string.sub(activityTime, 6, 7)
    local day = string.sub(activityTime, 9, 10)
    return year .. month .. day
end

-- 活动进行到第几天
function LogActivity:getDay(startTime)
	local curTime = globalData.userRunData.p_serverTime / 1000
	return math.ceil( (curTime - util_getymd_time(startTime)) / 86400 ) -- 天数向上取整
end

return LogActivity
