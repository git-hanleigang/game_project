--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{author}
    time:2022-11-10 14:19:46
]]
local InboxItem_base = util_require("views.inbox.item.InboxItem_baseReward")
local InboxItem_GrandPrize = class("InboxItem_GrandPrize", InboxItem_base)

function InboxItem_GrandPrize:getCsbName()
    return "InBox/InboxItem_Common_Reward.csb"
end

-- 描述说明
function InboxItem_GrandPrize:getDescStr()
    return "CONGRATS, YOU HAVE SPLIT THE GRAND PRIZE!"
end

function InboxItem_GrandPrize:collectMailSuccess()
    self:gainRewardSuccess()
    self:removeSelfItem()
end

-- 领取成功
function InboxItem_GrandPrize:gainRewardSuccess()
    -- local _rewardData = {}
    -- if self.m_mailData.awards ~= nil then
    --     if self.m_mailData.awards.coins and tonumber(self.m_mailData.awards.coins) > 0 then
    --         _rewardData.coins = tonumber(self.m_mailData.awards.coins)
    --     end
    -- end
    -- if table.nums(_rewardData) > 0 then
    --     G_GetMgr(ACTIVITY_REF.GrandPrize):showRewardLayer(_rewardData)
    -- end
end

return InboxItem_GrandPrize
