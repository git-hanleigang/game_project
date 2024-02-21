--[[
    author:{author}
    time:2019-04-18 21:53:40
]]
local RepartBaseData = require "data.baseDatas.RepartBaseData"
local RepartJackpotData = class("RepartJackpotData",RepartBaseData)
--奖池上线
function RepartJackpotData:getLimitPrize()
    if self.m_multiple and self.m_multiple>0 and self.m_multiple<999 then
        local bet = globalData.slotRunData:getCurTotalBet()
        return bet*self.m_multiple
    end
    return nil
end
--获取描述信息
function RepartJackpotData:getStrPrize()
    return self.m_purchaseMul
end

return RepartJackpotData