--[[
Author: dhs
Date: 2022-05-06 17:57:30
LastEditors: bogon
LastEditTime: 2022-06-11 16:46:19
FilePath: /SlotNirvana/src/GameModule/NewUser7Day/controller/NewUser7DayMgr.lua
Description: 新手7日目标 Mgr
--]]
local NewUser7DayMgr = class("NewUser7DayMgr", BaseActivityControl)
local NewUser7DayNet = util_require("GameModule.NewUser7Day.net.NewUser7DayNet")

function NewUser7DayMgr:ctor()
    NewUser7DayMgr.super.ctor(self)
    self:setRefName(G_REF.NewUser7Day)
    self.m_refresh = false
    self.m_taskStatus = {
        true,
        false,
        false,
        false,
        false,
        false,
        false
    }
end

function NewUser7DayMgr:parseData(_data)
    if not _data then
        return
    end
    local gameData = G_GetMgr(G_REF.NewUser7Day):getData()
    if gameData then
        -- local data = {current = _data}
        gameData:parseData(_data)
    end
end

function NewUser7DayMgr:parseSlotsData(_data)
    if not _data then
        return
    end
    local gameData = G_GetMgr(G_REF.NewUser7Day):getData()
    if gameData then
        local data = {current = _data}
        gameData:parseData(data)
    end
end

-- **************************************** 界面 **************************************** --
function NewUser7DayMgr:showMainLayer(_call)
    if not self:isCanShowLayer() then
        if _call then
            _call()
        end
        return nil
    end

    if gLobalViewManager:getViewByName("NewUser7DayMainLayer") ~= nil then
        if _call then
            _call()
        end
        return nil
    end

    local view = util_createView("Main.NewUser7DayMainLayer", _call)
    view:setName("NewUser7DayMainLayer")
    gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)

    return view
end

function NewUser7DayMgr:showInfoLayer(_call)
    if not self:isCanShowLayer() then
        if _call then
            _call()
        end
        return nil
    end

    if gLobalViewManager:getViewByName("NewUser7DayInfoLayer") ~= nil then
        return nil
    end

    local view = util_createView("Info.NewUser7DayInfoLayer", _call)
    view:setName("NewUser7DayInfoLayer")
    gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
    return view
end

function NewUser7DayMgr:showRewardLayer(_call)
    if not self:isCanShowLayer() then
        if _call then
            _call()
        end
        return nil
    end

    if gLobalViewManager:getViewByName("NewUser7DayRewardLayer") ~= nil then
        return nil
    end

    local view = util_createView("Reward.NewUser7DayRewardLayer", _call)
    view:setName("NewUser7DayRewardLayer")
    gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
    return view
end

-- **************************************** 界面 **************************************** --

-- **************************************** 请求 **************************************** --
function NewUser7DayMgr:sendCollectReward()
    local successCall = function()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_NEW_USER_7DAY_COLLECT, {success = true})
    end

    local failedCall = function()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_NEW_USER_7DAY_COLLECT, {success = false})
    end

    NewUser7DayNet:sendCollect(successCall, failedCall)
end
-- **************************************** 请求 **************************************** --

-- **************************************** 数据 **************************************** --
function NewUser7DayMgr:getData()
    return globalData.newUser7DayData
end

function NewUser7DayMgr:getCurrentGameData()
    local data = self:getData()
    if data then
        return data:getCurrentData()
    end
    return nil
end

function NewUser7DayMgr:getNextGameDataByDay(_day)
    local data = self:getData()
    if data then
        local nextDataList = data:getNextData()
        for i = 1, #nextDataList do
            local data = nextDataList[i]
            local index = data.index
            if _day == index then
                return data.gameData
            end
        end

        return nil
    end
    return nil
end

-- 用来判断玩家五级后从关卡返回大厅只弹出一次
function NewUser7DayMgr:setFirstEnter()
    gLobalDataManager:setStringByField("NewUser7Day", "NoFirst")
end

function NewUser7DayMgr:getFirstEnter()
    return gLobalDataManager:getStringByField("NewUser7Day", "First")
end

--判断当前任务是不是已经播放过动效
function NewUser7DayMgr:setTaskActionStatus(_taskId)
    gLobalDataManager:setStringByField("NewUser7DayTask" .. _taskId, "NoAction")
end

function NewUser7DayMgr:getTaskActionStatusById(_taskId)
    return gLobalDataManager:getStringByField("NewUser7DayTask" .. _taskId, "Action")
end

function NewUser7DayMgr:setParallaxOffSet(_offSet)
    gLobalDataManager:setNumberByField("ParallaxOffSet", _offSet)
end

function NewUser7DayMgr:getParallaxOffSet()
    return gLobalDataManager:getNumberByField("ParallaxOffSet", 0)
end

--记录当前红点逻辑

function NewUser7DayMgr:setTaskRedStatusByDay(_day)
    gLobalDataManager:setStringByField("TaskRedStatus" .. _day, "NoFirst")
end

function NewUser7DayMgr:getTaskRedStatusByDay(_day)
    return gLobalDataManager:getStringByField("TaskRedStatus" .. _day, "First")
end

function NewUser7DayMgr:setGameDataRefresh(_isRefresh)
    self.m_refresh = _isRefresh
end

function NewUser7DayMgr:getLocalGameData()
    return self.m_refresh or false
end

-- 控制任务解锁状态（每个任务都有倒计时）
function NewUser7DayMgr:setTaskLockStatus(_index, _lock)
    self.m_taskStatus[_index] = _lock
end

function NewUser7DayMgr:getTaskStatusByIdx(_index)
    return self.m_taskStatus[_index] or true
end

function NewUser7DayMgr:initTaskStatus(_index)
    for i = 1, #self.m_taskStatus do
        if i <= _index then
            self.m_taskStatus[i] = true
        end
    end
end

-- **************************************** 数据 **************************************** --
return NewUser7DayMgr
