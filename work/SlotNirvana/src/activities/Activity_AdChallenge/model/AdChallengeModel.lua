--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{hl}
    time:2022-06-15 11:08:13
    describe:广告任务
]]
local BaseActivityData = require "baseActivity.BaseActivityData"
local AdChallengeModel = class("AdChallengeModel", BaseActivityData)

function AdChallengeModel:ctor()
    AdChallengeModel.super.ctor(self)
    self.p_open = true
end

function AdChallengeModel:checkCompleteCondition()
    if not globalData.AdChallengeData or not globalData.AdChallengeData:isHasAdChallengeActivity() then
        return true
    else
        return AdChallengeModel.super.checkCompleteCondition(self)
    end
end

return AdChallengeModel
