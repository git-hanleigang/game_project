--[[--
    第二条任务线小游戏
    骰子小游戏数据解析
    message LuckyChallengeDiceBonus {
        optional string status = 1; //状态 PREPARE,PLAYING,FINISH
        optional int64 coins = 2; //金币奖励
        repeated DiceUpPosition dicePositions = 3; //[1,2,3,-1,5,6,7,-1] -1表示没翻过来，-2表示again失败,5表示again成功
        repeated int64 allCoins = 4; //1-8的所有奖励
    }
    message DiceUpPosition {
        repeated int32 positions = 3; //[1,2,3,-1,5,6,7,-1] -1表示没翻过来，-2表示again失败,5表示again成功
    }
]]
local CommonRewards = require "data.baseDatas.CommonRewards"
local LCDiceGameData = class("LCDiceGameData")

function LCDiceGameData:ctor()
end

function LCDiceGameData:parseData(data)
    self.status = data.status

    self.coins = tonumber(data.coins)
    -- if data:HasField("dicePositions") then
    if data.dicePositions then
        self.dicePositions = {}
        local ddp = data.dicePositions
        for i=1,#ddp do
            local dp = ddp[i]
            if dp and dp.positions then
                self.dicePositions[i] = {}
                for j=1,#dp.positions do
                    self.dicePositions[i][j] = dp.positions[j]
                end
            end
        end
    end

    if data.allCoins then
        self.allCoins = {}
        for i=1,#data.allCoins do
            self.allCoins[i] = tonumber(data.allCoins[i])
        end
    end
end

return  LCDiceGameData