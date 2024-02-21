--[[
    合成转盘
]]
local MagicGardenNet = require("activities.Activity_MagicGarden.net.MagicGardenNet")
local MagicGardenMgr = class("MagicGardenMgr", BaseActivityControl)

function MagicGardenMgr:ctor()
    MagicGardenMgr.super.ctor(self)

    self:setRefName(ACTIVITY_REF.MagicGarden)
    self.m_MagicGardenNet = MagicGardenNet:getInstance()
end

function MagicGardenMgr:showMainLayer(_params)
    if not self:isCanShowLayer() then
        return nil
    end

    local view = nil
    if gLobalViewManager:getViewByExtendData("Activity_MagicGarden") == nil then
        view = util_createView("Activity_MagicGarden.Activity.Activity_MagicGarden", _params)
        self:showLayer(view, ViewZorder.ZORDER_UI)
    end

    return view
end

function MagicGardenMgr:showInfoLayer(_params)
    if not self:isCanShowLayer() then
        return nil
    end

    local view = nil
    if gLobalViewManager:getViewByExtendData("Activity_MagicGardenInfo") == nil then
        view = util_createView("Activity_MagicGarden.Activity.Activity_MagicGardenInfo", _params)
        self:showLayer(view, ViewZorder.ZORDER_UI)
    end

    return view
end

function MagicGardenMgr:showRewardLayer(_params)
    if not self:isCanShowLayer() then
        return nil
    end

    local view = util_createView("Activity_MagicGarden.Activity.Activity_MagicGardenRewardLayer", _params)
    self:showLayer(view, ViewZorder.ZORDER_UI)

    return view
end

function MagicGardenMgr:createEntryNode()
    if not self:isCanShowLayer() then
        return nil
    end

    local entry = util_createView("Activity_MagicGarden.Activity.Activity_MagicGardenEntry")
    return entry
end

function MagicGardenMgr:sendFreeTimes()
    self.m_MagicGardenNet:sendFreeTimes()
end

function MagicGardenMgr:buySale(_data)
    self.m_MagicGardenNet:buySale(_data)
end

function MagicGardenMgr:sendRewardCollect(_index, _type)
    self.m_MagicGardenNet:sendRewardCollect(_index, _type)
end

function MagicGardenMgr:getHallPath(hallName)
    local themeName = self:getThemeName()
    return themeName .. "/Icons/" .. hallName .. "HallNode"
end

function MagicGardenMgr:getSlidePath(slideName)
    local themeName = self:getThemeName()
    return themeName .. "/Icons/" .. slideName .. "SlideNode"
end

function MagicGardenMgr:getPopPath(popName)
    local themeName = self:getThemeName()
    return themeName .. "/Activity/" .. popName
end

return MagicGardenMgr
