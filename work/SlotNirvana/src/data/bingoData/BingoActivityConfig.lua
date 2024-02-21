--[[
    author:JohnnyFred
    time:2020-06-23 14:30:10
]]
local BingoWildBallActivityConfig = util_require("data.bingoData.BingoWildBallActivityConfig")
local BingoActivityConfig = class("BingoActivityConfig")

function BingoActivityConfig:parseData(data)
    if data.wildBalls ~= nil then
        self.wildBallConfig = BingoWildBallActivityConfig:create()
        self.wildBallConfig:parseData(data.wildBalls)
    end
end

function BingoActivityConfig:getWildBallConfig()
    return self.wildBallConfig
end

return  BingoActivityConfig