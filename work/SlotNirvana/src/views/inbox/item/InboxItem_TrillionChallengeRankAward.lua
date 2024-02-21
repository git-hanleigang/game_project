--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-10-12 14:42:34
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-10-12 14:43:01
FilePath: /SlotNirvana/src/views/inbox/item/InboxItem_TrillionChallengeRankAward.lua
Description: 亿万赢钱挑战 排行邮件
--]]
local InboxItem_base = util_require("views.inbox.item.InboxItem_baseReward")
local InboxItem_TrillionChallengeRankAward = class("InboxItem_TrillionChallengeRankAward", InboxItem_base)

function InboxItem_TrillionChallengeRankAward:getCsbName()
    return "InBox/InboxItem_TrillionChallenge.csb"
end

-- 描述说明
function InboxItem_TrillionChallengeRankAward:getDescStr()
    return self.m_mailData.title or "TRILLION WINNER RANK REWARDS"
end

return InboxItem_TrillionChallengeRankAward