--[[
    付费目标
]]

local GetMorePayLessNet = require("activities.Activity_GetMorePayLess.net.GetMorePayLessNet")
local GetMorePayLessMgr = class("GetMorePayLessMgr", BaseActivityControl)

function GetMorePayLessMgr:ctor()
    GetMorePayLessMgr.super.ctor(self)

    self.m_net = GetMorePayLessNet:getInstance()
    self:setRefName(ACTIVITY_REF.GetMorePayLess)
end

function GetMorePayLessMgr:showMainLayer(_params)
    if not self:isCanShowLayer() then
        return nil
    end

    local view = nil
    if gLobalViewManager:getViewByExtendData("Activity_GetMorePayLess") == nil then
        view = util_createView("Activity_GetMorePayLess.Activity.Activity_GetMorePayLess", _params)
        self:showLayer(view, ViewZorder.ZORDER_UI)
    end
    return view
end

function GetMorePayLessMgr:sendCollect(_index)
    self.m_net:sendCollect(_index)
end

function GetMorePayLessMgr:getHallPath(hallName)
    local themeName = self:getThemeName()
    return themeName .. "/Icons/" .. hallName .. "HallNode"
end

function GetMorePayLessMgr:getSlidePath(slideName)
    local themeName = self:getThemeName()
    return themeName .. "/Icons/" .. slideName .. "SlideNode"
end

function GetMorePayLessMgr:getPopPath(popName)
    local themeName = self:getThemeName()
    return themeName .. "/Activity/" .. popName
end

return GetMorePayLessMgr
