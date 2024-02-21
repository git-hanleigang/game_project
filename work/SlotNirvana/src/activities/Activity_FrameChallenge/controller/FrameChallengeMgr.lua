--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{author}
    time:2022-08-15 11:22:24
    describe:头像框挑战
]]
local FrameChallengeMgr = class("FrameChallengeMgr", BaseActivityControl)

function FrameChallengeMgr:ctor()
    FrameChallengeMgr.super.ctor(self)
    self:setRefName(ACTIVITY_REF.FrameChallenge)
end

function FrameChallengeMgr:parseSlotData(_data)
    local data = self:getRunningData()
    if data then 
        data:parseSlotData(_data)
    end
end

function FrameChallengeMgr:isShowPrizeLayer()
    if self:isCanShowLayer() then
        local data = self:getRunningData()
        local isPopup = data:getIsPopup()
        if isPopup then
            return false
        else
            return true
        end
    end
    return false
end

function FrameChallengeMgr:showPrizeLayer()
    if not self:isCanShowLayer() then
        return
    end

    if gLobalViewManager:getViewByExtendData("Activity_FrameChallengeRewardLayer") then
        return
    end

    local view = util_createView("Activity.Activity_FrameChallengeRewardLayer", {isAutoClose = true})
    gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)

    return view
end

return FrameChallengeMgr
