--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2022-08-02 15:18:03
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2022-08-02 15:18:12
FilePath: /SlotNirvana/src/views/inbox/team/InboxItem_TeamRushAward.lua
Description: 公会Rush任务结算 邮件
--]]
local InboxItem_TeamRushAward = class("InboxItem_TeamRushAward", util_require("views.inbox.item.InboxItem_baseReward"))

function InboxItem_TeamRushAward:getCsbName()
    return "InBox/InboxItem_ClubRush.csb"
end
-- 如果有掉卡，在这里设置来源
function InboxItem_TeamRushAward:getCardSource()
    return {"Clan Rush"}
end

-- 描述说明
function InboxItem_TeamRushAward:getDescStr()
    return self.m_mailData.title 
end

return InboxItem_TeamRushAward