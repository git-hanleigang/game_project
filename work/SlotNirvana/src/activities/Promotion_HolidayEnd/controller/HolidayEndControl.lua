--[[
    聚合挑战结束促销
]]

local Facade = require("GameMVC.core.Facade")
local HolidayEndSaleNet = require("activities.Promotion_HolidayEnd.net.HolidayEndSaleNet")
local HolidayEndControl = class("HolidayEndControl", BaseGameControl)

function HolidayEndControl:ctor()
    HolidayEndControl.super.ctor(self)
    self:setRefName(G_REF.HolidayEnd)

    self.m_net = HolidayEndSaleNet:getInstance()
end

function HolidayEndControl:parseData(_data)
    if not _data then
        return
    end

    local data = self:getData()
    if not data then
        data = require("activities.Promotion_HolidayEnd.model.HolidayEndSaleData"):create()
        data:parseData(_data)
        self:registerData(data)
    else
        data:parseData(_data)
    end
end

function HolidayEndControl:showMainLayer()
    local data = self:getRunningData()
    if not data then
        return
    end

    local view = nil
    if gLobalViewManager:getViewByExtendData("Promotion_HolidayBoxMainLayer") == nil then
        view = util_createView("Activity/Promotion_HolidayBoxMainLayer")
        if view ~= nil then
            self:showLayer(view, ViewZorder.ZORDER_UI)
        end
    end

    return view 
end

function HolidayEndControl:deleteSaleData()
    local _data = self:getData()
    if _data then 
        Facade:getInstance():removeModel(self:getRefName())
    end
end

function HolidayEndControl:sendFreeReward()
    self.m_net:sendFreeReward()
end

function HolidayEndControl:buyPayReward(_data)
    self.m_net:buyPayReward(_data)
end

return HolidayEndControl
