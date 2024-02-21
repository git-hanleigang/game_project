local LevelCalacasParadeCSVData = class("LevelCalacasParadeCSVData", require("data.slotsdata.LevelConfigData"))

LevelCalacasParadeCSVData.m_carRewardList = {}

function LevelCalacasParadeCSVData:parseSelfConfigData(colKey, colValue)
    -- bonus1乘倍
    if colKey == "Bonus1Multi" then
        self.m_bonusMulti = self:CalacasParadeParsePro(colValue)
    --花车随机
    elseif colKey == "CarMulti_1" then
        self.m_carRewardList[1] = self:CalacasParadeParsePro(colValue)
    elseif colKey == "CarMulti_2" then
        self.m_carRewardList[2] = self:CalacasParadeParsePro(colValue)
    elseif colKey == "CarMulti_3" then
        self.m_carRewardList[3] = self:CalacasParadeParsePro(colValue)
    elseif colKey == "CarMulti_4" then
        self.m_carRewardList[4] = self:CalacasParadeParsePro(colValue)
    --烟花随机
    elseif colKey == "FireworksMulti" then
        self.m_fireworksMulti = self:CalacasParadeParsePro(colValue)
    end
end

--解析附带字符串的权重
function LevelCalacasParadeCSVData:CalacasParadeParsePro(_value)
    local data = {{}, 0}
    local verStrs = util_string_split(_value,";")
    for i,_proValue in ipairs(verStrs) do
        local vecPro = util_string_split(_proValue,"-")
        vecPro[2] = tonumber(vecPro[2])
        table.insert(data[1], vecPro)
        data[2] = data[2] + vecPro[2]
    end
    return data
end

-- bonus乘倍
function LevelCalacasParadeCSVData:getBonus1SymbolRandomMulti()
    local value = self:getValueByPros(self.m_bonusMulti[1], self.m_bonusMulti[2])
    return tonumber(value[1])
end

-- 花车随机奖励
function LevelCalacasParadeCSVData:getBonus2RandomReward(_index)
    local pool  = self.m_carRewardList[_index]
    local value = self:getValueByPros(pool[1], pool[2])
    return value[1]
end

-- 烟花随机
function LevelCalacasParadeCSVData:getFireworksRandomMulti()
    local value = self:getValueByPros(self.m_fireworksMulti[1], self.m_fireworksMulti[2])
    return tonumber(value[1])
end

return LevelCalacasParadeCSVData