--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{author}
    time:2022-08-01 15:23:36
]]
local NewCoinPusherFruitData = class("NewCoinPusherFruitData", util_require("activities.Activity_NewCoinPusher.model.data.NewCoinPusherBaseActionData"))

function NewCoinPusherFruitData:ctor()
    NewCoinPusherFruitData.super.ctor(self)
end

--重写ActionData 拆分组装ActionData 初始化时候赋值
function NewCoinPusherFruitData:setActionData(data)
    self._RunningData.ActionData = data
    local effectData = {}
    local addCount = data.value
    if data.value == 0 then
        addCount = 1
    end
    if effectData[data.type] == nil then
        effectData[data.type] = addCount
    else
        effectData[data.type] = effectData[data.type] + addCount
    end
    self:setSlotActionState(data.type, self._Config.PlayState.IDLE)
    self:setSlotActionState(self._Config.SlotEffectRefer.SLOT, self._Config.PlayState.IDLE)
    self._RunningData.ActionData.effectData = effectData
    self._RunningData.ActionData.isPourCoins = false
end

function NewCoinPusherFruitData:getFruitSlotsDatas()
    local data = self:getActionData()
    return data.fruitMachineCoins
end

function NewCoinPusherFruitData:getFruitSlotsCount()
    return table.nums(self:getFruitSlotsDatas())
end

function NewCoinPusherFruitData:getFruitSlotsEffectDatas()
    local data = self:getActionData()
    return data.effectData
end

--return line Type
function NewCoinPusherFruitData:getType()
    local data = self:getActionData()
    return data.type
end

function NewCoinPusherFruitData:getIndex()
    local data = self:getActionData()
    return tonumber(data.index)
end

function NewCoinPusherFruitData:getTime()
    local data = self:getActionData()
    return tonumber(data.time)
end

function NewCoinPusherFruitData:getValue()
    local data = self:getActionData()
    return tonumber(data.value)
end

function NewCoinPusherFruitData:setIsPourCoins(bool)
    local data = self:getActionData()
    data.isPourCoins = bool
end

function NewCoinPusherFruitData:getIsPourCoins()
    local data = self:getActionData()
    return data.isPourCoins
end

function NewCoinPusherFruitData:slotRunningEnd()
    self:setSlotActionState(self._Config.SlotEffectRefer.SLOT, self._Config.PlayState.DONE)
end

function NewCoinPusherFruitData:checkSlotIsEnd()
    local state = self:getSlotActionState(self._Config.SlotEffectRefer.SLOT)
    return state == self._Config.PlayState.DONE
end

function NewCoinPusherFruitData:getEffectDataByType(type)
    local dataEffect = self:getFruitSlotsEffectDatas()
    return dataEffect[type]
end

--获取当前play 的effect 返回false 则全部都播放完毕
function NewCoinPusherFruitData:getSlotPlayEffectData()
    local jpType = self:getSlotActionState(self._Config.SlotEffectRefer.JACKPOT)
    local sCtype = self:getSlotActionState(self._Config.SlotEffectRefer.STAGE_COIN)
    local hType = self:getSlotActionState(self._Config.SlotEffectRefer.HAMMER)
    local carType = self:getSlotActionState(self._Config.SlotEffectRefer.CAR)
    local bCType = self:getSlotActionState(self._Config.SlotEffectRefer.BIGCOIN)

    if jpType ~= self._Config.PlayState.DONE and jpType ~= nil then
        return self._Config.SlotEffectRefer.JACKPOT, self:getEffectDataByType(self._Config.SlotEffectRefer.JACKPOT)
    end

    if sCtype ~= self._Config.PlayState.DONE and sCtype ~= nil then
        return self._Config.SlotEffectRefer.STAGE_COIN, self:getEffectDataByType(self._Config.SlotEffectRefer.STAGE_COIN)
    end

    if hType ~= self._Config.PlayState.DONE and hType ~= nil then
        return self._Config.SlotEffectRefer.HAMMER, self:getEffectDataByType(self._Config.SlotEffectRefer.HAMMER)
    end

    if carType ~= self._Config.PlayState.DONE and carType ~= nil then
        return self._Config.SlotEffectRefer.CAR, self:getEffectDataByType(self._Config.SlotEffectRefer.CAR)
    end

    if bCType ~= self._Config.PlayState.DONE and bCType ~= nil then
        return self._Config.SlotEffectRefer.BIGCOIN, self:getEffectDataByType(self._Config.SlotEffectRefer.BIGCOIN)
    end

    return false
end

function NewCoinPusherFruitData:setSlotActionState(type, state)
    local extraActionStates = self:getExtraActionState()
    extraActionStates[type] = state
end

function NewCoinPusherFruitData:getSlotActionState(type)
    local extraActionStates = self:getExtraActionState()
    return extraActionStates[type]
end

function NewCoinPusherFruitData:checkSlotActionEnd(type)
    local extraActionStates = self:getExtraActionState()
    return extraActionStates[type] == self._Config.PlayState.DONE
end

function NewCoinPusherFruitData:reduceEffectDataCount(effectType)
    local effectData = self:getFruitSlotsEffectDatas()
    effectData[effectType] = effectData[effectType] - 1
    if effectData[effectType] == 0 then
        self:setSlotActionState(effectType, self._Config.PlayState.DONE)
    end
end

return NewCoinPusherFruitData
