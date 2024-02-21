--
--版权所有:{company}
-- Author:{author}
-- Date: 2018-12-22 14:38:44
--用于DwarfFairyConfig.csv 中自定义数据的解析
local LevelConfigData = require("data.slotsdata.LevelConfigData")
local LevelClassicRapid2ClassicConfig = class("LevelClassicRapid2ClassicConfig", LevelConfigData)
LevelClassicRapid2ClassicConfig.SYMBOL_CLASSIC_SCORE_WILD = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 2
LevelClassicRapid2ClassicConfig.SYMBOL_WILD_x1 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 9
LevelClassicRapid2ClassicConfig.SYMBOL_WILD_x2 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 10
LevelClassicRapid2ClassicConfig.SYMBOL_WILD_x3 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 11
LevelClassicRapid2ClassicConfig.SYMBOL_WILD_x5 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 12

function LevelClassicRapid2ClassicConfig:ctor()

      self.reelAllList = {{self.SYMBOL_WILD_x1},{self.SYMBOL_WILD_x2},{self.SYMBOL_WILD_x3},{self.SYMBOL_WILD_x5},{self.SYMBOL_WILD_x2,self.SYMBOL_WILD_x3,self.SYMBOL_WILD_x5}}
      LevelConfigData.ctor(self)

end

function LevelClassicRapid2ClassicConfig:getNormalReelDatasByColumnIndex(columnIndex,index)
	local colKey = "reel_cloumn"..columnIndex
      if not self.reelAllList then
            self.reelAllList = {{self.SYMBOL_WILD_x1},{self.SYMBOL_WILD_x2},{self.SYMBOL_WILD_x3},{self.SYMBOL_WILD_x5},{self.SYMBOL_WILD_x2,self.SYMBOL_WILD_x3,self.SYMBOL_WILD_x5}}
      end
      local  replaceList = self.reelAllList[index]
	for i=1,#self[colKey] do
		local symbolType =  self[colKey][i]
            if symbolType ==  self.SYMBOL_CLASSIC_SCORE_WILD or symbolType == self.SYMBOL_WILD_x1 or symbolType == self.SYMBOL_WILD_x2 or symbolType == self.SYMBOL_WILD_x3 or symbolType == self.SYMBOL_WILD_x5 then
                  if index then
                        self[colKey][i] = replaceList[math.random( 1, #replaceList)]
                  end
		end
	end
	return self[colKey]
  end

return  LevelClassicRapid2ClassicConfig