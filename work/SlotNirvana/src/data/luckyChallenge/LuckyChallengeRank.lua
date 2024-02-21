
local CommonRewards = require "data.baseDatas.CommonRewards"
local ShopItem = require "data.baseDatas.ShopItem"

local LuckyChallengeRank = class("LuckyChallengeRank")

function LuckyChallengeRank:ctor()

end

function LuckyChallengeRank:parseData(data,isJson)
    -- message LuckyChallengeRank {
--     repeated RankUser users = 1;
--     optional RankUser myRank = 2;
--     repeated RankReward rewards = 3;
--   }
    if not data then
        return
    end
    
    self.users = {}
    if data.users and #data.users then
        for i=1,#data.users do
            local temp = self:parseRankUserData(data.users[i])
            self.users[i] = temp
        end
        if data.myRank then
            self.myRank =  self:parseRankUserData(data.myRank)
        end
    end

    self.rewards = {}
    for i=1,#data.rewards do
        local temp = self:parseRankRewardData(data.rewards[i])
        self.rewards[i] = temp
    end
end

function LuckyChallengeRank:getRank(index)
    local result = nil
    if self.users[index] then
        result = self.users[index]
    end
    return result
end

function LuckyChallengeRank:getOnRankNum()
    return #self.users
end

function LuckyChallengeRank:getRankReward(index)
    local reward = nil
    for i=1,#self.rewards do
        if self.rewards[i].minRank <= index and self.rewards[i].maxRank >= index then
            reward = self.rewards[i]
        end
    end
    return reward
end
function LuckyChallengeRank:parseRankUserData(data,isJson)
    local temp = {}
    temp.rank = data.rank
    temp.name = data.name
    temp.points = data.points
    temp.facebookId = data.facebookId
    temp.head = data.head
    temp.frameId = data.head
    return temp
end

function LuckyChallengeRank:parseRankRewardData(data,isJson)
    --   //排行榜rewards
--   message RankReward {
--     optional int32 minRank = 1;
--     optional int32 maxRank = 2;
--     optional int64 coins = 3;
--     repeated ShopItem items = 4;
--   }
    local temp = {}
    temp.minRank = data.minRank
    temp.maxRank = data.maxRank
    temp.coins = data.coins
    temp.items = self:parseItems(data.items,isJson)

    -- if data.items then
    --     for i=1,#data.items do
    --         local temp = CommonRewards:create()
    --         temp:parseData(data.items[i])
    --         self.items[i] = temp
    --     end
    -- end

    return temp
end
function LuckyChallengeRank:parseItems(data,isJson)
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
return  LuckyChallengeRank
