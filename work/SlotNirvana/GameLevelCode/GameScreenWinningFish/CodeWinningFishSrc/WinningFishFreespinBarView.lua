

local WinningFishFreespinBarView = class("WinningFishFreespinBarView",util_require("Levels.FreeSpinBar"))

function WinningFishFreespinBarView:initUI()
    self:createCsbNode("Socre_WinningFish_FreeSpins.csb")
end

function WinningFishFreespinBarView:updateFreespinCount(leftCount,totalCount)
    self:findChild("m_lb_num"):setString(leftCount)
end

return WinningFishFreespinBarView