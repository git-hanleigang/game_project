--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{author}
    time:2021-02-08 20:42:52
]]

local LevelConfigData = require("data.slotsdata.LevelConfigData")
local LevelEasterConfig = class("LevelEasterConfig", LevelConfigData)

LevelEasterConfig.SYMBOL_SCORE_10 = 9
LevelEasterConfig.SYMBOL_SCATTER_GOLD = 97  -- 金色Scatter
LevelEasterConfig.SYMBOL_SCATTER_WILD = 98  -- Scatter变成的wild

function LevelEasterConfig:ctor()
      LevelConfigData.ctor(self)
      self.m_mysterList = {}
      for i = 1, 5 do
          self.m_mysterList[i] = -1
      end
end

---
-- 获取普通情况下滚动数据
-- @param columnIndex 列索引
function LevelEasterConfig:getNormalReelDatasByColumnIndex(columnIndex)
    local colKey = "reel_cloumn" .. columnIndex

    local rundata = {}

    local mysterType = self.m_mysterList[columnIndex]
    if mysterType ~= -1 then
        for i = 1, #self[colKey] do
            local symbolType = mysterType
            table.insert(rundata, symbolType)
        end
        return rundata
    else
        return self[colKey]
    end
end

function LevelEasterConfig:getFsReelDatasByColumnIndex(fsModelID,columnIndex)

	local colKey = string.format("freespinModeId_%d_%d",fsModelID,columnIndex)
  

    local rundata = {}

    local mysterType = self.m_mysterList[columnIndex]
    if mysterType ~= -1 then
        for i = 1, #self[colKey] do
            local symbolType = mysterType
            table.insert(rundata, symbolType)
        end
        return rundata
    else
        return self[colKey]
    end
end

function LevelEasterConfig:setMysterSymbol(symbolTypeList)
    self.m_mysterList = symbolTypeList
end
return LevelEasterConfig

