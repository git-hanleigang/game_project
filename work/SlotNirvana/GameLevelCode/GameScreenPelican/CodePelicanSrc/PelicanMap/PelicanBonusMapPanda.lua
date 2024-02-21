local PelicanBonusMapPanda = class("PelicanBonusMapPanda", util_require("base.BaseView"))
-- 构造函数
function PelicanBonusMapPanda:initUI(data)
    local resourceFilename = "Pelican_Map_chuan.csb"
    self:createCsbNode(resourceFilename)
    self:runCsbAction("idle", true)
end

return PelicanBonusMapPanda