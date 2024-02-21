--[[
    购买权益
]]

local PBInfoController = class("PBInfoController", BaseGameControl)

function PBInfoController:ctor()
    PBInfoController.super.ctor(self)
    self.m_refName = G_REF.PBInfo
end

function PBInfoController:showPBInfoLayer(_saleData, _itemList, _refName, _notRemoveSame)
    local layer = util_createView("GameModule.PBInfo.views.PBInfoLayer", _saleData, _itemList, _refName, _notRemoveSame)
    self:showLayer(layer, ViewZorder.ZORDER_POPUI)
end

return PBInfoController
