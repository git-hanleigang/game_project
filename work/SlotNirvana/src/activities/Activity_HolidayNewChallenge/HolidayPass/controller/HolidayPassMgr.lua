--[[
    圣诞聚合 -- pass
]]
local HolidayPassConfig = require("activities.Activity_HolidayNewChallenge.HolidayPass.config.HolidayPassConfig")
local HolidayPassNet = require("activities.Activity_HolidayNewChallenge.HolidayPass.net.HolidayPassNet")
local HolidayPassMgr = class("HolidayPassMgr", BaseActivityControl)

function HolidayPassMgr:ctor()
    HolidayPassMgr.super.ctor(self)

    self:setRefName(ACTIVITY_REF.HolidayPass)
    self.m_net = HolidayPassNet:getInstance()
end

function HolidayPassMgr:getHallPath(hallName)
    return hallName .. "/" .. hallName .. "HallNode"
end

function HolidayPassMgr:getSlidePath(slideName)
    return slideName .. "/" .. slideName .. "SlideNode"
end

function HolidayPassMgr:getPopPath(popName)
    return popName .. "/" .. popName
end

function HolidayPassMgr:parseSpinData(_data)
    if _data then
        local curProgress = _data.curProgress or 0
        local gameData = self:getRunningData()
        if gameData and curProgress > 0 then
            local progress = math.max(curProgress, gameData:getCurProgress())
            gameData:setCurProgress(progress)
        end
    end
end

-- 请求购买pass
function HolidayPassMgr:requestBuyPass(_params)
    local successFunc = function()
        gLobalViewManager:checkBuyTipList(function()
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_HOLIDAY_PASS_UNLOCK, true)
        end)
    end

    local failedCallFunc = function()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_HOLIDAY_PASS_UNLOCK, false)
    end
    self.m_net:requestBuyPass(_params, successFunc, failedCallFunc)
end

-- 请求领取pass奖励 _params:{free = true/false, seq = 1-max}
function HolidayPassMgr:requestCollectReward(_params)
    local successFunc = function(resData)
        local sucParams = clone(_params)
        sucParams.resData = resData
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_HOLIDAY_PASS_COLLECT, sucParams)
    end

    local failedCallFunc = function()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_HOLIDAY_PASS_COLLECT, false)
    end
    self.m_net:requestCollectReward(_params, successFunc, failedCallFunc)
end

-- 请求刷新数据
function HolidayPassMgr:requestRefreshData(successFunc, failedCallFunc)
    self.m_net:requestRefreshData(successFunc, failedCallFunc)
end

function HolidayPassMgr:getHolidayPassMainLayer()
    local view = self:getLayerByName("HolidayPassMainLayer")
    return view
end

function HolidayPassMgr:refreshProgress()
    local view = self:getHolidayPassMainLayer()
    if view then
        if view.refreshUI then
            view:refreshUI()
        end
    end
end

function HolidayPassMgr:showMainLayer(_params)
    if not self:isCanShowLayer() then
        return nil
    end

    local view = self:getLayerByName("HolidayPassMainLayer")
    if view then
        if view.initDatas then
            view:initDatas(_params)
        end
        if view.onShowedCallFunc then
            view:onShowedCallFunc()
        end
        return view
    end
    
    local successFunc = function()
        local themeName = self:getThemeName()
        local luaPath = themeName .. "/Pass/HolidayPassMainLayer"
        view = util_createView(luaPath, _params)
        if view then
            self:showLayer(view, ViewZorder.ZORDER_UI)
        end
    end
    self:requestRefreshData(successFunc, nil)
    return view
end

--新版pass 需要先展示进度面板，在跳转到主界面
function HolidayPassMgr:showProgressLayer(_params)
    if not self:isCanShowLayer() then
        return nil
    end

    local view = self:getLayerByName("HolidayPassProcessLayer")
    if view then
        return view
    end

    local data = self:getRunningData()
    local isHasReward = data:hasPassCompleteReward()
    if not isHasReward then
        data:refreshPreProgress()
        return nil
    end

    local themeName = self:getThemeName()
    local luaPath = themeName .. "/Pass/HolidayPassProcessLayer"
    view = util_createView(luaPath, _params)
    if view then
        self:showLayer(view, ViewZorder.ZORDER_UI)
    end
    return view
end

function HolidayPassMgr:createRewardLayer(_reward)
    if _reward then
        -- 道具列表
        local itemDataList = {}
        -- 金币道具
        local coins = 0
        if _reward.getCoins then
            coins = _reward:getCoins()
        end
        if coins and coins > toLongNumber(0) then
            local itemData = gLobalItemManager:createLocalItemData("Coins", coins)
            itemData:setTempData({p_limit = 3})
            itemDataList[#itemDataList + 1] = itemData
        end
        -- 通用道具
        local items = {}
        if _reward.getItems then
            items = _reward:getItems()
        end
        if #items > 0 then
            for i, v in ipairs(items) do
                local itemData = gLobalItemManager:createLocalItemData(v.p_icon, v.p_num, v)
                itemDataList[#itemDataList + 1] = itemData
            end
        end
        
        local clickFunc = function()
            if CardSysManager:needDropCards("Snowflakes Chase") then
                CardSysManager:doDropCards("Snowflakes Chase")
            end
        end

        local view = gLobalItemManager:createRewardLayer(itemDataList, clickFunc, coins, true, "Christmas2023")
        if view then
            gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
        end
    end
end

return HolidayPassMgr
