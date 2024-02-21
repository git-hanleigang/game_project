--
--版权所有:{company}
-- Author:{author}
-- Date: 2018-12-22 14:38:44
--用于DwarfFairyConfig.csv 中自定义数据的解析
local LevelConfigData = require("data.slotsdata.LevelConfigData")
local LevelFivePandeConfig = class("LevelFivePandeConfig", LevelConfigData)

LevelFivePandeConfig.SYMBOL_MYSTER_1 = 131
LevelFivePandeConfig.SYMBOL_MYSTER_2 = 132
LevelFivePandeConfig.m_MYSTER_RunSymbol_1 = 0
LevelFivePandeConfig.m_MYSTER_RunSymbol_2 = 0

function LevelFivePandeConfig:ctor()
    LevelConfigData.ctor(self)

    self.m_mysterList = {}
    for i = 1, 6 do
        self.m_mysterList[i] = -1
    end
end

---
-- 获取普通情况下滚动数据
-- @param columnIndex 列索引
function LevelFivePandeConfig:getNormalReelDatasByColumnIndex(columnIndex)
	local colKey = "reel_cloumn"..columnIndex

	local rundata = {}

	local mysterType = self.m_mysterList[columnIndex]
	if mysterType ~= -1 then
        for i = 1, #self[colKey] do
            local symbolType = mysterType
            table.insert(rundata, symbolType)
        end
    else
        for i=1,#self[colKey] do
			local symbolType =  self[colKey][i]
			if symbolType ==  self.SYMBOL_MYSTER_1 then
				symbolType = self.m_MYSTER_RunSymbol_1
			elseif symbolType ==  self.SYMBOL_MYSTER_2 then
				symbolType = self.m_MYSTER_RunSymbol_2
			end

			table.insert(rundata,symbolType)
		end
    end

	return rundata
  end

---
-- 获取freespin model 对应的reel 列数据
--
function LevelFivePandeConfig:getFsReelDatasByColumnIndex(fsModelID,columnIndex)
	local colKey = string.format("freespinModeId_%d_%d",fsModelID,columnIndex)
	local rundata = {}

	local mysterType = self.m_mysterList[columnIndex]
	if mysterType ~= -1 then
        for i = 1, #self[colKey] do
        	local symbolType = mysterType
            table.insert(rundata, symbolType)
        end
    else
        for i=1,#self[colKey] do
			local symbolType =  self[colKey][i]
			if symbolType ==  self.SYMBOL_MYSTER_1 then
				symbolType = self.m_MYSTER_RunSymbol_1
			elseif symbolType ==  self.SYMBOL_MYSTER_2 then
				symbolType = self.m_MYSTER_RunSymbol_2
			end

			table.insert(rundata,symbolType)
		end
    end

	return rundata
end

function LevelFivePandeConfig:setMysterSymbol( symbolType1,symbolType2)

		self.m_MYSTER_RunSymbol_1 = symbolType1
		self.m_MYSTER_RunSymbol_2 = symbolType2
	
end

function LevelFivePandeConfig:setMysterSymbolList(symbolTypeList)
    self.m_mysterList = symbolTypeList
end

return  LevelFivePandeConfig