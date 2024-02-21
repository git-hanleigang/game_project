--[[--
    章节选择界面中wild章节后边的飞动卡牌特效
]]
local CardAlbumCellWildEffect = class("CardAlbumCellWildEffect", util_require("base.BaseView"))
function CardAlbumCellWildEffect:initUI()
    self:createCsbNode(CardResConfig.CardAlbumCell2020WildEffectRes)
    self:playIdle()
end

function CardAlbumCellWildEffect:playIdle()
    self:runCsbAction("idle", true)
end

return CardAlbumCellWildEffect