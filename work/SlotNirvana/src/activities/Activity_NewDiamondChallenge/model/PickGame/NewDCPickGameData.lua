--[[--
    第二条任务线小游戏
    pcik小游戏数据解析
]]
local NewDCPickGameBoxData = import(".NewDCPickGameBoxData")
local NewDCPickGameJackpotData = import(".NewDCPickGameJackpotData")
local NewDCPickGameData = class("NewDCPickGameData")

function NewDCPickGameData:ctor()
    self.p_coins = toLongNumber(0)
end

--[[
    message LuckyChallengeV2PickBonus {
        optional string status = 1;// 小游戏的状态
        optional string multiple = 2; // 最终的乘倍
        optional string coins = 3; // 赢钱
        optional int32 playTimes = 4;// 可以选择几次/
        repeated LuckyChallengeV2PickBonusJackpot jackpot = 5; // jackpot
        repeated LuckyChallengeV2PickBonusBox box = 6;// box每个选项值
        optional int32 level = 7;// 对应pass节点当中的level
    }
]]
function NewDCPickGameData:parseData(data)
    self.p_status = data.status
    self.p_multiple = data.multiple
    self.p_coins:setNum(data.coins or 0)
    self.p_playTimes = data.playTimes
    self.p_jackpot = {}
    if data.jackpot and #data.jackpot > 0 then
        for i=1,#data.jackpot do
            local jackpotData = NewDCPickGameJackpotData:create()
            jackpotData:parseData(data.jackpot[i])
            -- table.insert(self.p_jackpot, jackpotData)
            self.p_jackpot["" .. jackpotData:getJpType()] = jackpotData
        end
    end
    self.p_box = {}
    if data.box and #data.box > 0 then
        for i=1,#data.box do
            local boxData = NewDCPickGameBoxData:create()
            boxData:parseData(data.box[i])
            table.insert(self.p_box, boxData)
        end
    end    
    self.p_level = data.level
    self.p_miniGameType = "PICK_BOX"
end

function NewDCPickGameData:getStatus()
    return self.p_status
end

function NewDCPickGameData:isPlayingStatus()
    return self.p_status == "PLAYING"
end

function NewDCPickGameData:getMultiple()
    return self.p_multiple
end

function NewDCPickGameData:getCoins()
    return self.p_coins or toLongNumber(0)
end

function NewDCPickGameData:getPlayTimes()
    return self.p_playTimes
end

function NewDCPickGameData:getJackpot(_type)
    if not _type then
        return self.p_jackpot
    end

    return self.p_jackpot["" .. _type]
end

function NewDCPickGameData:getBox()
    return self.p_box
end

function NewDCPickGameData:getLevel()
    return self.p_level
end

function NewDCPickGameData:getMiniGameType()
    return self.p_miniGameType
end

return NewDCPickGameData
