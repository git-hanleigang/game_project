--[[--
    第二条任务线小游戏
    pcik小游戏数据解析
]]
local NewDCPickGameJackpotData = class("NewDCPickGameJackpotData")

function NewDCPickGameJackpotData:ctor()
    self.p_jackpotCoins = toLongNumber(0)
end

--[[
    message LuckyChallengeV2PickBonusJackpot {
        optional string jackpotType = 1; // jackpot的类型
        optional string jackpotCoins = 2; // jackpot的金币
    }
]]
function NewDCPickGameJackpotData:parseData(data)
    self.p_jackpotType = data.jackpotType
    self.p_jackpotCoins:setNum(data.jackpotCoins or 0) 
end

function NewDCPickGameJackpotData:getJpType()
    return self.p_jackpotType
end

function NewDCPickGameJackpotData:getJpCoins()
    return self.p_jackpotCoins
end

return NewDCPickGameJackpotData
