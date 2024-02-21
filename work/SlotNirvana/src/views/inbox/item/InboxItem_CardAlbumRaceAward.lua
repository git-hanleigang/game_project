--[[
    holidayChallenge 节日挑战邮件奖励
]]

local ShopItem = util_require("data.baseDatas.ShopItem")
local InboxItem_base = util_require("views.inbox.item.InboxItem_baseReward")
local InboxItem_CardAlbumRaceAward = class("InboxItem_CardAlbumRaceAward", InboxItem_base)

function InboxItem_CardAlbumRaceAward:getCsbName()
    return "InBox/InboxItem_Common_Reward.csb"
end

-- 描述说明
function InboxItem_CardAlbumRaceAward:getDescStr()
    return self.m_mailData.title or "Album Race Special Offer"
end

function InboxItem_CardAlbumRaceAward:collectMailSuccess()
    self:gainRewardSuccess()
    self:removeSelfItem()
end

function InboxItem_CardAlbumRaceAward:initReward()
    if self.m_node_reward then
        self.m_node_reward:setVisible(false)
    end
    local sp_reward_bg = self:findChild("sp_reward_bg")
    if sp_reward_bg then
        sp_reward_bg:setVisible(false)
    end
end

-- 领取成功
function InboxItem_CardAlbumRaceAward:gainRewardSuccess()
    -- 需要做一个通用弹板，因为后面需要
    local _rewardData = {}
    if self.m_mailData.awards ~= nil then
        if CardSysManager:needDropCards("Card Album Race Rewards") == true then
            -- 卡包开完消息 只在自己触发掉卡的时候监听 监听早了会被其他地方掉卡影响
            CardSysManager:doDropCards("Card Album Race Rewards")
        end
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_DROP_DELUXE_CARD_ITEM)
        -- 刷新高倍场点数
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_DELUEXECLUB_POINT_UPDATE)
    end
end

return  InboxItem_CardAlbumRaceAward