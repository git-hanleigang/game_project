--[[
    StarPick小游戏
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
local PickBonusBox = import(".PickBonusBox")
local PickGameData = class("PickGameData")
function PickGameData:ctor()
    self.boxes = {}
    self.boxType = {}
end

function PickGameData:parseData(data)
    self.m_id = data.index
    if data.jackpotCoins then
        self.jackpotCoins = {}
        for i = 1, #data.jackpotCoins do
            self.jackpotCoins[i] = tonumber(data.jackpotCoins[i])
        end
    end

    self.expireAt = tonumber(data.expireAt)
    self.status = data.status
    self.coins = tonumber(data.coins)

    if data.boxes then
        for i = 1, #data.boxes do
            local _boxInfo = self.boxes[i]
            if not _boxInfo then
                _boxInfo = PickBonusBox:create()
            end
            _boxInfo:parseData(data.boxes[i])
            self.boxes[i] = _boxInfo

            local _type = _boxInfo:getType()
            local _hasType = self.boxType[_type]
            if not _hasType then
                self.boxType[_type] = true
            end
        end
    end
    printInfo("=====")
end

function PickGameData:getId()
    return self.m_id
end

function PickGameData:getExpireAt()
    return self.expireAt
end

function PickGameData:isPlaying()
    return self.status == "PLAYING"
end

function PickGameData:createBox(data)
    local box = {}
    box.type = data.type
    box.coins = tonumber(data.coins)
    box.pick = data.pick
    return box
end

function PickGameData:getJackpot()
    return self.jackpotCoins
end

-- function PickGameData:checkStatus()
--     if self.status == GPBonusCfg.PICK_GAME_STATUS.lock then
--         return false
--     end
--     return true
-- end

function PickGameData:getTotalwinCoins()
    -- local coins = 0
    -- for i = 1, self.m_pickCount do
    --     local c = self.m_starData[i].coins
    --     if self.m_starData[i].type == GPBonusCfg.PICK_TYPE.MULCoin then
    --         coins = coins * c
    --     else
    --         if coins <= 0 and c < 0 then
    --             c = 0
    --         end
    --         coins = coins + c
    --     end
    -- end
    -- return coins
    return self.coins
end

function PickGameData:isPicked(nIndex)
    local _boxInfo = self.boxes[nIndex]
    if not _boxInfo then
        return false
    end

    return _boxInfo:isPicked()
end

function PickGameData:isFinished()
    return self.status == GPBonusCfg.PICK_GAME_STATUS.FINISH
end

function PickGameData:getBoxInfo(nIndex)
    if not nIndex then
        return nil
    end

    return self.boxes[nIndex]
end

function PickGameData:isJackpotLight(jackpotType)
    -- for i = 1, #self.boxes do
    --     local info = self.boxes[i]

    --     if info:getType() == jackpotType then
    --         return true
    --     end
    -- end

    -- return false
    return self.boxType[jackpotType] or false
end

return PickGameData
