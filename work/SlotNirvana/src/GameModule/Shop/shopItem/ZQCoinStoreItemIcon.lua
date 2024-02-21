local BaseView = util_require("base.BaseView")
local ZQCoinStoreItemIcon = class("ZQCoinStoreItemIcon", BaseView)

function ZQCoinStoreItemIcon:getCsbName()
    return "Shop_Res/CoinStoreIcon.csb"
end

function ZQCoinStoreItemIcon:initUI(index)
    self:createCsbNode(self:getCsbName())

    for i=1,6 do
        local spIcon = self:findChild("sp_Icon"..i)
        spIcon:setVisible(index == i)
    end
end


return ZQCoinStoreItemIcon