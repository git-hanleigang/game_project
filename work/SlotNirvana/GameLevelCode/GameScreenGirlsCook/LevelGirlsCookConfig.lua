--
--版权所有:{company}
-- Author:{author}
-- Date: 2020-07-03 15:34:11
--

local LevelConfigData = require("data.slotsdata.LevelConfigData")
local LevelGirlsCookConfig = class("LevelGirlsCookConfig", LevelConfigData)

function LevelGirlsCookConfig:ctor()
      LevelConfigData.ctor(self)
end

function LevelGirlsCookConfig:parseSelfConfigData(colKey, colValue)
      if string.find( colKey, "init_reel" ) ~= nil then
            local verStrs = util_string_split(colValue,";",true)
            self[colKey] = verStrs
      end
end

--[[
      获取初始轮盘
]]
function LevelGirlsCookConfig:getInitReel()
      local initReelData = {}
      for iCol = 1,self.p_columnNum do
            initReelData[iCol] = self["init_reel"..iCol]
      end
      return initReelData
end

--[[
      根据列数获取初始轮盘数据
]]
function LevelGirlsCookConfig:getInitReelDatasByColumnIndex(colIndex)
      return self["init_reel"..colIndex]
end

--[[
      初始轮盘配置是否存在
]]
function LevelGirlsCookConfig:isHaveInitReel()
      return self["init_reel1"] and true or false
end

return  LevelGirlsCookConfig