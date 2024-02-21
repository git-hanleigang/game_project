--[[
    RepeatFreeSpin
]]
local RepeatFreeSpinControl = class("RepeatFreeSpinControl", BaseActivityControl)

function RepeatFreeSpinControl:ctor()
    RepeatFreeSpinControl.super.ctor(self)
    self:setRefName(ACTIVITY_REF.RepeatFreeSpin)
end

function RepeatFreeSpinControl:showCoinStoreLayer(_openPos)
    if globalFireBaseManager.sendFireBaseLogDirect and _openPos then
        globalFireBaseManager:sendFireBaseLogDirect(_openPos .. "_PopupClick", false)
    end
    gLobalSendDataManager:getLogIap():setEnterOpen(nil, nil, _openPos)
    G_GetMgr(G_REF.Shop):showMainLayer()

    local repeatFreeSpinData = self:getRunningData()
    if repeatFreeSpinData and repeatFreeSpinData:isRunning() then
        --打点
        if gLobalSendDataManager:getLogFeature().sendRepartActivity then
            gLobalSendDataManager:getLogFeature():sendRepartActivity("FreeSpinReturn", "Click", "FreeSpinReturn" .. repeatFreeSpinData:getStrEndTime())
        end
    end
end

function RepeatFreeSpinControl:showMainLayer()
    if not self:isCanShowLayer() then
        return nil
    end

    local repeatFreeSpinData = self:getRunningData()
    if repeatFreeSpinData == nil or repeatFreeSpinData:isRunning() == false then
        return
    end
    if repeatFreeSpinData:isAlive() then
        local view = util_createFindView("Activity/RepeatFreeSpinInGame")
        if view ~= nil then
            self:showLayer(view, ViewZorder.ZORDER_UI)
        end
    else
        local view = util_createFindView("Activity/Activity_RepeatFreeSpin")
        if view ~= nil then
            self:showLayer(view, ViewZorder.ZORDER_UI)
        end
    end
end

return RepeatFreeSpinControl
