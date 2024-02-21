--[[
      optional int32 chapter = 1;//当前章节
  optional int32 special = 2; //是否是特殊章节
  optional int32 needGems = 3; //支付需要宝石数
]]

local MythicGameConfig = require("GameModule.MythicGame.config.MythicGameConfig")
local MythicGameChapterData = class("MythicGameChapterData")

function MythicGameChapterData:parseData(data)
    self.p_index = data.chapter
    self.p_special = data.special
    self.p_needGems = data.needGems
end

function MythicGameChapterData:getIndex()
    return self.p_index
end

function MythicGameChapterData:getNeedGems()
    return self.p_needGems
end

function MythicGameChapterData:getSpecial()
    return self.p_special
end

function MythicGameChapterData:isSpecial()
    return self.p_special == MythicGameConfig.LevelType.special
end

return MythicGameChapterData
