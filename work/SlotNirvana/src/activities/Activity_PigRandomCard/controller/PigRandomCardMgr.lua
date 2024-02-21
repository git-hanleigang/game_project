--[[
    author:{author}
    time:2021-09-28 14:22:08
]]
local PigRandomCardMgr = class("PigRandomCardMgr", BaseActivityControl)

function PigRandomCardMgr:ctor()
    PigRandomCardMgr.super.ctor(self)
    self:setRefName(ACTIVITY_REF.PigRandomCard)
end

local tbMainLayerLua = {
    Activity_PigRandomCard = "Activity_PigRandomCard",
    Activity_PigRandomCardAngry = "PigRandomCardAngryMainUI",
    Activity_PigRandomCardAngry23 = "Activity_PigRandomCardAngry23MainUI"
}

function PigRandomCardMgr:showMainLayer(info,_over)
    if not self:isCanShowLayer() then
        return
    end
    if self:getRunningData() == nil then
        return
    end
    --送卡完成
    local data = self:getRunningData() 
    if data:isCompleted() then
        return
    end

    if gLobalViewManager:getViewByName("PigRandomCardAngryMainUI") ~= nil then
        return
    end

    local themeName = self:getThemeName()
    local luaPath = tbMainLayerLua[themeName]
    if not luaPath then
        return 
    end

    luaPath = themeName .. "." .. luaPath
    
    local view = util_createView(luaPath, info,_over)

    self:showLayer(view, ViewZorder.ZORDER_UI)
    return view
end

function PigRandomCardMgr:getHallPath(hallName)
    local themeName = self:getThemeName()
    return themeName .. "/" .. hallName .. "HallNode"
end

function PigRandomCardMgr:getSlidePath(slideName)
    local themeName = self:getThemeName()
    return themeName .. "/" .. slideName .. "SlideNode"
end

function PigRandomCardMgr:getPopPath(popName)
    local themeName = self:getThemeName()
    return themeName .. "/" .. popName
end

return PigRandomCardMgr
