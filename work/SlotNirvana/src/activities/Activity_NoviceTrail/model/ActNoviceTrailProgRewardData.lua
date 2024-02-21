--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-06-27 17:58:04
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-06-27 18:00:38
FilePath: /SlotNirvana/src/activities/Activity_NoviceTrail/model/ActNoviceTrailProgRewardData.lua
Description: 新手期三日任务 累计进度条 奖励数据
--]]
local ActNoviceTrailProgRewardData = class("ActNoviceTrailProgRewardData")
local ShopItem = util_require("data.baseDatas.ShopItem")

function ActNoviceTrailProgRewardData:ctor(_serverData)
    if not _serverData then
        return
    end

    self.m_bCollect = _serverData.collect --是否领取
    self.m_points = _serverData.points or 0 --点数奖励
    self.m_coins = tonumber(_serverData.coins) or 0 --美金奖励
    -- 奖励道具
    self:parseRewardList(_serverData.items or {})
end

-- 奖励道具
function ActNoviceTrailProgRewardData:parseRewardList(_list)
    self.m_rewardList = {} -- 物品奖励
    self.m_rewardNoCoinsList = {} -- 物品奖励 不带金币
    if self.m_coins > 0 then
        local itemData = gLobalItemManager:createLocalItemData("Coins", "$"..self.m_coins)
        table.insert(self.m_rewardList, itemData)
    end

    for k, data in ipairs(_list) do
        local shopItem = ShopItem:create()
        shopItem:parseData(data)
        table.insert(self.m_rewardList, shopItem)
        table.insert(self.m_rewardNoCoinsList, shopItem)
    end
end

function ActNoviceTrailProgRewardData:getCurPoints()
    return self.m_points
end
function ActNoviceTrailProgRewardData:getCheckCollected()
    return self.m_bCollect
end
function ActNoviceTrailProgRewardData:getCoins()
    return self.m_coins
end
function ActNoviceTrailProgRewardData:getRewardList()
    return self.m_rewardList
end

return ActNoviceTrailProgRewardData