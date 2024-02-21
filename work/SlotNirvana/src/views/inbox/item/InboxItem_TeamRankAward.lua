--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2022-08-01 12:21:45
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2022-08-01 12:21:55
FilePath: /SlotNirvana/src/views/inbox/team/InboxItem_TeamRankAward.lua
Description: 公会排行榜结算 邮件
--]]
local InboxItem_TeamRankAward = class("InboxItem_TeamRankAward", util_require("views.inbox.item.InboxItem_baseReward"))

function InboxItem_TeamRankAward:getCsbName()
    return "InBox/InboxItem_ClubRank.csb"
end
-- 如果有掉卡，在这里设置来源
function InboxItem_TeamRankAward:getCardSource()
    return {"Clan Rank"}
end

-- 描述说明
function InboxItem_TeamRankAward:getDescStr()
    return self.m_mailData.title 
end

return InboxItem_TeamRankAward