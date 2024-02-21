local BrokenSaleV2Net = require("GameModule.BrokenSaleV2.net.BrokenSaleV2Net")
local BrokenSaleV2Mgr = class("BrokenSaleV2Mgr", BaseGameControl)

function BrokenSaleV2Mgr:ctor()
    BrokenSaleV2Mgr.super.ctor(self)
    self:setRefName(G_REF.BrokenSaleV2)
    self:setResInApp(true)
    self:setDataModule("GameModule.BrokenSaleV2.model.BrokenSaleV2Data")
    self.m_net = BrokenSaleV2Net:getInstance()
end

--[[
    message GoBrokeSaleBuff {
        optional string multiple = 2; // 倍数
        optional int64 count = 3; // 剩余次数
        optional int64 buffCoins = 4; // buff已收集金币
        optional int64 buffCoinsLimit = 5; // buff收集金币上限
    }
]]
function BrokenSaleV2Mgr:parseSpinData(_data)
    local data = self:getData()
    if _data and data then
        local buffData = data:getActiveBuff()
        if buffData then
            buffData:parseSpinData(_data)
        end
    end
end

function BrokenSaleV2Mgr:getRightFrameRunningData()
    local data = self:getData()
    if data and self:isCanShowEntry() then
        return data
    end
    return false
end

-- 是否可显示入口
function BrokenSaleV2Mgr:isCanShowEntry()
    local _data = self:getData()
    if not _data or not _data:isCanShowEntry() then
        return false
    end
    return true
end

-- 关卡内入口
function BrokenSaleV2Mgr:getEntryModule()
    return "views.sale.BrokenSaleV2.BrokenSaleV2BuffEntryNode"
end

-- buff金币领奖
function BrokenSaleV2Mgr:requestBuffCoinsReward(successCallFunc, failedCallFunc)
    self.m_net:requestBuffCoinsReward({}, successCallFunc, failedCallFunc)
end

-- 促销弹窗关闭
function BrokenSaleV2Mgr:requestCloseSaleView(successCallFunc, failedCallFunc)
    self.m_net:requestCloseSaleView({}, successCallFunc, failedCallFunc)
end

-- 付费购买
function BrokenSaleV2Mgr:requestBuySale(params, successCallFunc, failedCallFunc)
    self.m_net:requestBuySale(params, successCallFunc, failedCallFunc)
end

function BrokenSaleV2Mgr:isCanShowMainLayer()
    if not self:isCanShowLayer() then
        return false
    end
    if not self:isCoolDown() then
        return false
    end
    local layer = gLobalViewManager:getViewByExtendData("BrokenSaleV2Layer")
    if layer then
        return false
    end
    return true
end

--打开破产促销界面
function BrokenSaleV2Mgr:showMainLayer()
    if not self:isCanShowLayer() then
        return nil
    end
    local layer = gLobalViewManager:getViewByExtendData("BrokenSaleV2Layer")
    if layer then
        return layer
    end
    local view = util_createView("views.sale.BrokenSaleV2.BrokenSaleV2Layer")
    if view then
        self:showLayer(view, ViewZorder.ZORDER_UI)
    end
    return view
end

--打开破产促销 buff界面
function BrokenSaleV2Mgr:showBuffLayer(_buffData)
    local layer = gLobalViewManager:getViewByExtendData("BrokenSaleV2BuffLayer")
    if layer then
        return layer
    end
    local view = util_createView("views.sale.BrokenSaleV2.BrokenSaleV2BuffLayer", _buffData)
    if view then
        self:showLayer(view, ViewZorder.ZORDER_UI)
    end
    return view
end

--关卡中检测弹出buff界面
function BrokenSaleV2Mgr:checkPopBuffLayer()
    local data = self:getData()
    if not data then
        return false
    end
    local buffData = data:getActiveBuff()
    if not buffData then
        return false
    end
    local isCanCollect = buffData:isCanCollect()
    if not isCanCollect then
        return false
    end
    return self:showBuffLayer()
end

function BrokenSaleV2Mgr:isCoolDown()
    local bPop = false
    local cdTime = gLobalDataManager:getNumberByField("BrokenSaleV2PopCD", 0)
    local curTime = util_getCurrnetTime()
    if curTime - cdTime > 0 then
        bPop = true
    end
    return bPop
end

function BrokenSaleV2Mgr:setCoolDownTime()
    local curTime = util_getCurrnetTime()
    gLobalDataManager:setNumberByField("BrokenSaleV2PopCD", curTime + 5 * 60)
end

return BrokenSaleV2Mgr
