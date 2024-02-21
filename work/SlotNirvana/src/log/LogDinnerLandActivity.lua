--
-- Author:  刘阳
-- Date:    2019-08-03
-- Desc:    餐厅打点


local NetworkLog = require "network.NetworkLog"
local LogDinnerLandActivity = class("LogDinnerLandActivity", NetworkLog)


function LogDinnerLandActivity:ctor()
    NetworkLog.ctor(self)
end



-- 新手引导打点
function LogDinnerLandActivity:sendGuideLog( guideName )
	local gameData = G_GetActivityDataByRef(ACTIVITY_REF.DinnerLand)
	if not gameData or not gameData:isRunning() then
		return
	end
	local log_data = {}
	log_data.tp = "Open"
	log_data.name = "DinnerLand" .. self:formatActivityTime(gameData.p_start)
	log_data.day = gameData:getDay()						-- 第几天
	log_data.s = tonumber(gameData:getSequence()) - 1000  	-- 活动轮数
	
	log_data.rd = gameData:getCurrent() 					-- 第几关
	log_data.pn = guideName
	gL_logData:syncEventData("CookNewGuide")
	gL_logData.p_data = log_data
    -- globalPlatformManager:checkSendFireBaseLog(log_data)
    self:sendLogData()
end


--[[
	pageName:推送宣传页=PushPage,关卡选择界面=RoundPage,活动界面=ActivityPage
	enterType:大厅=lobby,游戏关卡=gameName,邮箱=inbox邮箱
	entryName:1:大厅lobby:(大厅下UI-comingsoon=downActivtyIcon 大厅区-轮播图=lobbyCarousel) 2:关卡内gameName:、游戏区-quest活动=gameToQuestIcon
	entryOpen:点击打开=TapOpen,推送打开=PushOpen
	pageOpenType:界面打开方式
]]
function LogDinnerLandActivity:sendPageLog( pageName,pageOpenType,entryType )
	assert( pageName," !! pageName is nil !! " )
	assert( pageOpenType," !! pageOpenType is nil !! " )
	local entryData = gLobalSendDataManager:getLogIap().m_entryInfo or {}
	local enterType = entryData.entryType
	local entryName = entryData.entryName
	local entryOpen = entryData.entryOpen

	-- 发送数据
	if enterType and entryName and entryOpen then
		local gameData = G_GetActivityDataByRef(ACTIVITY_REF.DinnerLand)
		if not gameData or not gameData:isRunning() then
			return
		end
		local log_data = {}
		log_data.tp = pageOpenType
		log_data.name = "DinnerLand" .. self:formatActivityTime(gameData.p_start)
		log_data.day = gameData:getDay()
		log_data.s = tonumber(gameData:getSequence()) - 1000  	-- 活动轮数
		log_data.rd = gameData:getCurrent() 					-- 第几关
		log_data.pn = pageName
		log_data.et = enterType
		log_data.en = entryName
		log_data.eo = entryOpen
		gL_logData:syncEventData("CookPopup")
		gL_logData.p_data = log_data
		self:sendLogData()
	end
end


function LogDinnerLandActivity:formatActivityTime(activityTime)
    if not activityTime then
        return ""
    end
    local year = string.sub(activityTime, 1, 4)
    local month = string.sub(activityTime, 6, 7)
    local day = string.sub(activityTime, 9, 10)
    return year .. month .. day
end

return LogDinnerLandActivity