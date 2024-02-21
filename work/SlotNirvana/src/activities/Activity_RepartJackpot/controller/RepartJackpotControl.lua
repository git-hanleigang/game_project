--[[
    Echo Win
]]

local RepartJackpotControl = class("RepartJackpotControl", BaseActivityControl)

function RepartJackpotControl:ctor()
    RepartJackpotControl.super.ctor(self)
    self:setRefName(ACTIVITY_REF.RepartJackpot)
end

function RepartJackpotControl:showCoinStoreLayer(_openPos)
    if globalFireBaseManager.sendFireBaseLogDirect and _openPos then
        globalFireBaseManager:sendFireBaseLogDirect(_openPos .. "_PopupClick", false)
    end
    gLobalSendDataManager:getLogIap():setEnterOpen(nil, nil, _openPos)
    G_GetMgr(G_REF.Shop):showMainLayer()

    local repartJackpotData = self:getRunningData()
    if repartJackpotData and repartJackpotData:isRunning() then
        --打点
        if gLobalSendDataManager:getLogFeature().sendRepartActivity then
            gLobalSendDataManager:getLogFeature():sendRepartActivity("JackpotReturn", "Click", "JackpotReturn" .. repartJackpotData:getStrEndTime())
        end
    end
end

function RepartJackpotControl:showMainLayer()
    if not self:isCanShowLayer() then
        return nil
    end

    local repartJackpotData = self:getRunningData()
    if repartJackpotData == nil or repartJackpotData:isRunning() == false then
        return
    end
    if repartJackpotData:isAlive() then
        local view = util_createFindView("Activity/RepartJackpotInGame")
        if view ~= nil then
            gLobalViewManager:showUI(view, ViewZorder.ZORDER_POPUI)
        end
    else
        local view = util_createFindView("Activity/Activity_RepartJackpot")
        if view ~= nil then
            gLobalViewManager:showUI(view, ViewZorder.ZORDER_POPUI)
        end
    end
end

return RepartJackpotControl
