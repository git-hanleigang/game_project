--[[
    连续充值
]]

local KeepRechargeControl = class("KeepRechargeControl", BaseActivityControl)

function KeepRechargeControl:ctor()
    KeepRechargeControl.super.ctor(self)
    self:setRefName(ACTIVITY_REF.KRechargeSale)
end

function KeepRechargeControl:setClickEnable(click)
    self.m_click = click
end

function KeepRechargeControl:getClickEnable()
    return self.m_click
end

function KeepRechargeControl:setCurBuyLevel(_level)
    self.m_curLevel = _level
end

function KeepRechargeControl:getCurBuyLevel()
    return self.m_curLevel or 0
end

function KeepRechargeControl:showMainLayer()
    if not self:isCanShowLayer() then
        return nil
    end

    local view = self:createPopLayer()
    if view then
        self:showLayer(view, ViewZorder.ZORDER_UI)
    end
    return view
end

function KeepRechargeControl:getHallPath(hallName)
    local themeName = self:getThemeName()
    local refName = self:getRefName()
    if themeName == refName then
        return "Icons/" .. hallName .. "HallNode"
    else
        return themeName .. "/Icons/" .. themeName .. "HallNode" 
    end
end

function KeepRechargeControl:getSlidePath(slideName)
    local themeName = self:getThemeName()
    local refName = self:getRefName()
    if themeName == refName then
        return "Icons/" .. slideName .. "SlideNode"
    else
        return themeName .. "/Icons/" .. themeName .. "SlideNode" 
    end
end

function KeepRechargeControl:getPopPath(popName)
    local themeName = self:getThemeName()
    local refName = self:getRefName()
    if themeName == refName then
        return "Activity/" .. popName
    else
        return themeName .. "/Activity/" .. popName
    end
end

return KeepRechargeControl
