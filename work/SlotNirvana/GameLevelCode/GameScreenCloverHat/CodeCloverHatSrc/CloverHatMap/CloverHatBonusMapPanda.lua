local CloverHatBonusMapPanda = class("CloverHatBonusMapPanda", util_require("base.BaseView"))
-- 构造函数
function CloverHatBonusMapPanda:initUI(data)
    local resourceFilename = "CloverHat_Map_zhizhen.csb"
    self:createCsbNode(resourceFilename)
    self:runCsbAction("idleframe", true)
end

function CloverHatBonusMapPanda:onEnter()

end

function CloverHatBonusMapPanda:onExit()

end


return CloverHatBonusMapPanda