--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-03-23 10:27:17
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-03-23 11:54:21
FilePath: /SlotNirvana/src/GameModule/NewUserExpand/net/LogExpand.lua
Description: 扩圈系统 打点
--]]
local NewUserExpandGuideData = require("GameModule.NewUserExpand.model.NewUserExpandGuideData")
local NewUserExpandConfig = util_require("GameModule.NewUserExpand.config.NewUserExpandConfig")
local NetworkLog = require "network.NetworkLog"
local LogExpand = class("LogExpand", NetworkLog)

-- 扩圈入口打点
function LogExpand:sendExpandClickEntryLog()
    local expandData = G_GetMgr(G_REF.NewUserExpand):getData()
    local gameData = expandData:getGameData()
    local log_data = {}
    log_data.tp = "open"
    log_data.name = "ExpandSystem"..util_formatServerTime()
    log_data.order = gameData:getCurIdx()
    log_data.atp = expandData:getServerGameType()
    log_data.et = "lobby"
    log_data.en = "ExpandSystem"
    local curType = G_GetMgr(G_REF.NewUserExpand):getCurLobbyStyle()
    if curType == NewUserExpandConfig.LOBBY_TYPE.SLOTS then
        log_data.en = "Slot"
    elseif curType == NewUserExpandConfig.LOBBY_TYPE.COL_LEVELS then
        log_data.en = "CollectLevels"
    end
    
    gL_logData:syncEventData("ExpandSystemPopup")
    gL_logData.p_data = log_data
    self:sendLogData()
end

-- 扩圈loading界面耗时打点
function LogExpand:sendExpandLoadingLog(_timeSec)
    local expandData = G_GetMgr(G_REF.NewUserExpand):getData()
    local gameData = expandData:getGameData()
    local log_data = {}
    log_data.tp = "enter"
    log_data.name = "ExpandSystem"..util_formatServerTime()
    log_data.order = gameData:getCurIdx()
    log_data.atp = expandData:getServerGameType()
    log_data.et = "lobby"
    log_data.en = "ExpandSystem"
    log_data.t = _timeSec -- 耗时
    
    gL_logData:syncEventData("ExpandSystemPopup")
    gL_logData.p_data = log_data
    self:sendLogData()
end

-- 扩圈引导打点
function LogExpand:sendExpandGuideLog(_guideName)
    local guideInfo = NewUserExpandGuideData.guide_log_info[_guideName]
    if not guideInfo then
        return
    end

    local log_data = {}
    local expandData = G_GetMgr(G_REF.NewUserExpand):getData()
    log_data.atp = expandData:getServerGameType()
    log_data.tp = "Normal" --玩家类型 正常用户登录
    if G_GetMgr(G_REF.NewUserExpand):checkIsClientActiveType() then
        log_data.tp = "Special" --玩家类型 玩家自主激活扩圈系统
    end
    log_data.guideType = guideInfo.guideType   -- "1.点击小游戏按钮 2.页签提示点击 3.点击游戏入口 4.引导查看解锁规则（完成路障引导时打） 5.了解返回Slot界面规则（点击进入到老虎机界面打）"
    log_data.guideStatus = guideInfo.bCoerce and "Compel" or "Free" -- 强引导Compel  弱引导Free
    log_data.guideId = guideInfo.guideId
    if guideInfo.passIdx then
        log_data.guideName = guideInfo.passIdx  --3.点击游戏入口 (关卡idx)
    end
    gL_logData:syncEventData("ExpandSystemGuide")
    gL_logData.p_data = log_data
    self:sendLogData()
end

return  LogExpand