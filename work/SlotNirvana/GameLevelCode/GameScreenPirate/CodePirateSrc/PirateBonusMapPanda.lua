local PirateBonusMapPanda = class("PirateBonusMapPanda", util_require("base.BaseView"))
-- 构造函数
function PirateBonusMapPanda:initUI(data)
    local resourceFilename = "Bonus_Pirate_Map_zhishi.csb"
    self:createCsbNode(resourceFilename)
    self:runCsbAction("run", true)
end

function PirateBonusMapPanda:onEnter()

end

function PirateBonusMapPanda:onExit()

end


return PirateBonusMapPanda