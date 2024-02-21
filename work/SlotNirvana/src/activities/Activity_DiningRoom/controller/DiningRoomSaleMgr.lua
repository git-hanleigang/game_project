--[[
    
    author:{author}
    time:2021-09-28 17:58:50
]]
local DiningRoomSaleMgr = class("DiningRoomSaleMgr", BaseActivityControl)

function DiningRoomSaleMgr:ctor()
    DiningRoomSaleMgr.super.ctor(self)
    self:setRefName(ACTIVITY_REF.DiningRoomSale)
end

function DiningRoomSaleMgr:showMainLayer(extra_data)
    local bData = G_GetActivityDataByRef(ACTIVITY_REF.DiningRoom)
    if bData == nil then
        return
    end

    local uiView = self:createPopLayer(extra_data)
    if uiView then
        if gLobalSendDataManager.getLogIap and gLobalSendDataManager:getLogIap().setEnterOpen then
            gLobalSendDataManager:getLogIap():setEnterOpen("tapOpen", self:getThemeName())
        end

        local refName = self:getRefName()
        gLobalViewManager:showUI(uiView, gLobalActivityManager:getUIZorder(refName))
    end

    return uiView
end

return DiningRoomSaleMgr
