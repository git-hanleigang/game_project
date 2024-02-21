--[[
    箱子数据
    author:{author}
    time:2021-11-26 16:21:49
]]
local PickBonusBox = class("PickBonusBox")

function PickBonusBox:ctor()
    self.type = ""
    self.coins = 0
    self.pick = false
end

function PickBonusBox:parseData(data)
    self.type = data.type
    self.coins = tonumber(data.coins)
    self.pick = data.pick
end

function PickBonusBox:isPicked()
    return self.pick
end

function PickBonusBox:getType()
    return self.type
end

function PickBonusBox:getCoins()
    return self.coins
end

return PickBonusBox
