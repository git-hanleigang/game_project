
local LevelConfigData = require("data.slotsdata.LevelConfigData")
local LevelKoiBlissConfig = class("LevelKoiBlissConfig", LevelConfigData)

function LevelKoiBlissConfig:parseSelfConfigData(colKey, colValue)
    if colKey == "bonus1_pro" then
	    self.m_bnBasePro1 , self.m_bnBaseTotalWeight1 = self:parsePro(colValue)
    end
end
--获取假滚bonus1显示的倍数
function LevelKoiBlissConfig:getBonus1SymbolPro()
    local value = self:getValueByPros(self.m_bnBasePro1 , self.m_bnBaseTotalWeight1)
    return value[1]
end
--获取最大倍数
function LevelKoiBlissConfig:getBonus1MaxSymbolPro()
    for i = #self.m_bnBasePro1,1,-1 do
        if self:getMulJackpotType(self.m_bnBasePro1[i][1]) == nil then
            return self.m_bnBasePro1[i][1]
        end
    end
end
--通过倍数判断jackpot类型，不是jackpot返回nil
function LevelKoiBlissConfig:getMulJackpotType(mul)
    local jackPotMul = {
        Mini = 10,
        Minor = 30
    }
    for k,v in pairs(jackPotMul) do
        if v == mul then
            return k
        end
    end
    return nil
end
return  LevelKoiBlissConfig