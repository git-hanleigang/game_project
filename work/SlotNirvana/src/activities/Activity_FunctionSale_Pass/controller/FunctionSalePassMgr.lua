--[[
    大活动PASS
]]

local FunctionSalePassNet = require("activities.Activity_FunctionSale_Pass.net.FunctionSalePassNet")
local FunctionSalePassMgr = class("FunctionSalePassMgr", BaseActivityControl)

function FunctionSalePassMgr:ctor()
    FunctionSalePassMgr.super.ctor(self)

    self:setRefName(ACTIVITY_REF.FunctionSalePass)
    self.m_net = FunctionSalePassNet:getInstance()
end

function FunctionSalePassMgr:showMainLayer(_data)
    local view = self:createPopLayer(_data)
    if view then
        self:showLayer(view, ViewZorder.ZORDER_UI)
    elseif _data and _data.closeFunc then
        _data.closeFunc()
    end
    return view
end

function FunctionSalePassMgr:showInfoLayer()
    if not self:isCanShowLayer() then
        return nil
    end

    local themeName = self:getThemeName()
    local view = util_createView(themeName .. ".Activity." .. themeName .. "_Info")
    self:showLayer(view, ViewZorder.ZORDER_UI)
end

function FunctionSalePassMgr:showBuyLayer()
    if not self:isCanShowLayer() then
        return nil
    end

    local themeName = self:getThemeName()
    local view = util_createView(themeName .. ".Activity." .. themeName .. "_Buy")
    self:showLayer(view, ViewZorder.ZORDER_UI)
end

function FunctionSalePassMgr:showRewardLayer(_data)
    if not self:isCanShowLayer() then
        return nil
    end

    local themeName = self:getThemeName()
    local view = util_createView(themeName .. ".Activity." .. themeName .. "_Reward", _data)
    self:showLayer(view, ViewZorder.ZORDER_UI)
end

function FunctionSalePassMgr:createEntryNode()
    if not self:isCanShowLayer() then
        return
    end

    local themeName = self:getThemeName()
    local view = util_createView(themeName .. ".Activity." .. themeName .. "_Logo")
    return view
end

function FunctionSalePassMgr:getHallPath(hallName)
    local themeName = self:getThemeName()
    return themeName .. "/Icons/" .. hallName .. "HallNode"
end

function FunctionSalePassMgr:getSlidePath(slideName)
    local themeName = self:getThemeName()
    return themeName .. "/Icons/" .. slideName .. "SlideNode"
end

function FunctionSalePassMgr:getPopPath(popName)
    local themeName = self:getThemeName()
    return themeName .. "/Activity/" .. popName
end

function FunctionSalePassMgr:sendPassCollect(_data, _type, _selectIndexList)
    self.m_net:sendPassCollect(_data, _type, _selectIndexList)
end

function FunctionSalePassMgr:buyUnlock(_data)
    self.m_net:buyUnlock(_data)
end

function FunctionSalePassMgr:checkShowMainLayer(_data)
    local view = nil
    local closeFunc = _data.closeFunc
    local data = self:getRunningData()
    if data and not data:getPayUnlocked() then
        view = self:showMainLayer(_data)
    else
        if closeFunc then
            closeFunc()
        end
    end
    return view
end

function FunctionSalePassMgr:saveSelectIdx(_type, _level, _idx)
    local data = self:getRunningData()
    if data then
        data:saveSelectIdx(_type, _level, _idx)
    end
end

function FunctionSalePassMgr:checkMainLayerPop()
    local data = self:getRunningData()
    if not data then
        return
    end

    local count = data:getCanCollectCount()
    if count <= 0 then
        return
    end

    local popTime = gLobalDataManager:getNumberByField("functionSalePassMainPop", 0)
    local curTime = util_getCurrnetTime()
    if curTime - popTime >= 1800 then
        self:showMainLayer()
        gLobalDataManager:setNumberByField("functionSalePassMainPop", curTime)
    end
end

function FunctionSalePassMgr:checkBuyLayerPop()
    local data = self:getRunningData()
    if not data then
        return
    end

    local payUnlock = data:getPayUnlocked()
    if payUnlock then
        return
    end

    local popTime = gLobalDataManager:getNumberByField("functionSalePassBuyPop", 0)
    local curTime = util_getCurrnetTime()
    if curTime - popTime >= 43200 then
        self:showBuyLayer()
        gLobalDataManager:setNumberByField("functionSalePassBuyPop", curTime)
    end
end

return FunctionSalePassMgr
