--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{hl}
    time:2022-06-15 11:07:55
    describe:广告任务
]]
local AdChallengeMgr = class("AdChallengeMgr", BaseActivityControl)

function AdChallengeMgr:ctor()
    AdChallengeMgr.super.ctor(self)
    self:setRefName(ACTIVITY_REF.AdChallenge)
end

function AdChallengeMgr:isCanShowHall()
    if not globalData.AdChallengeData or not globalData.AdChallengeData:isHasAdChallengeActivity() then
        return false
    else
        return AdChallengeMgr.super.isCanShowHall(self)
    end
end

function AdChallengeMgr:isCanShowSlide()
    if not globalData.AdChallengeData or not globalData.AdChallengeData:isHasAdChallengeActivity() then
        return false
    else
        return AdChallengeMgr.super.isCanShowSlide(self)
    end
end

function AdChallengeMgr:isCanShowPop()
    if not globalData.AdChallengeData or not globalData.AdChallengeData:isHasAdChallengeActivity() then
        return false
    else
        return AdChallengeMgr.super.isCanShowPop(self)
    end
end

function AdChallengeMgr:isCanShowInEntrance()
    if not globalData.AdChallengeData or not globalData.AdChallengeData:isHasAdChallengeActivity() then
        return false
    else
        return AdChallengeMgr.super.isCanShowInEntrance(self)
    end
end

return AdChallengeMgr
