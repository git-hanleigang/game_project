local NewCoinPusherSlotData = class("NewCoinPusherSlotData", util_require("activities.Activity_NewCoinPusher.model.data.NewCoinPusherBaseActionData"))

function NewCoinPusherSlotData:ctor()
    NewCoinPusherSlotData.super.ctor(self)
end

--重写ActionData 拆分组装ActionData 初始化时候赋值
function NewCoinPusherSlotData:setActionData(data)
    self._RunningData.ActionData = data

    local slotData = data.slots
    data.IndexSlot = 1

    local effectData = {}

    --重新整理一遍数据 符合老虎机动画设计
    for k, v in pairs(slotData) do
        -- "EMPTY" "FREESPIN" 暂时不播放动画
        if v.type ~= "EMPTY" and v.type ~= "FREESPIN" then
            local addCount = v.values
            if v.values == 0 then
                addCount = 1
            end
            if effectData[v.type] == nil then
                effectData[v.type] = addCount
            else
                effectData[v.type] = effectData[v.type] + addCount
            end
            self:setSlotActionState(v.type, self._Config.PlayState.IDLE)
        end
    end
    self:setSlotActionState(self._Config.SlotEffectRefer.SLOT, self._Config.PlayState.IDLE)
    self._RunningData.ActionData.effectData = effectData
end

function NewCoinPusherSlotData:getSlotsDatas()
    local data = self:getActionData()
    return data.slots
end

function NewCoinPusherSlotData:getSlotsEffectDatas()
    local data = self:getActionData()
    return data.effectData
end

function NewCoinPusherSlotData:getSlotsEffectCount(type)
    local effetDatas = self:getSlotsEffectDatas()
    return effetDatas[type]
end

function NewCoinPusherSlotData:getSlotsIndex()
    local data = self:getActionData()
    return data.IndexSlot
end

function NewCoinPusherSlotData:setSlotsIndex(index)
    local data = self:getActionData()
    data.IndexSlot = index
end

function NewCoinPusherSlotData:getSlotsCount()
    return table.nums(self:getSlotsDatas())
end

--获取当前运行的slotData
function NewCoinPusherSlotData:getPlaySlotsData()
    local slotData = self:getSlotsDatas()
    return slotData[self:getSlotsIndex()]
end

function NewCoinPusherSlotData:getPlaySlotsDataReels()
    local data = self:getPlaySlotsData()
    return data.reel
end

--return line Type
function NewCoinPusherSlotData:getLineType()
    local data = self:getPlaySlotsData()
    return data.type
end

function NewCoinPusherSlotData:getLineTypeIsFs()
    local data = self:getPlaySlotsData()
    return data.type == "FREESPIN"
end

--获取当前运行的slotData freespinTimes
function NewCoinPusherSlotData:getPlaySlotsDataFsTimes(index)
    local slotDatas = self:getSlotsDatas()
    local data = slotDatas[index]
    return data.leftTimes
end

--获取上次slot

function NewCoinPusherSlotData:getInitFsTimes()
    local index = self:getSlotsIndex()
    if index == 1 then
        return 1
    end

    return self:getPlaySlotsDataFsTimes(index - 1)
end

--获取最后一次slot盘面用于存档
function NewCoinPusherSlotData:getSlotsEndData()
    local slotData = self:getSlotsDatas()
    return slotData[self:getSlotsCount()]
end

--上次slot数据用于初始化读档盘面
function NewCoinPusherSlotData:getSlotsLastData()
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

function NewCoinPusherSlotData:slotRunningEnd()
    local data = self:getActionData()
    local index = self:getSlotsIndex()
    index = index + 1
    self:setSlotsIndex(index)
    if index > self:getSlotsCount() then
        self:setSlotActionState(self._Config.SlotEffectRefer.SLOT, self._Config.PlayState.DONE)
    end
end

function NewCoinPusherSlotData:checkSlotIsEnd()
    local state = self:getSlotActionState(self._Config.SlotEffectRefer.SLOT)
    return state == self._Config.PlayState.DONE
end

function NewCoinPusherSlotData:getEffectDatas()
    local data = self:getActionData()
    return data.effectData
end

function NewCoinPusherSlotData:getEffectDataByType(type)
    local dataEffect = self:getEffectDatas()
    return dataEffect[type]
end

--获取当前play 的effect 返回false 则全部都播放完毕
function NewCoinPusherSlotData:getSlotPlayEffectData()
    local jpType = self:getSlotActionState(self._Config.SlotEffectRefer.JACKPOT)
    local bCtype = self:getSlotActionState(self._Config.SlotEffectRefer.BIGCOIN)
    local hType = self:getSlotActionState(self._Config.SlotEffectRefer.HAMMER)

    if jpType ~= self._Config.PlayState.DONE and jpType ~= nil then
        return self._Config.SlotEffectRefer.JACKPOT, self:getEffectDataByType(self._Config.SlotEffectRefer.JACKPOT)
    end

    if bCtype ~= self._Config.PlayState.DONE and bCtype ~= nil then
        return self._Config.SlotEffectRefer.BIGCOIN, self:getEffectDataByType(self._Config.SlotEffectRefer.BIGCOIN)
    end

    if hType ~= self._Config.PlayState.DONE and hType ~= nil then
        return self._Config.SlotEffectRefer.HAMMER, self:getEffectDataByType(self._Config.SlotEffectRefer.HAMMER)
    end

    return false
end

function NewCoinPusherSlotData:setSlotActionState(type, state)
    local extraActionStates = self:getExtraActionState()
    extraActionStates[type] = state
end

function NewCoinPusherSlotData:getSlotActionState(type)
    local extraActionStates = self:getExtraActionState()
    return extraActionStates[type]
end

function NewCoinPusherSlotData:checkSlotActionEnd(type)
    local extraActionStates = self:getExtraActionState()
    return extraActionStates[type] == self._Config.PlayState.DONE
end

function NewCoinPusherSlotData:reduceEffectDataCount(effectType)
    local effectData = self:getSlotsEffectDatas()
    effectData[effectType] = effectData[effectType] - 1
    if effectData[effectType] == 0 then
        self:setSlotActionState(effectType, self._Config.PlayState.DONE)
    end
end

return NewCoinPusherSlotData
