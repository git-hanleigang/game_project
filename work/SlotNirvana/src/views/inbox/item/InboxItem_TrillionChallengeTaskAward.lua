--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-10-12 14:42:49
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-10-12 14:44:21
FilePath: /SlotNirvana/src/views/inbox/item/InboxItem_TrillionChallengeTaskAward.lua
Description: 亿万赢钱挑战 任务 邮件
--]]
local InboxItem_base = util_require("views.inbox.item.InboxItem_baseReward")
local InboxItem_TrillionChallengeTaskAward = class("InboxItem_TrillionChallengeTaskAward", InboxItem_base)

function InboxItem_TrillionChallengeTaskAward:getCsbName()
    return "InBox/InboxItem_TrillionChallenge.csb"
end

-- 描述说明
function InboxItem_TrillionChallengeTaskAward:getDescStr()
    return self.m_mailData.title or "TRILLION WINNER TASK REWARDS"
end

return InboxItem_TrillionChallengeTaskAward