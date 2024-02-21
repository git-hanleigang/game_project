-- word 进度条 奖励
local ShopItem = util_require("data.baseDatas.ShopItem")
local WordProgressRewardData = class("WordProgressRewardData")

-- message WordProgressRewards {
--     optional int64 coins = 1;
--     repeated ShopItem items = 2;
--     optional string coinValue = 3;
--     optional int32 treasureId = 4;//宝箱id
--     optional int32 jackpotId = 5;//jackpoctId
--     optional int32 scoop = 6; //挖宝道具数量
--     optional string type = 7;// 奖励类型
--     optional string coinsV2 = 8;
--   }
function WordProgressRewardData:parseData(_netData)
    self.p_coins = _netData.coinsV2

    self.p_items = {}
    if _netData.items and #_netData.items > 0 then
        for i = 1, #_netData.items do
            local shopData = ShopItem:create()
            shopData:parseData(_netData.items[i])
            table.insert(self.p_items, shopData)
        end
    end    

    self.p_coinValue = _netData.coinValue
    self.p_treasureId = _netData.treasureId
    self.p_jackpotId = _netData.jackpotId
    self.p_scoop = _netData.scoop
    self.key = _netData.type
end

function WordProgressRewardData:getcoins()
    return self.p_coins
end

function WordProgressRewardData:getcoinValue()
    return self.p_coinValue
end

function WordProgressRewardData:gettreasureId()
    return self.p_treasureId
end

function WordProgressRewardData:getRewardList()
    return self.p_rewardList
end

function WordProgressRewardData:getRewardType()
    return self.key
end

function WordProgressRewardData:getJackpotType()
    return self.p_jackpotId
end

function WordProgressRewardData:getScoop()
    return self.p_scoop
end

-- 设置完成条件 因为现在是固定的触发条件 服务器没有 暂时写在客户端 以后有改动找服务器加
function WordProgressRewardData:setCompletePercent( idx )
    if idx == 1 then
        self.completePercent = 50
    elseif idx == 2 then
        self.completePercent = 100
    end
end

function WordProgressRewardData:getCompletePercent()
    return self.completePercent
end

return WordProgressRewardData