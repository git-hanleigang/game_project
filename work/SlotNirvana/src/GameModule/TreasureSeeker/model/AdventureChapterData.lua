--[[
      optional int32 chapter = 1;//当前章节
  optional int32 special = 2; //是否是特殊章节
  optional int32 needGems = 3; //支付需要宝石数
]]
local AdventureChapterData = class("AdventureChapterData")

function AdventureChapterData:parseData(data)
    self.p_index = data.chapter
    self.p_special = data.special
    self.p_needGems = data.needGems
end

function AdventureChapterData:getIndex()
    return self.p_index
end

function AdventureChapterData:getNeedGems()
    return self.p_needGems
end

function AdventureChapterData:getSpecial()
    return self.p_special
end

function AdventureChapterData:isSpecial()
    return self.p_special == TreasureSeekerCfg.LevelType.special
end

return AdventureChapterData
