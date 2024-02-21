--[[
    通用奖励邮件
]]
local InboxItem_base = util_require("views.inbox.item.InboxItem_baseReward")
local InboxItem_common = class("InboxItem_common", InboxItem_base)

function InboxItem_common:getCsbName()
    return "InBox/InboxItem_Common_Reward.csb"
end
-- 如果有掉卡，在这里设置来源
function InboxItem_common:getCardSource()
    return {
        "Wanted",   --  单日特殊任务
        "Mission",  --  任务奖励邮件
        "Christmas Adven Calendar", --  圣诞台历未领取阶段奖励
        "Touchdown Match", --  全服累充
        "New User Charge", --  7日累充
        "CTS Tycoon", -- 付费排行榜
        "Grand Finale", -- 赛季末返新卡
        "Level Up Pass", -- LEVEL UP PASS
        "Farm Invaders Sale", -- 三联优惠券
        "Mergical Pass", -- 合成Pass
        "Flame Clash", -- 1v1比赛
        "Super Spin Send Item", -- LuckySpin送道具
        "Story Calendar", --  圣诞聚合 -- 签到
        "Blind Box Pass", -- 集装箱pass
        "Snowflakes Chase", --  圣诞聚合 -- pass
        "Holly Ranking", --  圣诞聚合 -- 排行榜
        "Pet Mission Reward", -- 宠物-7日任务
    }
end
-- 描述说明
function InboxItem_common:getDescStr()
    return self.m_mailData.title or ""
end

return InboxItem_common
