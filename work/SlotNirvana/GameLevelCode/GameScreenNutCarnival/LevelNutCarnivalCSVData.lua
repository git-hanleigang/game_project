local LevelNutCarnivalCSVData = class("LevelNutCarnivalCSVData", require("data.slotsdata.LevelConfigData"))


function LevelNutCarnivalCSVData:parseSelfConfigData(colKey, colValue)
    -- bonus假滚的随机乘倍
    if colKey == "BonusMulti" then
        local pro,weight = self:parsePro(colValue)
        self.m_bonusMulti = {pro, weight}
    end
end

function LevelNutCarnivalCSVData:getReSpinSymbolRandomMulti()
    local value = self:getValueByPros(self.m_bonusMulti[1], self.m_bonusMulti[2])
    return value[1]
end
return LevelNutCarnivalCSVData