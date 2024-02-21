--
--版权所有:{company}
-- Author:{author}
-- Date: 2018-12-22 14:38:44
--用于DwarfFairyConfig.csv 中自定义数据的解析
local LevelConfigData = require("data.slotsdata.LevelConfigData")
local LevelMrCashMiniConfig = class("LevelMrCashMiniConfig", LevelConfigData)
LevelMrCashMiniConfig.m_dataMaxNum = 60
LevelMrCashMiniConfig.m_SymbolList = {101,102,103,104,105,106,107,108}
LevelMrCashMiniConfig.m_SymbolPro =  {10 ,10 ,10 ,20 ,20 ,20 ,20 ,50}
---
-- 获取普通情况下滚动数据
-- @param columnIndex 列索引
function LevelMrCashMiniConfig:getNormalReelDatasByColumnIndex(columnIndex)
    local colKey = "reel_cloumn"..columnIndex
    
    local reelDatas = {}
    
    for i=1,self.m_dataMaxNum do
        local index =  self:getProMysterIndex(self.m_SymbolPro)
    
        local RunSymbol = self.m_SymbolList[index]
        if RunSymbol then
            table.insert(reelDatas,RunSymbol) 
        end
        
    end


    return reelDatas
end

---
-- 获取freespin model 对应的reel 列数据
--
function LevelMrCashMiniConfig:getFsReelDatasByColumnIndex(fsModelID,columnIndex)

	local colKey = string.format("freespinModeId_%d_%d",fsModelID,columnIndex)

	local reelDatas = {}
    
    for i=1,self.m_dataMaxNum do
        local index =  self:getProMysterIndex(self.m_SymbolPro)
    
        local RunSymbol = self.m_SymbolList[index]
        if RunSymbol then
            table.insert(reelDatas,RunSymbol) 
        end
        
    end


    return reelDatas
end


function LevelMrCashMiniConfig:getProMysterIndex( array )

    local index = 1
    local Gear = 0
    local tableGear = {}
    for k,v in pairs(array) do
        Gear = Gear + v
        table.insert( tableGear, Gear )
    end

    local randomNum = math.random( 1,Gear )

    for kk,vv in pairs(tableGear) do
        if randomNum <= vv then
            return kk
        end

    end

    return index

end

return  LevelMrCashMiniConfig