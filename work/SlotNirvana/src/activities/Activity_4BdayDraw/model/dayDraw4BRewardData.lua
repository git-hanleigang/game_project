--[[
    活动结束后分奖
]]

local dayDraw4BRewardData = class("dayDraw4BRewardData")

function dayDraw4BRewardData:ctor()
    self.p_coins = 0
    self.p_dollars = "0"
end

-- message FourBirthdayDrawReward {
--     optional string dollars = 1;//美刀
--     optional string coins = 2;
--   }
function dayDraw4BRewardData:parseData(_data)
    self.p_coins = tonumber(_data.coins)
    self.p_dollars = _data.dollars
end

function dayDraw4BRewardData:getCoins()
    return self.p_coins
end

function dayDraw4BRewardData:getDollars()
    return self.p_dollars
end

function dayDraw4BRewardData:clearData()
    self.p_coins = 0
    self.p_dollars = "0"
end

return dayDraw4BRewardData