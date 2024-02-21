--[[
Author: your name
Date: 2022-03-10 17:00:32
LastEditTime: 2022-03-10 17:00:33
LastEditors: your name
Description: 打开koroFileHeader查看配置 进行设置: https://github.com/OBKoro1/koro1FileHeader/wiki/%E9%85%8D%E7%BD%AE
FilePath: /SlotNirvana/src/activities/Activity_CoinPusher/model/data/CoinPusherEasterEggData.lua
--]]
local CoinPusherEasterEggData = class("CoinPusherEasterEggData", util_require("activities.Activity_CoinPusher.model.data.CoinPusherBaseActionData"))
local TAG_EVENT = "DropEasterEgg"

function CoinPusherEasterEggData:ctor()
    CoinPusherEasterEggData.super.ctor(self)
end

--重写ActionData 拆分组装ActionData
function CoinPusherEasterEggData:setActionData(data)
    self._RunningData.ActionData = data

    --初始弹窗状态
    local extraActionStates = self:getExtraActionState()
    extraActionStates[TAG_EVENT] = self._Config.PlayState.IDLE
end

--设置弹窗状态
function CoinPusherEasterEggData:setPopViewActionState(state)
    local extraActionStates = self:getExtraActionState()
    extraActionStates[TAG_EVENT] = state
end

function CoinPusherEasterEggData:getPopViewState()
    local extraActionStates = self:getExtraActionState()
    return extraActionStates[TAG_EVENT]
end

function CoinPusherEasterEggData:getDropEggData()
    -- local data = self:getActionData()

end
return CoinPusherEasterEggData