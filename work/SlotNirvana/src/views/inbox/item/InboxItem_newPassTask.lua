--[[
    活动任务邮件
]]
local ShopItem = require "data.baseDatas.ShopItem"
local InboxItem_newPassTask = class("InboxItem_newPassTask", util_require("views.inbox.item.InboxItem_baseReward"))

function InboxItem_newPassTask:getCsbName( )
    return "InBox/InboxItem_NewPass_MissionReward.csb"
end

-- 描述说明
function InboxItem_newPassTask:getDescStr()
    return "HERE'S YOUR REWARD"
end

function InboxItem_newPassTask:collectMailSuccess()
    self:gainRewardSuccess()
    self:removeSelfItem()
end

-- 领取成功
function InboxItem_newPassTask:gainRewardSuccess()
    local _rewardData = {}
    if self.m_mailData.awards ~= nil then
        if self.m_mailData.awards.coins and tonumber(self.m_mailData.awards.coins) > 0 then
            _rewardData.coins = tonumber(self.m_mailData.awards.coins)
        end
        if self.m_mailData.awards.items ~= nil then
            _rewardData.items = {}
            for i=1,#self.m_mailData.awards.items do
                local shopItem = ShopItem:create()
                shopItem:parseData(self.m_mailData.awards.items[i], true)
               _rewardData.items[i] = shopItem
            end
            _rewardData.gems = self:getTotalGem(_rewardData.items)
        end
    end
    if next(_rewardData) ~= nil  then
        _rewardData.collectType = gLobalDailyTaskManager.COLLECT_TYPE.REWARD_TYPE
        gLobalDailyTaskManager:openRewardLayer(_rewardData,"")
    end
end

function InboxItem_newPassTask:getTotalGem(itemList)
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

return  InboxItem_newPassTask