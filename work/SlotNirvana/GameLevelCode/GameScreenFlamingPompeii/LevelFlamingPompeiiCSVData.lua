local LevelFlamingPompeiiCSVData = class("LevelFlamingPompeiiCSVData", require("data.slotsdata.LevelConfigData"))



LevelFlamingPompeiiCSVData.m_buffReelData = {}

--[[
      @return: 返回中的倍数
--]]
function LevelFlamingPompeiiCSVData:getReSpinSymbolRandomMulti()
    local value = self:getValueByPros(self.m_bonusMulti[1], self.m_bonusMulti[2])
    return value[1]
end

function LevelFlamingPompeiiCSVData:parseSelfConfigData(colKey, colValue)
    -- 两个buff卷轴的假滚
    if colKey == "buffReel_1" then
        self.m_buffReelData[1] = self:parseSelfDefinePron(colValue)
    elseif colKey == "buffReel_2" then
        self.m_buffReelData[2] = self:parseSelfDefinePron(colValue)
    --普通buff卷轴-乘倍概率
    elseif colKey == "BUFFREEL_1_MULTI" then
        local pro,weight = self:parsePro(colValue)
        self.m_buffReel1_multi = {pro, weight}
    --普通buff卷轴-升行概率
    elseif colKey == "BUFFREEL_1_UPROW" then
        local pro,weight = self:parsePro(colValue)
        self.m_buffReel1_upRow = {pro, weight}
    --普通buff卷轴-增加bonus奖金概率
    elseif colKey == "BUFFREEL_1_ADDBONUSCOINS" then
        local pro,weight = self:parsePro(colValue)
        self.m_buffReel1_addBonusCoins = {pro, weight}
    --特殊buff卷轴-倍数或jackpot奖励概率
    elseif colKey == "BUFFREEL_2_WINCOINS" then
        --概率列表，总权重
        self.m_buffReel2_winCoins = {{}, 0}
        local verStrs = util_string_split(colValue,";")
        for i,_proValue in ipairs(verStrs) do
            local vecPro = util_string_split(_proValue,"-")
            vecPro[2] = tonumber(vecPro[2]) 
            table.insert(self.m_buffReel2_winCoins[1], vecPro)
            self.m_buffReel2_winCoins[2] = self.m_buffReel2_winCoins[2] + vecPro[2]
        end
    --特殊buff卷轴-倍数或jackpot奖励概率(没有grand的情况)
    elseif colKey == "BUFFREEL_2_WINCOINS_NOTGRAND" then
        self.m_buffReel2_winCoinsNotGrand = {{}, 0}
        local verStrs = util_string_split(colValue,";")
        for i,_proValue in ipairs(verStrs) do
            local vecPro = util_string_split(_proValue,"-")
            vecPro[2] = tonumber(vecPro[2]) 
            table.insert(self.m_buffReel2_winCoinsNotGrand[1], vecPro)
            self.m_buffReel2_winCoinsNotGrand[2] = self.m_buffReel2_winCoinsNotGrand[2] + vecPro[2]
        end
    -- bonus假滚的随机乘倍
    elseif colKey == "BonusMulti" then
        local pro,weight = self:parsePro(colValue)
        self.m_bonusMulti = {pro, weight}
    end
end

--特殊bonus触发reSpin假滚
function LevelFlamingPompeiiCSVData:getSpecialRespinCloumnByColumnIndex(columnIndex)
	local colKey = string.format("respinCloumn_special_%d", columnIndex)
	return self[colKey]
end


--buff棋盘假滚
function LevelFlamingPompeiiCSVData:getReSpinBuffReelData(_reelType)
    local reelData = self.m_buffReelData[_reelType]
    return reelData
end
--buff棋盘1-随机倍数
function LevelFlamingPompeiiCSVData:getBuffReel1MultiPro()
    local value = self:getValueByPros(self.m_buffReel1_multi[1], self.m_buffReel1_multi[2])
    return value[1]
end
--buff棋盘1-随机升行
function LevelFlamingPompeiiCSVData:getBuffReel1UpRowPro()
    local value = self:getValueByPros(self.m_buffReel1_upRow[1], self.m_buffReel1_upRow[2])
    return value[1]
end
--buff棋盘1-增加bonus奖金概率
function LevelFlamingPompeiiCSVData:getBuffReel1AddBonusCoins()
    local value = self:getValueByPros(self.m_buffReel1_addBonusCoins[1], self.m_buffReel1_addBonusCoins[2])
    return value[1]
end
--buff棋盘2-倍数或jackpot奖励概率
function LevelFlamingPompeiiCSVData:getBuffReel2WinCoins()
    local value = self:getValueByPros(self.m_buffReel2_winCoins[1], self.m_buffReel2_winCoins[2])
    return value[1]
end
--buff棋盘2-倍数或jackpot奖励概率(没有grand的情况)
function LevelFlamingPompeiiCSVData:getBuffReel2WinCoinsNotGrand()
    local value = self:getValueByPros(self.m_buffReel2_winCoinsNotGrand[1], self.m_buffReel2_winCoinsNotGrand[2])
    return value[1]
end

return LevelFlamingPompeiiCSVData