
local LevelConfigData = require("data.slotsdata.LevelConfigData")
local LevelZeusVsHadesConfig = class("LevelZeusVsHadesConfig", LevelConfigData)

LevelZeusVsHadesConfig.m_bnBasePro1 = nil
LevelZeusVsHadesConfig.m_bnBaseTotalWeight1 = nil
LevelZeusVsHadesConfig.m_replaceSignal = nil
function LevelZeusVsHadesConfig:parsePro( value )
    local verStrs = util_string_split(value,";")

    local proValues = {}
    local totalWeight = 0
    for i=1,#verStrs do
        local proValue = verStrs[i]
        local vecPro = util_string_split(proValue,"-" , true)

        proValues[#proValues + 1] = vecPro
        totalWeight = totalWeight + vecPro[2]
    end
    return proValues , totalWeight
end

function LevelZeusVsHadesConfig:parseSelfConfigData(colKey, colValue)
    if colKey == "bonus_multiple" then
        self.m_bnBasePro1 , self.m_bnBaseTotalWeight1 = self:parsePro(colValue)
    elseif colKey == "respin_multiple" then
        self.m_respinBasePro1 , self.m_respinBaseTotalWeight1 = self:parsePro(colValue)
    elseif colKey == "respin_plunderNum" then
        self.m_plunderNumPro1 , self.m_plunderNumTotalWeight1 = self:parsePro(colValue)
    end
end
--获得bonus倍数
function LevelZeusVsHadesConfig:getFixSymbolPro()
    local value = self:getValueByPros(self.m_bnBasePro1 , self.m_bnBaseTotalWeight1)
    return value[1]
end
--获得respin下的倍数图标倍数
function LevelZeusVsHadesConfig:getRespinMultiple()
    local value = self:getValueByPros(self.m_respinBasePro1 , self.m_respinBaseTotalWeight1)
    return value[1]
end
--获得respin下抢地盘图标数字
function LevelZeusVsHadesConfig:getRespinPlunder()
    local value = self:getValueByPros(self.m_plunderNumPro1 , self.m_plunderNumTotalWeight1)
    return value[1]
end
--[[
    @desc: 根据权重返回对应的值
]]
function LevelZeusVsHadesConfig:getValueByPros( proValues , totalWeight )
    local random = util_random(1,totalWeight)
    local preValue = 0
    local triggerValue = -1
    for i=1,#proValues do
        local value = proValues[i]
        if value[2] ~= 0 then
            if random > preValue and random <= preValue + value[2] then
                triggerValue = value
                break
            end
            preValue = preValue + value[2]
        end
    end
    return triggerValue
end
--设置假滚96号替换成的id
function LevelZeusVsHadesConfig:setReplaceSignal(peplaceType)
    self.m_replaceSignal = peplaceType
end

-- 获取普通情况下滚动数据
-- @param columnIndex 列索引
function LevelZeusVsHadesConfig:getNormalReelDatasByColumnIndex(columnIndex)
    local colKey = "reel_cloumn" .. columnIndex
    local rundata = {}
    for i = 1, #self[colKey] do
        local symbolType = self[colKey][i]
        if symbolType == 96 then
            symbolType = self.m_replaceSignal
        end
        if symbolType ~= nil then
            table.insert(rundata, symbolType)
        end
    end
    return rundata
end
return  LevelZeusVsHadesConfig