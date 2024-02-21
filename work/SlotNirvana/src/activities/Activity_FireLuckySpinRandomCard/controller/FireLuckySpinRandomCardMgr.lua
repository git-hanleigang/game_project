--[[
    SuperSpin高级版送缺卡
]]
--
local FireLuckySpinRandomCardMgr = class("FireLuckySpinRandomCardMgr", BaseActivityControl)

function FireLuckySpinRandomCardMgr:ctor()
    FireLuckySpinRandomCardMgr.super.ctor(self)

    self:setRefName(ACTIVITY_REF.FireLuckySpinRandomCard)
end

function FireLuckySpinRandomCardMgr:showMainLayer(_data)
    local view = self:createPopLayer(_data)
    if view then
        self:showLayer(view, ViewZorder.ZORDER_UI)
    end
    return view
end

function FireLuckySpinRandomCardMgr:getHallPath(hallName)
    local themeName = self:getThemeName()
    return themeName .. "/Icons/" .. hallName .. "HallNode"
end

function FireLuckySpinRandomCardMgr:getSlidePath(slideName)
    local themeName = self:getThemeName()
    return themeName .. "/Icons/" .. slideName .. "SlideNode"
end

function FireLuckySpinRandomCardMgr:getPopPath(popName)
    local themeName = self:getThemeName()
    return themeName .. "/Activity/" .. popName
end

return FireLuckySpinRandomCardMgr
