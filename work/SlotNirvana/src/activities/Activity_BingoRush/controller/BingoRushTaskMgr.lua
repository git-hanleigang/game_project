-- bingo比赛任务

local BingoRushTaskMgr = class("BingoRushTaskMgr", BaseActivityControl)

function BingoRushTaskMgr:ctor()
    BingoRushTaskMgr.super.ctor(self)
    self:setRefName(ACTIVITY_REF.BingoRushTask)
    self:addPreRef(ACTIVITY_REF.BingoRush)
end

function BingoRushTaskMgr:showMainLayer()
    if not self:isCanShowLayer() then
        return nil
    end

    local uiView = nil
    if gLobalViewManager:getViewByExtendData("BingoRushTaskMainLayer") == nil then
        uiView = util_createFindView("Activity/BingoRushTaskMainLayer")
        if uiView ~= nil then
            gLobalViewManager:showUI(uiView, ViewZorder.ZORDER_UI)
        end
    end

    return uiView
end

return BingoRushTaskMgr
