local GamePusherDropCoinData = class("GamePusherDropCoinData", util_require("CandyPusherSrc.GamePusherData.GamePusherBaseActionData"))
local TAG_EVENT = "DropCoins"

function GamePusherDropCoinData:ctor(  )
    GamePusherDropCoinData.super.ctor(self)
end

--重写ActionData 拆分组装ActionData
function GamePusherDropCoinData:setActionData(data)
    self.m_tRunningData.ActionData = data

    --初始化掉金币状态
    local extraActionStates = self:getExtraActionState()
    extraActionStates[TAG_EVENT] = self.m_pConfig.PlayState.IDLE
end

function GamePusherDropCoinData:setCoinActionState(state)
   --初始化掉金币状态
   local extraActionStates = self:getExtraActionState()
   extraActionStates[TAG_EVENT] = state
end

function GamePusherDropCoinData:getDropCoinState()
   --初始化掉金币状态
   local extraActionStates = self:getExtraActionState()
   return extraActionStates[TAG_EVENT]
end

function GamePusherDropCoinData:reduceCoinsCount(coinType)
    local actionData = self:getActionData()
    local coinsData = actionData[1]
    local bNotDrop = false

    for k,v in pairs(coinsData) do
        if k == coinType and v > 0 then
            coinsData[k] = v - 1
        end
        if v > 0 then
            bNotDrop = true
        end
    end
    --全部都create了 掉金币状态置为Done
    if not  bNotDrop then
        self:setCoinActionState(self.m_pConfig.PlayState.DONE)
    end
end

return GamePusherDropCoinData