--[[
    邮箱收集
]]

local CollectEmailNet = require("activities.Promotion_NewDouble.net.NewDoubleNet")
local NewDoubleControl = class("NewDoubleControl", BaseActivityControl)

function NewDoubleControl:ctor()
    NewDoubleControl.super.ctor(self)
    
    self:setRefName(ACTIVITY_REF.NewDouble)

    self.m_netModel = CollectEmailNet:getInstance()   -- 网络模块
end

function NewDoubleControl:showGiveUpLayer()
    local view = util_createView("Activity.Choice_GiveUp")
    gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
    return view
end

function NewDoubleControl:showMainLayer()
    local view = util_createView("Activity.Promotion_NewDouble")
    gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
end

function NewDoubleControl:buySale(_data)
    self.m_netModel:buySale(_data)
end

function NewDoubleControl:giveUp()
    self.m_netModel:giveUp()
end

return NewDoubleControl
