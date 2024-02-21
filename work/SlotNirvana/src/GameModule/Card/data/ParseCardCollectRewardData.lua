--[[
    集齐奖励
    章节、赛季
]]
-- message CardCollectReward {
--     optional int64 coins = 1; //奖励金币数量
--     repeated ShopItem rewards = 2; //其他奖励物品
--     optional string id = 3; //赛季卡册id或者卡组id
--     optional CardDropInfo cardDrop = 4;
--     optional string clanType = 5;// 卡册类型
--     optional int32 clanCardNum = 6;// 卡册中已收集卡的数量
--     repeated BuffItem buffs = 7; //用户的buff
--   }
local BuffItem = require "data.baseDatas.BuffItem"
local ShopItem = require "data.baseDatas.ShopItem"
local ParseCardCollectRewardData = class("ParseCardCollectRewardData")
function ParseCardCollectRewardData:ctor()
end

function ParseCardCollectRewardData:parseData(_netData)
    self.coins = tonumber(_netData.coins)

    self.rewards = {}
    if _netData.rewards and #_netData.rewards > 0 then
        for i = 1, #_netData.rewards do
            if _netData.rewards[i].p_id then
                table.insert(self.rewards, _netData.rewards[i])
            else
                local sItem = ShopItem:create()
                sItem:parseData(_netData.rewards[i])
                table.insert(self.rewards, sItem)
            end
        end
    end

    self.id = _netData.id
    self.clanType = _netData.clanType
    self.phaseChips = _netData.clanCardNum or _netData.phaseChips

    if _netData.cardDrop and _netData.cardDrop.source ~= nil and _netData.cardDrop.source ~= "" then -- 加判断，防止死循环，因为存在类相互引用，这里通过数据去控制不死循环，目前没有更好的方案
        local ParseCardDropData = require("GameModule.Card.data.ParseCardDropData")
        self.cardDrop = ParseCardDropData:create()
        self.cardDrop:parseData(_netData.cardDrop)
    end

    if _netData.buffs and #_netData.buffs > 0 then
        globalData.syncBuffs(_netData.buffs)
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_MULEXP_END)
    end
end

function ParseCardCollectRewardData:getClanId()
    return self.id
end

function ParseCardCollectRewardData:getClanType()
    return self.clanType
end

-- 完成此章节奖励，需要获得的章节筹码数量
function ParseCardCollectRewardData:getPhaseChips()
    return self.phaseChips or 0
end

function ParseCardCollectRewardData:getCoins()
    return self.coins
end

function ParseCardCollectRewardData:getRewards()
    return self.rewards
end

function ParseCardCollectRewardData:getBuffItems()
    local buffItems = {}
    if self.rewards and #self.rewards > 0 then
        for i=1,#self.rewards do
            local itemData = clone(self.rewards[i])
            if itemData:isBuff() then
                table.insert(buffItems, itemData)
            end
        end
    end
    return buffItems
end

return ParseCardCollectRewardData
