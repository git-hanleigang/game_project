--jackport 数据
local BlastJackData = class("BlastJackData")

function BlastJackData:ctor()
    self.m_coins = toLongNumber(0)
end

function BlastJackData:parseData(data)
   self.m_jackpot = data.jackpot
   self.m_count = data.count
   if data.coinsV2 and data.coinsV2 ~= "" then
       self.m_coins:setNum(data.coinsV2) 
   else
       self.m_coins:setNum(data.coins)
   end
end

function BlastJackData:getCoins()
    return self.m_coins
end

function BlastJackData:getJackpot()
    return self.m_jackpot
end

function BlastJackData:getCount()
    return self.m_count
end

return BlastJackData
