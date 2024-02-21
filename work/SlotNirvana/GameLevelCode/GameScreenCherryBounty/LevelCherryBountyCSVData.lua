local LevelCherryBountyCSVData = class("LevelCherryBountyCSVData", require("data.slotsdata.LevelConfigData"))

function LevelCherryBountyCSVData:parseSelfConfigData(colKey, colValue)
    -- bonus1乘倍
    if colKey == "Bonus1Multi" then
        self.m_bonus1Multi = self:StringValParsePro(colValue)
    elseif colKey == "reSpinReelRandom" then
        self.m_reSpinReelRandom = self:StringValParsePro(colValue)
    end
end
--解析附带字符串的权重
function LevelCherryBountyCSVData:StringValParsePro(_value)
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
function LevelCherryBountyCSVData:getBonus1SymbolRandomMulti()
    local value = self:getValueByPros(self.m_bonus1Multi[1], self.m_bonus1Multi[2])
    return tonumber(value[1])
end

--reSpin信号类型
function LevelCherryBountyCSVData:getReSpinReelRandomSymbol()
    local value = self:getValueByPros(self.m_reSpinReelRandom[1], self.m_reSpinReelRandom[2])
    return tonumber(value[1])
end

return LevelCherryBountyCSVData