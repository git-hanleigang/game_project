--[[
]]
GD.VipConfig = {}
VipConfig.name_small = "VipNew/other/name_small/VipName_"
VipConfig.name_middle = "VipNew/other/name_middle/VipName_"
VipConfig.name_big = "VipNew/other/name_big/VipName_"
VipConfig.logo_small = "VipNew/other/logo_small/VipIcon_"
VipConfig.logo_middle = "VipNew/other/logo_middle/VipIcon_"
VipConfig.logo_big = "VipNew/other/logo_big/VipIcon_"
VipConfig.logo_shop = "VipNew/other/shop_vip/VipIcon_"
VipConfig.name_shop = "VipNew/other/shop_vip/VipName_"

VipConfig.vip_bg = "VipNew/other/vip_leveldi.png"

VipConfig.MAX_LEVEL = 8
VipConfig.MULTI = 6

VipConfig.PageNum = 2
VipConfig.CellNum = 5
VipConfig.PAGE_CONFIG = {
    {
        {pageName = "Store Coins"},
        {pageName = "VIP Point", pageFlag = "boosted"},
        {pageName = "Store Gift"},
        {pageName = "Gold Vault", pageFlag = "boosted"},
        {pageName = "Silver Vault", pageFlag = "boosted"}
    },
    {
        {pageName = "Cash Wheel", pageFlag = "boosted"},
        {pageName = "Fanpage Gift"},
        {pageName = "Notification Gift"},
        {pageName = "Vip Coupon", pageFlag = "new"},
        {pageName = "Weekly Gifts", pageFlag = "new"}
    }
}

VipConfig.LISTCELL_TEXT = {
    {
        "x%s",
        "x%s",
        "x%s",
        "%s%%",
        "%s%%"
    },
    {
        "%s%%",
        "x%s",
        "x%s",
        "%s%%",
        "$%s"
    }
}

VipConfig.LISTVIEW_CONFIG = {
    {cType = "vertical", name = "BRONZE"},
    {cType = "vertical", name = "SILVER"},
    {cType = "vertical", name = "GOLD"},
    {cType = "vertical", name = "PLATINUM"},
    {cType = "vertical", name = "DIAMOND"},
    {cType = "vertical", name = "ROYAL"},
    {cType = "black", name = "BLACK"},
    {cType = "blackPlus", name = "BLACK PLUS"}
}

ViewEventType.VIP_CELL_BUBBLE = "VIP_CELL_BUBBLE"
ViewEventType.VIP_SWITCH_PAGE = "VIP_SWITCH_PAGE"
ViewEventType.VIP_REWARDUI_CLOSE = "VIP_REWARDUI_CLOSE"
