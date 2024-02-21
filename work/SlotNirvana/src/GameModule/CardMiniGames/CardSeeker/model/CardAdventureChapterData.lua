--[[
      optional int32 chapter = 1;//当前章节
  optional int32 special = 2; //是否是特殊章节
  optional int32 needGems = 3; //支付需要宝石数
]]
local CardAdventureChapterData = class("CardAdventureChapterData")

function CardAdventureChapterData:parseData(data)
    self.p_index = data.chapter
    self.p_special = data.special
    self.p_needGems = data.needGems
end

function CardAdventureChapterData:getIndex()
    return self.p_index
end

function CardAdventureChapterData:getNeedGems()
    return self.p_needGems
end

function CardAdventureChapterData:getSpecial()
    return self.p_special
end

function CardAdventureChapterData:isSpecial()
    return self.p_special == CardSeekerCfg.LevelType.special
end

return CardAdventureChapterData
