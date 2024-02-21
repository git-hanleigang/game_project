--[[--
    第二条任务线小游戏
    pcik小游戏数据解析
]]
local NewDCPickGameBoxData = class("NewDCPickGameBoxData")

function NewDCPickGameBoxData:ctor()
    self.p_coins = toLongNumber(0)
end

--[[
    message LuckyChallengeV2PickBonusBox {
        optional string type = 1; //箱子类型
        optional string coins = 2; //奖励金币
        optional bool pick = 3;// 是否可选择
    }
]]
function NewDCPickGameBoxData:parseData(data)
    self.p_type = data.type
    self.p_coins:setNum(data.coins or 0)
    self.p_pick = data.pick
end

function NewDCPickGameBoxData:getType()
    return self.p_type
end

function NewDCPickGameBoxData:getValue()
    return self.p_coins
end

function NewDCPickGameBoxData:getPick()
    return self.p_pick
end

return NewDCPickGameBoxData
