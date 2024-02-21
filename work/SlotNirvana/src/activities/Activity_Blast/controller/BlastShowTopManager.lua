--[[
    blast排行榜
    author: 徐袁
    time: 2021-09-05 11:34:35
]]
local BlastShowTopManager = class("BlastShowTopManager", BaseActivityControl)

function BlastShowTopManager:ctor()
    BlastShowTopManager.super.ctor(self)
    self:setRefName(ACTIVITY_REF.BlastShowTop)
    self:addPreRef(ACTIVITY_REF.Blast)
end

function BlastShowTopManager:showMainLayer()
    if not self:isCanShowLayer() then
        return nil
    end

    local uiView = nil
    if gLobalViewManager:getViewByExtendData("BlastRankUI") == nil then
        local config = G_GetMgr(ACTIVITY_REF.Blast):getConfig()
        if config.getThemeName() == config.THEMES.OCEAN then
            uiView = util_createView("Activity.BlastGame.BlastRank.BlastRankUI")
        elseif config.getThemeName() == config.THEMES.THANKSGIVING then
            uiView = util_createView("Activity.BlastGame.BlastRank.BlastRankThanksGivingUI")
        elseif config.getThemeName() == config.THEMES.CHRISTMAS then
            uiView = util_createView("Activity.BlastGame.BlastRank.BlastRankChristmasUI")
        elseif config.getThemeName() == config.THEMES.THREE3RD then
            uiView = util_createView("Activity.BlastGame.BlastRank.BlastRank3RDUI")
        elseif config.getThemeName() == config.THEMES.BLOSSOM then
            uiView = util_createView("Activity.BlastGame.BlastRank.BlastRankBlossomUI")
        elseif config.getThemeName() == config.THEMES.HALLOWEEN then
            uiView = util_createView("Activity.BlastGame.BlastRank.BlastRankHalloweenUI")
        elseif config.getThemeName() == config.THEMES.MERMAID then
            uiView = util_createView("Activity.BlastGame.BlastRank.BlastRankMermaidUI")
        end
        if uiView then
            gLobalViewManager:showUI(uiView, ViewZorder.ZORDER_POPUI)
        end
    end

    return uiView
end

return BlastShowTopManager
