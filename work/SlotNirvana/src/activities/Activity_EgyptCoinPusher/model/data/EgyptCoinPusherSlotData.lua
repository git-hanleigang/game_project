local EgyptCoinPusherSlotData = class("EgyptCoinPusherSlotData", util_require("activities.Activity_EgyptCoinPusher.model.data.EgyptCoinPusherBaseActionData"))

function EgyptCoinPusherSlotData:ctor()
    EgyptCoinPusherSlotData.super.ctor(self)
end

--重写ActionData 拆分组装ActionData 初始化时候赋值
function EgyptCoinPusherSlotData:setActionData(data)
    self._RunningData.ActionData = data

    local slotData = data.coins
    data.IndexSlot = 1

    local effectData = {}

    --重新整理一遍数据 符合老虎机动画设计
    local slotEffctCount = 0
    for k, v in pairs(slotData) do
        local addCount = v
        if effectData[k] == nil then
            effectData[k] = addCount
        else
            effectData[k] = effectData[k] + addCount
        end
        if addCount > 0 then
            slotEffctCount = slotEffctCount + 1
            self:setSlotActionState(k, self._Config.PlayState.IDLE)
        end
    end
    if data.symbol == "SYMBOL_HUGE_COINS" then
        self:setSlotActionState(self._Config.SlotEffectRefer.LONGPUSHER, self._Config.PlayState.IDLE)
        effectData["LONGPUSHER"] = 1
        slotEffctCount = slotEffctCount + 1
    end

    self:setSlotActionState(self._Config.SlotEffectRefer.SLOT, self._Config.PlayState.IDLE)
    if slotEffctCount <= 0 then
        self:setSlotActionState(self._Config.SlotEffectRefer.SLOT, self._Config.PlayState.DONE)
        self:setActionState(self._Config.PlayState.DONE)
    end
    self._RunningData.ActionData.effectData = effectData
end

function EgyptCoinPusherSlotData:getSlotsDatas()
    local data = self:getActionData()
    return data.slots
end

function EgyptCoinPusherSlotData:getSlotsEffectDatas()
    local data = self:getActionData()
    return data.effectData
end

function EgyptCoinPusherSlotData:getSlotsEffectCount(type)
    local effetDatas = self:getSlotsEffectDatas()
    return effetDatas[type]
end

function EgyptCoinPusherSlotData:getSlotsIndex()
    local data = self:getActionData()
    return data.IndexSlot
end

function EgyptCoinPusherSlotData:setSlotsIndex(index)
    local data = self:getActionData()
    data.IndexSlot = index
end

function EgyptCoinPusherSlotData:getSlotsCount()
    return table.nums(self:getSlotsDatas())
end

--获取当前运行的slotData
function EgyptCoinPusherSlotData:getPlaySlotsData()
    local slotData = self:getSlotsDatas()
    return slotData[self:getSlotsIndex()]
end

function EgyptCoinPusherSlotData:getPlaySlotsDataReels()
    local data = self:getPlaySlotsData()
    return data.reel
end

--return line Type
function EgyptCoinPusherSlotData:getLineType()
    local data = self:getPlaySlotsData()
    return data.type
end

function EgyptCoinPusherSlotData:getLineTypeIsFs()
    local data = self:getPlaySlotsData()
    return data.type == "FREESPIN"
end

--获取当前运行的slotData freespinTimes
function EgyptCoinPusherSlotData:getPlaySlotsDataFsTimes(index)
    local slotDatas = self:getSlotsDatas()
    local data = slotDatas[index]
    return data.leftTimes
end

--获取上次slot

function EgyptCoinPusherSlotData:getInitFsTimes()
    local index = self:getSlotsIndex()
    if index == 1 then
        return 1
    end

    return self:getPlaySlotsDataFsTimes(index - 1)
end

--获取最后一次slot盘面用于存档
function EgyptCoinPusherSlotData:getSlotsEndData()
    local slotData = self:getSlotsDatas()
    return slotData[self:getSlotsCount()]
end

--上次slot数据用于初始化读档盘面
function EgyptCoinPusherSlotData:getSlotsLastData()
    local index = self:getSlotsIndex()
    if index <= 1 then
        return nil
    end
    local slotData = self:getSlotsDatas()
    if slotData[index - 1] then
        return slotData[index - 1].reel
    end
    return nil
end

function EgyptCoinPusherSlotData:slotRunningEnd()
    local data = self:getActionData()
    local index = self:getSlotsIndex()
    index = index + 1
    self:setSlotsIndex(index)
    if index > self:getSlotsCount() then
        self:setSlotActionState(self._Config.SlotEffectRefer.SLOT, self._Config.PlayState.DONE)
    end
end

function EgyptCoinPusherSlotData:checkSlotIsEnd()
    local state = self:getSlotActionState(self._Config.SlotEffectRefer.SLOT)
    return state == self._Config.PlayState.DONE
end

function EgyptCoinPusherSlotData:getEffectDatas()
    local data = self:getActionData()
    return data.effectData
end

function EgyptCoinPusherSlotData:getEffectDataByType(type)
    local dataEffect = self:getEffectDatas()
    return dataEffect[type]
end

--获取当前play 的effect 返回false 则全部都播放完毕
function EgyptCoinPusherSlotData:getSlotPlayEffectData()
    local jpType = self:getSlotActionState(self._Config.SlotEffectRefer.JACKPOT)
    local stType = self:getSlotActionState(self._Config.SlotEffectRefer.STAGE_COIN)
    local spType = self:getSlotActionState(self._Config.SlotEffectRefer.SMALLCOIN)
    local bCtype = self:getSlotActionState(self._Config.SlotEffectRefer.BIGCOIN)
    local hType = self:getSlotActionState(self._Config.SlotEffectRefer.HAMMER)
    local lType = self:getSlotActionState(self._Config.SlotEffectRefer.LONGPUSHER)

    if jpType ~= self._Config.PlayState.DONE and jpType ~= nil then
        return self._Config.SlotEffectRefer.JACKPOT, self:getEffectDataByType(self._Config.SlotEffectRefer.JACKPOT)
    end

    if stType ~= self._Config.PlayState.DONE and stType ~= nil then
        return self._Config.SlotEffectRefer.STAGE_COIN, self:getEffectDataByType(self._Config.SlotEffectRefer.STAGE_COIN)
    end

    if spType ~= self._Config.PlayState.DONE and spType ~= nil then
        return self._Config.SlotEffectRefer.SMALLCOIN, self:getEffectDataByType(self._Config.SlotEffectRefer.SMALLCOIN)
    end

    if bCtype ~= self._Config.PlayState.DONE and bCtype ~= nil then
        return self._Config.SlotEffectRefer.BIGCOIN, self:getEffectDataByType(self._Config.SlotEffectRefer.BIGCOIN)
    end

    if hType ~= self._Config.PlayState.DONE and hType ~= nil then
        return self._Config.SlotEffectRefer.HAMMER, self:getEffectDataByType(self._Config.SlotEffectRefer.HAMMER)
    end

    if lType ~= self._Config.PlayState.DONE and lType ~= nil then
        return self._Config.SlotEffectRefer.LONGPUSHER, self:getEffectDataByType(self._Config.SlotEffectRefer.LONGPUSHER)
    end
    
    return false
end

function EgyptCoinPusherSlotData:setSlotActionState(type, state)
    local extraActionStates = self:getExtraActionState()
    extraActionStates[type] = state
end

function EgyptCoinPusherSlotData:getSlotActionState(type)
    local extraActionStates = self:getExtraActionState()
    return extraActionStates[type]
end

function EgyptCoinPusherSlotData:checkSlotActionEnd(type)
    local extraActionStates = self:getExtraActionState()
    return extraActionStates[type] == self._Config.PlayState.DONE
end

function EgyptCoinPusherSlotData:reduceEffectDataCount(effectType)
    local effectData = self:getSlotsEffectDatas()
    if not effectType then
        release_print("===EgyptCoinPusherSlotData:reduceEffectDataCount---effectType---nil")
    end
    if not effectData[effectType] then
        release_print("===EgyptCoinPusherSlotData:reduceEffectDataCount---effectData---nil---" .. effectType)
    end
    effectData[effectType] = effectData[effectType] - 1
    if effectData[effectType] == 0 then
        self:setSlotActionState(effectType, self._Config.PlayState.DONE)
        self:checkSlotLogicEnd()
    end
end

function EgyptCoinPusherSlotData:getType()
    local data = self:getActionData()
    return data.type
end

function  EgyptCoinPusherSlotData:checkSlotLogicEnd()
    local jpType = self:getSlotActionState(self._Config.SlotEffectRefer.JACKPOT)
    local spType = self:getSlotActionState(self._Config.SlotEffectRefer.SMALLCOIN)
    local bCtype = self:getSlotActionState(self._Config.SlotEffectRefer.BIGCOIN)
    local hType = self:getSlotActionState(self._Config.SlotEffectRefer.HAMMER)
    local lType = self:getSlotActionState(self._Config.SlotEffectRefer.LONGPUSHER)
    local result = 0
    if jpType ~= self._Config.PlayState.DONE and jpType ~= nil then
        result = result + 1
    end

    if spType ~= self._Config.PlayState.DONE and spType ~= nil then
        result = result + 1
    end

    if bCtype ~= self._Config.PlayState.DONE and bCtype ~= nil then
        result = result + 1
    end

    if hType ~= self._Config.PlayState.DONE and hType ~= nil then
        result = result + 1
    end

    if lType ~= self._Config.PlayState.DONE and lType ~= nil then
        result = result + 1
    end
    if result == 0 then
        self:setSlotActionState(self._Config.SlotEffectRefer.SLOT, self._Config.PlayState.DONE)
    end
end

return EgyptCoinPusherSlotData
