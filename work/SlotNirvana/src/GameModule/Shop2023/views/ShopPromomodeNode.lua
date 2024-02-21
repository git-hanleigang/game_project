--[[
    
]]

local ShopPromomodeNode = class("ShopPromomodeNode", BaseView)

function ShopPromomodeNode:initDatas(_isPortrait)
    self.m_isPortrait = _isPortrait
end

function ShopPromomodeNode:getCsbName()
    if self.m_isPortrait then
        return SHOP_RES_PATH.PromomodeV
    end
    return SHOP_RES_PATH.PromomodeH
end

function ShopPromomodeNode:initUI()
    ShopPromomodeNode.super.initUI(self)

    if G_GetMgr(G_REF.Shop):getPromomodeOpen() then
        self:runCsbAction("idle_on", false)
    else
        self:runCsbAction("idle_off", false)
    end
end

function ShopPromomodeNode:clickFunc(_sender)
    if self.m_isTouch then
        return 
    end

    local name = _sender:getName()
    if name == "btn_switch" then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        self.m_isTouch = true
        if G_GetMgr(G_REF.Shop):getPromomodeOpen() then
            G_GetMgr(G_REF.Shop):setPromomodeOpen(false)
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SHOP_PROMO_SWITCH, "off")
            performWithDelay(self, function ()
                self.m_isTouch = false
            end, 1.5)
            self:runCsbAction("off", false)
        else
            G_GetMgr(G_REF.Shop):setPromomodeOpen(true)
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SHOP_PROMO_SWITCH, "on")
            performWithDelay(self, function ()
                self.m_isTouch = false
            end, 1.5)
            self:runCsbAction("on", false)
        end 
    end
end

return ShopPromomodeNode