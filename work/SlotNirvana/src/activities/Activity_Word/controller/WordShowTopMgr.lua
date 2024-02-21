--[[
    
    author:{author}
    time:2021-09-28 17:58:50
]]
local WordShowTopMgr = class("WordShowTopMgr", BaseActivityControl)

function WordShowTopMgr:ctor()
    WordShowTopMgr.super.ctor(self)
    self:setRefName(ACTIVITY_REF.WordShowTop)
    self:addPreRef(ACTIVITY_REF.Word)
end

function WordShowTopMgr:showMainLayer()
    if not self:isCanShowLayer() then
        return nil
    end

    local wordRankUI = nil
    if gLobalViewManager:getViewByExtendData("WordRankUI") == nil then
        gLobalNoticManager:postNotification(ViewEventType.RANK_BTN_CLICKED, {name = ACTIVITY_REF.Word})
        wordRankUI = util_createView("Activity.WordRank.WordRankUI")
        gLobalViewManager:showUI(wordRankUI, ViewZorder.ZORDER_POPUI)
    end
    return wordRankUI
end

return WordShowTopMgr
