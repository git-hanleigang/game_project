
--[[--
    第二条任务线小游戏
    pick小游戏数据解析

    message LuckyChallengePickBonus {
        repeated int64 jackpotCoins = 1; //jackPotCoins
        optional int64 expireAt = 2; //cd解释时间（毫秒）
        optional string status = 3; //状态 PREPARE,PLAYING,FINISH
        repeated PickBonusBox boxes = 4; //奖励箱子
        optional int64 coins = 5; //总金币奖励
      }

      message PickBonusBox {
        optional string type = 1; //箱子类型 COINS,JACKPOT,OVER
        optional int64 coins = 2; //奖励金币
        optional bool pick = 3; //是否是手动点过的
      }
]]
local LCPickGameData = class("LCPickGameData")
function LCPickGameData:ctor()
end

function LCPickGameData:parseData(data)
    if data.jackpotCoins then
        self.jackpotCoins = {}
        for i=1,#data.jackpotCoins do
            self.jackpotCoins[i] = tonumber(data.jackpotCoins[i])
        end
    end

    self.expireAt = tonumber(data.expireAt)
    self.status = data.status
    self.coins = data.coins

    if data.boxes then
        self.boxes = {}
        for i=1,#data.boxes do
            self.boxes[i] = self:createBox(data.boxes[i])
        end
    end

    self.coins = data.coins
    self:resetJackpot()
end
function LCPickGameData:createBox(data)
    local box = {}
    box.type = data.type
    box.coins = tonumber(data.coins)
    box.pick = data.pick
    return box
end

function LCPickGameData:resetJackpot()
    -- local minValue = 0.7
    -- local maxPecent = 120
    -- local addTime = 60
    -- self.m_resetTIme = util_getCurrnetTime()
    -- self.m_showJackpotList = {}
    -- self.m_pieceAddList = {}
    -- for i = 1,#self.jackpotCoins do
    --     local temp = self.jackpotCoins[i]
    --     local randomNum = math.random(100,maxPecent)
    --     temp = temp * minValue * randomNum / 100
    --     self.m_showJackpotList[i] = temp
    --     local tempAdd = (self.jackpotCoins[i] - temp) / addTime
    --     self.m_pieceAddList[i] = tempAdd
    -- end

end

function LCPickGameData:getJackpot()
    -- if not self.m_resetTIme then
    --     return {}
    -- end
    -- local list = {}
    -- local curTime = util_getCurrnetTime()
    -- local timeS = curTime - self.m_resetTIme
    -- for i = 1,#self.m_showJackpotList do
    --     local temp = self.m_showJackpotList[i]
    --     local piece = self.m_pieceAddList[i]
    --     local result = (temp + piece * timeS)%self.jackpotCoins[i]
    --     list[i] = result
    -- end
    -- return list
    return self.jackpotCoins
end

return  LCPickGameData

