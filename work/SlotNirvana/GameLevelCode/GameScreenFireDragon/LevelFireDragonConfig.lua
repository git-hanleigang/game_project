--
--版权所有:{company}
-- Author:{author}
-- Date: 2020-07-03 18:04:59
--

local LevelConfigData = require("data.slotsdata.LevelConfigData")
local LevelFireDragonConfig = class("LevelFireDragonConfig", LevelConfigData)

function LevelFireDragonConfig:ctor()
      LevelConfigData.ctor(self)
end



function LevelFireDragonConfig:parseSelfConfigData(colKey, colValue)
    
      if colKey == "Mestery_Hit_Score_4" then
            self.m_mesteryHitScore4 = util_string_split(colValue,";" , true)
      elseif colKey == "Mestery_Hit_Score_3" then
            self.m_mesteryHitScore3 = util_string_split(colValue,";" , true)
      elseif colKey == "Mestery_Hit_Score_2" then
            self.m_mesteryHitScore2 = util_string_split(colValue,";" , true)
      elseif colKey == "Mestery_Hit_Score_1" then
            self.m_mesteryHitScore1 = util_string_split(colValue,";" , true)
      end

end

--[[
    @desc: 获取攻击怪兽返回的分值
    time:2018-12-24 18:13:43
    --@symbolType:
	--@hitCount: 
    @return:
]]
function LevelFireDragonConfig:getHitScoreBySymbolType( symbolType, hitCount )
      local hitScores = nil
      if symbolType == 1 then
            hitScores = self.m_mesteryHitScore1
      elseif symbolType == 2 then
            hitScores = self.m_mesteryHitScore2
      elseif symbolType == 3 then
            hitScores = self.m_mesteryHitScore3
      elseif symbolType == 4 then
            hitScores = self.m_mesteryHitScore4
      end

      if hitScores == nil then
            return 0
      end

      if #hitScores < hitCount then
            return hitScores[#hitScores]
      end

      return hitScores[hitCount]

end


return  LevelFireDragonConfig