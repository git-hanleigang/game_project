---
--xcyy
--2018年5月23日
--FortuneCatsCollectItem.lua

local FortuneCatsCollectItem = class("FortuneCatsCollectItem",util_require("base.BaseView"))


function FortuneCatsCollectItem:initUI(_num)
    self:createCsbNode("FortuneCats_collect_Item.csb")
    if _num then

        local node = self:findChild("BitmapFontLabel_1")
        node:setString(util_formatCoins(_num, 3))
        if _num >= 10 then
            node:setScale(0.7)
        end
    end
end

function FortuneCatsCollectItem:onEnter()

end


function FortuneCatsCollectItem:onExit()

end

return FortuneCatsCollectItem