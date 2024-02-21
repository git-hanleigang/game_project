--
--版权所有:{company}
-- Author:{author}
-- Date: 2019-04-10 17:52:13
--
local MegaResult = class("MegaResult")
MegaResult.p_id = nil
MegaResult.p_bet = nil
MegaResult.p_multiply = nil
MegaResult.p_totalWin = nil

function MegaResult:ctor()
    
end

function MegaResult:parseData(data)
      self.p_id = data.id or 0
      self.p_bet = tonumber(data.bet) or 0
      self.p_multiply = data.multiply or 0
      self.p_totalWin = tonumber(data.totalWin)
end

return  MegaResult