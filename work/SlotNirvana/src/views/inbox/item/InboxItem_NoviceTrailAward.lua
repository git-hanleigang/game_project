--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-06-28 12:22:29
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-06-28 14:54:09
FilePath: /SlotNirvana/src/views/inbox/InboxItem_NoviceTrailAward.lua
Description: 新手期三日任务 邮件
--]]
local InboxItem_base = util_require("views.inbox.item.InboxItem_baseReward")
local InboxItem_NoviceTrailAward = class("InboxItem_NoviceTrailAward", InboxItem_base)

-- 如果有掉卡，在这里设置来源
function InboxItem_NoviceTrailAward:getCardSource()
    return {"Novice Trail Award"}
end
-- 描述说明
function InboxItem_NoviceTrailAward:getDescStr()
    return "HERE'S YOUR REWARD"
end

function InboxItem_NoviceTrailAward:getCsbName()
    local csbName = "InBox/InboxItem_NoviceTrail.csb"
    return csbName
end
 
return InboxItem_NoviceTrailAward