
-- optional int64 rewardId = 1;
-- optional int32 points = 2; //需要的分数
-- optional int64 coins = 3; //金币
-- optional string status = 4; //状态：COLLECTED、COLLECT、LOCK
-- optional int32 level = 5;
-- repeated ShopItem rewards = 6; //其他物品奖励
-- optional LuckyChallengeDiceBonus diceBonus = 7; //LuckyChallengeDiceBonus
local CommonRewards = require "data.baseDatas.CommonRewards"
local LCDiceGameData = require "data.luckyChallenge.LCDiceGameData"
local LCPickGameData = require "data.luckyChallenge.LCPickGameData"
local ShopItem = require "data.baseDatas.ShopItem"

local LuckyChallengeReward = class("LuckyChallengeReward")

function LuckyChallengeReward:ctor()

end

function LuckyChallengeReward:parseData(data,isJson)
    self.rewardId = tonumber(data.rewardId) -- 类型
    self.points = data.points --需要的分数
    self.coins = data.coins
    self.value = data.value --奖励的值
    self.status = data.status --状态：COLLECTED、COLLECT、LOCK

    self.level = data.level
    self.rewards = self:parseItems(data.rewards)
    -- for i=1,#data.rewards do
    --     local temp = CommonRewards:create()
    --     temp:parseData(data.rewards[i])
    --     self.rewards[i] = temp
    -- end
    if data.diceBonus then
    -- if data:HasField("diceBonus") then
        self.diceBonus = LCDiceGameData:create()
        self.diceBonus:parseData(data.diceBonus) --状态：COLLECTED、COLLECT、LOCKdata.diceBonus
    end
    if data.pickBonus then
        local temp = LCPickGameData:create()
        temp:parseData(data.pickBonus)
        self.pickBonus = temp
    end
    self.getReward = data.getReward
end

function LuckyChallengeReward:resetJackpot()
    if self.pickBonus then
        self.pickBonus:resetJackpot()
    end
end




function LuckyChallengeReward:parseItems(data,isJson)
    local items = {}
    if data ~= nil and #data > 0 then
          for i=1,#data do
                local shopItemCell = ShopItem:create()
                shopItemCell:parseData(data[i],true)
                items[i]=shopItemCell
          end
    end
    return items
end
function LuckyChallengeReward:getDiceBonusData()
    return self.diceBonus
end

function LuckyChallengeReward:getPickBonusData()
    return self.pickBonus
end

return  LuckyChallengeReward

