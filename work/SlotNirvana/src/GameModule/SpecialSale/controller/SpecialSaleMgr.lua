--[[
    常规促销整理
]]

local Facade = require("GameMVC.core.Facade")
local SpecialSaleNet = require("GameModule.SpecialSale.net.SpecialSaleNet")
local SpecialSaleMgr = class("SpecialSaleMgr", BaseGameControl)

function SpecialSaleMgr:ctor()
    SpecialSaleMgr.super.ctor(self)

    self.m_SpecialSaleNet = SpecialSaleNet:getInstance()

    self:setRefName(G_REF.SpecialSale)
end

function SpecialSaleMgr:parseData(data)
    if not data then
        return
    end

    local _data = self:getData()
    if not _data then
        _data = require("GameModule.SpecialSale.model.SpecialSaleData"):create()
        _data:parseData(data)
        _data:setRefName(G_REF.SpecialSale)
        self:registerData(_data)
    else
        _data:parseData(data)
    end
end

function SpecialSaleMgr:showMainLayer(_params)
    local _data = self:getRunningData()
    if not _data then
        return
    end

    local view = nil
    view = util_createView("views.sale.BasicSaleLayer", _params)
    self:showLayer(view, ViewZorder.ZORDER_UI)
    return view
end

function SpecialSaleMgr:shwoWheelLayer(_params)
    local view = nil
    view = util_createView("views.sale.BasicSaleWheelLayer", _params)
    self:showLayer(view, ViewZorder.ZORDER_UI)
    return view
end

return SpecialSaleMgr
