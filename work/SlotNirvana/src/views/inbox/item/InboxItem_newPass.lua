--[[
    Newpass 邮件奖励
]]
local ShopItem = require "data.baseDatas.ShopItem"
local InboxItem_newPass = class("InboxItem_newPass", util_require("views.inbox.item.InboxItem_baseReward"))

function InboxItem_newPass:getCsbName()
    return "InBox/InboxItem_NewPass.csb"
end

-- 描述说明
function InboxItem_newPass:getDescStr()
    return "Daily Mission Reward", tostring(self.m_mailData.content)
end

function InboxItem_newPass:initView()
    self:initTime()
    self:initDesc()
end

function InboxItem_newPass:collectMailSuccess()
    self:gainRewardSuccess()
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_INBOX_CLOSE)
end

-- 领取成功
function InboxItem_newPass:gainRewardSuccess()
    local _rewardData = {}
    if self.m_mailData.awards ~= nil then
        if self.m_mailData.awards.coins and tonumber(self.m_mailData.awards.coins) > 0 then
            _rewardData.coins = tonumber(self.m_mailData.awards.coins)
        end
        if self.m_mailData.awards.items ~= nil then
            _rewardData.items = {}
            for i = 1, #self.m_mailData.awards.items do
                local shopItem = ShopItem:create()
                shopItem:parseData(self.m_mailData.awards.items[i], true)
                _rewardData.items[i] = shopItem
            end
            _rewardData.gems = self:getTotalGem(_rewardData.items)
        end
    end
    if next(_rewardData) ~= nil then
        _rewardData.collectType = gLobalDailyTaskManager.COLLECT_TYPE.REWARD_TYPE
        gLobalDailyTaskManager:checkExtraRewardData(_rewardData)
        gLobalDailyTaskManager:openRewardLayer(_rewardData, "")
    end
end

function InboxItem_newPass:getTotalGem(itemList)
    local gems = 0
    if itemList and #itemList > 0 then
        for i = 1, #itemList do
            local itemInfo = itemList[i]
            if itemInfo.p_icon == "Gem" then
                gems = gems + itemInfo.p_num
            end
        end
    end
    return gems
end

return InboxItem_newPass
