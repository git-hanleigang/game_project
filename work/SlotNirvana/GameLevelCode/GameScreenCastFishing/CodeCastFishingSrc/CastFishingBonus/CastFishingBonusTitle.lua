local CastFishingBonusTitle = class("CastFishingBonusTitle",util_require("Levels.BaseLevelDialog"))
local CastFishingManager = require "CodeCastFishingSrc.CastFishingFish.CastFishingManager"

function CastFishingBonusTitle:initUI()
    self:createCsbNode("CastFishing_UStitle.csb")

    util_setCascadeOpacityEnabledRescursion(self, true)
end

return CastFishingBonusTitle