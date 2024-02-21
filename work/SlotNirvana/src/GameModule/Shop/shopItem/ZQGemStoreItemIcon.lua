local ZQCoinStoreItemIcon = util_require("GameModule.Shop.shopItem.ZQCoinStoreItemIcon")
local ZQCoinStoreItemIcon = class("ZQCoinStoreItemIcon", ZQCoinStoreItemIcon)

function ZQCoinStoreItemIcon:getCsbName()
    return "Shop_Res/GemStoreIcon.csb"
end

return ZQCoinStoreItemIcon