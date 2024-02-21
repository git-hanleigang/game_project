
local CommonRewards = require "data.baseDatas.CommonRewards"
local LuckyChallengeSimpleRank = class("LuckyChallengeSimpleRank")

function LuckyChallengeSimpleRank:ctor()

end
--   message LuckyChallengeSimpleRank {
--     repeated RankUser users = 1; //排行前3的几个人的数据
--     optional int64 totalCoins = 2; //金币大奖的总值
--     repeated ShopItem rewards = 3; //其他物品奖励
--   }
function LuckyChallengeSimpleRank:parseData(data,isJson)
    self.users = {}--排行前3的几个人的数据
    if data.users then
        for i=1,#data.users do
            local temp = self:createRankUser(i,data.users[i])
            self.users[i] = temp
        end
    end

    self.totalCoins = data.totalCoins --金币大奖的总值
    self.rewards = {}
    if data.rewards then
        for i=1,#data.rewards do
            local temp = CommonRewards:create()
            temp:parseData(data.rewards[i])
            self.rewards[i] = temp
        end
    end

end

--RankUser
function LuckyChallengeSimpleRank:createRankUser(index,data)
    local rankUser =
    {
        p_rank = data.rank,
        p_name = data.name,
        p_points = data.points,
        p_udid = data.udid,
        p_fbid = data.facebookId,
        p_frameId = data.frame,
    }
    if index ~= nil then
        rankUser.p_index = index
    end
    return rankUser
end


return  LuckyChallengeSimpleRank

