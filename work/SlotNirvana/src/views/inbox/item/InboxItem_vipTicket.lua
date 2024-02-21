local InboxItem_vipTicket = class("InboxItem_vipTicket", util_require("views.inbox.item.InboxItem_ticket"))
local MAX_VIP_LEVEL = 7 --vip最大等级

function InboxItem_vipTicket:updateCustomUI()
    if not self.m_mailData or not self.m_mailData.ticketId then
        return
    end

    local config = globalData.itemsConfig:getCommonTicket(self.m_mailData.ticketId) or {}
    local icon = config.p_icon or ""
    local vipLevel = string.sub(icon, -1)
    if not tonumber(vipLevel) then
        vipLevel = globalData.userRunData.vipLevel
    end

    -- 当前VIP 图标
    vipLevel = tonumber(vipLevel)
    -- vip图片
    local imgPath = VipConfig.logo_middle .. vipLevel .. ".png"
    local spVip = self:findChild("sp_vip_item")
    util_changeTexture(spVip, imgPath)
    spVip:setScale(0.5)

    -- vipDesc
    local desc = {"BRONZE", "SILVER", "GOLD", "PLATINUM", "DIAMOND", "ROYAL DIAMOND", "BLACK DIAMOND"}
    local lbVipDesc = self:findChild("lb_vipDesc1")
    lbVipDesc:setString(desc[vipLevel])
    util_scaleCoinLabGameLayerFromBgWidth(lbVipDesc, 170)
end

function InboxItem_vipTicket:getCsbName()
    local csbName = "InBox/InboxItem_VIP_Coupon.csb"
    return csbName
end

function InboxItem_vipTicket:onEnter()
end

return InboxItem_vipTicket
