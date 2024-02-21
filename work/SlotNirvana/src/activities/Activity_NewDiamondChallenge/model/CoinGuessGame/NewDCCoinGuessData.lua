--[[
    猜正反
]]

local NewDCCoinGuessData = class("NewDCCoinGuessData")

function NewDCCoinGuessData:ctor()
    self.p_coins = toLongNumber(0)
    self.p_guessCoinbase = toLongNumber(0)
end

-- message LuckyChallengeV2CoinGuess {
--     optional string status = 1; // 小游戏的状态  LOCK：初始化奖励数据的时候，PREPARE：当pass进度达到可领取的条件的时候，PLAYING：点击领取的时候 初始化小游戏数据，REWARD：最后一次选择的时候进行效验 提供给客户端弹领奖弹板， FINISH：领完奖品之后的
--     repeated int32 disappear = 2; // 各个阶段消失的个数
--     repeated string multipleStage = 3; // 存放各个阶段的倍数
--     optional string multiple = 4; // 存放最终的乘倍
--     optional string coins = 5; // 赢得的金币
--     optional int32 level = 6;// 对应pass节点当中的level
--     optional string guessCoinbase = 7; // 金币系数 初始化奖励的时候进行赋值
--     optional int32 coinNum = 8; //金币总数
--   }
function NewDCCoinGuessData:parseData(_data)
    self.p_status = _data.status
    self.p_disappear = _data.disappear
    self.p_multipleStage = _data.multipleStage
    self.p_multiple = _data.multiple
    self.p_level = tonumber(_data.level)
    self.p_coinNum = _data.coinNum
    self.p_miniGameType = "COIN_GUESS"
    self.p_coins:setNum(_data.coins)
    self.p_guessCoinbase:setNum(_data.guessCoinbase)
end

function NewDCCoinGuessData:getStatus()
    return self.p_status
end

function NewDCCoinGuessData:getCoins()
    return self.p_coins
end

function NewDCCoinGuessData:getDisappear()
    return self.p_disappear
end

function NewDCCoinGuessData:getMultipleStage()
    return self.p_multipleStage
end

function NewDCCoinGuessData:getMultiple()
    return self.p_multiple
end

function NewDCCoinGuessData:getLevel()
    return self.p_level
end

function NewDCCoinGuessData:getGuessCoinbase()
    return self.p_guessCoinbase
end

function NewDCCoinGuessData:getCoinNum()
    return self.p_coinNum
end

function NewDCCoinGuessData:isPrepareStatus()
    return self.p_status == "PREPARE"
end

function NewDCCoinGuessData:isLockStatus()
    return self.p_status == "LOCK"
end

function NewDCCoinGuessData:isPlayingStatus()
    return self.p_status == "PLAYING"
end

function NewDCCoinGuessData:isRewardStatus()
    return self.p_status == "REWARD"
end

function NewDCCoinGuessData:isFinishStatus()
    return self.p_status == "FINISH"
end

function NewDCCoinGuessData:getMiniGameType()
    return self.p_miniGameType
end

return NewDCCoinGuessData
