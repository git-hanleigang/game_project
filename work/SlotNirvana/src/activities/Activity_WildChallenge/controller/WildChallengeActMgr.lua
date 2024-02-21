--[[
Author: cxc
Date: 2022-03-23 15:57:56
LastEditTime: 2022-03-23 15:57:57
LastEditors: cxc
Description: 3日行为付费聚合活动  管理器
FilePath: /SlotNirvana/src/activities/Activity_WildChallenge/controller/WildChallengeActMgr.lua
--]]
local WildChallengeActMgr = class("WildChallengeActMgr", BaseActivityControl)
local WildChallengeNet = require("activities.Activity_WildChallenge.net.WildChallengeNet")

function WildChallengeActMgr:ctor()
    WildChallengeActMgr.super.ctor(self)
    self:setRefName(ACTIVITY_REF.WildChallenge)
    self.m_netModel = WildChallengeNet:getInstance()
end

-- 关卡内spin更新活动数据
function WildChallengeActMgr:updateTaskData(_taskData)
    local data = self:getRunningData()
    if not data or not _taskData then
        return
    end

    local list = data:getPhaseListData()
    for _, taskData in ipairs(list) do
        local idx = taskData:getIdx()
        if idx == _taskData.seq then
            taskData:parseData(_taskData)

            -- 任务状态 0初始化 1开启 2完成 3已领取
            if not (taskData:isFirst() and taskData:isFree()) then
                if taskData:getStatus() == 2 then
                    data:setUncollectedTask(true)
                end
            end
            break
        end 
    end
end

function WildChallengeActMgr:sendCollectReq(_idx)
    local data = self:getRunningData()
    if not data then
        return
    end
    local bNovice = data:isNovice()
    self.m_netModel:sendCollectReq(_idx, bNovice)
end

-- 是否有可领取但是未领取的任务
function WildChallengeActMgr:checkUncollectedTask()
    local data = self:getRunningData() 
    if not data then
        return false
    end
    return data:checkUncollectedTask()
end

-- 显示主弹板
function WildChallengeActMgr:showMainLayer()
    if not self:isCanShowLayer() then
        return
    end

    if gLobalViewManager:getViewByExtendData("WildChallengeActMainLayer") then
        return
    end

    local themeName = self:getThemeName()
    local luaPath = "Activity." .. themeName .. "MainUI"
    local view = util_createView(luaPath)
    gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
    
    return view
end

-- 显示奖励弹板
function WildChallengeActMgr:popRewardLayer(_idx, _cb)
    local themeName = self:getThemeName()
    local luaPath = "Activity.rewards." .. themeName .. "RewardLayer"
    local view = util_createView(luaPath, _idx, _cb)
    if not view then
        return
    end
    
    gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
    return view
end

-- 关卡logo
-- function WildChallengeActMgr:getLevelLogoCodePath()
--     local themeName = self:getThemeName()
--     local luaPath = "Activity/logo/" .. themeName .. "LogoNode"
--     return luaPath
-- end

-- 关卡内入口名
function WildChallengeActMgr:getEntryName()
    return self:getThemeName()
end

-- 是否可显示入口
function WildChallengeActMgr:isCanShowEntry()
    if not self:isDownloadRes() then
        return false
    end

    local _data = self:getRunningData()
    if not _data or not _data:isCanShowEntry() then
        return false
    end

    if _data:checkCompleteCondition() then
        return false
    end
    
    return true
end


-- 引导数据
function WildChallengeActMgr:saveGuideKey(_value)
    gLobalDataManager:setStringByField("WildChallengeGuide", _value)
end
function WildChallengeActMgr:checkGuide()
    local timeDay = gLobalDataManager:getStringByField("WildChallengeGuide")
    if not timeDay or string.len(timeDay) == 0 then
        return true
    end

    local day = self:getFormatTime()
    if tonumber(day) > tonumber(timeDay) then
        return true
    end

    return false
end
function WildChallengeActMgr:getFormatTime()
    local tm = os.date("*t")
    return string.format("%02d%02d%02d", tm.year, tm.month, tm.day)
end

return WildChallengeActMgr
