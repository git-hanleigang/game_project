--[[
    圣诞聚合 -- 排行榜
]]

local HolidayRankNet = require("activities.Activity_HolidayNewChallenge.HolidayRank.net.HolidayRankNet")
local HolidayRankMgr = class("HolidayRankMgr", BaseActivityControl)

function HolidayRankMgr:ctor()
    HolidayRankMgr.super.ctor(self)
    self:setRefName(ACTIVITY_REF.HolidayNewRank)
    --self:addPreRef(ACTIVITY_REF.Holiday)
    self.m_net = HolidayRankNet:getInstance()
end

------------------------------------------------------ 弹窗
function HolidayRankMgr:showMainLayer(_data)
    local view = self:createPopLayer(_data)
    if view then
        self:showLayer(view, ViewZorder.ZORDER_UI)
    end
    return view
end

function HolidayRankMgr:getHallPath(hallName)
    local themeName = self:getThemeName()
    return themeName .. "/Icons/" .. hallName .. "HallNode"
end

function HolidayRankMgr:getSlidePath(slideName)
    local themeName = self:getThemeName()
    return themeName .. "/Icons/" .. slideName .. "SlideNode"
end

function HolidayRankMgr:getPopPath(popName)
    self:sendActionRank(false)
    local themeName = self:getThemeName()
    return themeName .. "/Activity/" .. "HolidayRankUI"
end


------------------------------------------------------ 排行榜主界面
-- 请求排行榜数据 _flag 是否转圈
function HolidayRankMgr:sendActionRank(_flag)
    self.m_net:sendActionRank(_flag)
end

-- 显示排行榜主界面
function HolidayRankMgr:showMainLayer()
    if not self:isCanShowLayer() then
        return
    end
    if self:getLayerByName("HolidayRankUI") ~= nil then
        return
    end
    local OutsideCaveRankUI = nil
    self:sendActionRank(false)
    local themeName = self:getThemeName()
    local OutsideCaveRankUI = util_createView(themeName .. ".Activity.HolidayRankUI")
    if OutsideCaveRankUI ~= nil then
        self:showLayer(OutsideCaveRankUI, ViewZorder.ZORDER_UI)
    end
    return OutsideCaveRankUI
end

return HolidayRankMgr
