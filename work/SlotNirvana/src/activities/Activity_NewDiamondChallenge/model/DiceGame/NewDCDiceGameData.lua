--[[--
    第二条任务线小游戏
    骰子小游戏数据解析
    message LuckyChallengeV2DiceBonus {
        optional string status = 1;// 小游戏的状态
        optional string coins = 2;// 赢钱
        repeated LuckyChallengeV2DiceBonusPosition dicePositions = 3;// 每次股子出现的位置
        repeated string allCoins = 4;//奖池当中的数据
        optional int32 level = 5;// 对应pass节点当中的level
    }

    message LuckyChallengeV2DiceBonusPosition{
        repeated int32 positions = 1;
    }
]]
local NewDCDiceGameData = class("NewDCDiceGameData")

function NewDCDiceGameData:ctor()
    self.p_coins = toLongNumber(0)
end

function NewDCDiceGameData:parseData(data)
    self.p_status = data.status
    self.p_coins:setNum(data.coins or 0)
    self.p_dicePositions = self:parseDiceUpPosition(data.dicePositions)
    self.p_allCoins = self:parseAllCoins(data.allCoins)
    self.p_level = tonumber(data.level)
    self.p_miniGameType = "DICE_BONUS"
end

function NewDCDiceGameData:parseDiceUpPosition(data)
    local positionsArr = {}
    if data then
        for i, v in ipairs(data) do
            positionsArr[i] = {}
            for j, pos in ipairs(v.positions) do
                positionsArr[i][j] = pos
            end
        end
    end
    return positionsArr
end

function NewDCDiceGameData:parseAllCoins(data)
    local allCoins = {}
    if data and #data > 0 then
        for i, v in ipairs(data) do
            table.insert(allCoins, toLongNumber(v))
        end
    end
    return allCoins
end

function NewDCDiceGameData:getStatus()
    return self.p_status
end

function NewDCDiceGameData:getCoins()
    return self.p_coins or toLongNumber(0)
end

function NewDCDiceGameData:getDicePositions()
    return self.p_dicePositions or {}
end

function NewDCDiceGameData:getAllCoins()
    return self.p_allCoins or {}
end

function NewDCDiceGameData:getCoinsByIndex(_index)
    local allCoins = self:getAllCoins()
    return allCoins[_index] or toLongNumber(0)
end

function NewDCDiceGameData:getLevel()
    return self.p_level
end

function NewDCDiceGameData:isPlayingStatus()
    return self.p_status == "PLAYING"
end

function NewDCDiceGameData:getMiniGameType()
    return self.p_miniGameType
end

return NewDCDiceGameData
