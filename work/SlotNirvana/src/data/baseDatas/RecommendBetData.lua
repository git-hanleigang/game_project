--
-- 推荐bet 档位列表信息
-- 
-- Date: 2019-04-10 17:49:08
--
local RecommendBetData = class("RecommendBetData")

RecommendBetData.p_betId = nil 
RecommendBetData.p_totalBetValue = nil -- total bet
RecommendBetData.p_unlockJackpot = nil -- 解锁jackpot 信息， mini 、 minor 、 major 、 grand 等等
RecommendBetData.p_unlockedType = nil -- 解锁标识， 这个每关可能定义的并不同
RecommendBetData.p_available = nil -- 此bet 是否已经解锁了

function RecommendBetData:ctor()
    
end


function RecommendBetData:parseData( data )

      self.p_betId = data.betId
      self.p_totalBetValue = tonumber(data.totalBet) -- total bet
      self.p_unlockJackpot = data.jackpot -- 解锁jackpot 信息， mini 、 minor 、 major 、 grand 等等
      self.p_unlockedType = data.unlockFeature -- 解锁标识， 这个每关可能定义的并不同
      self.p_available = data.available

end

return  RecommendBetData