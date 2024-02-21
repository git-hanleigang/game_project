local CashBonusIcon = class("CashBonusIcon", util_require("base.BaseView"))

function CashBonusIcon:initUI(urlType)
    -- setDefaultTextureType("RGBA8888",nil)

    self:createCsbNode("NewCashBonus/CashBonusNew/"..urlType..".csb")
    if globalData.deluexeClubData:getDeluexeClubStatus() ~= true then
        self:findChild("deluxe_extra"):setVisible(false)
    else
        self:findChild("deluxe_extra"):setVisible(true)
        self:findChild("labExra"):setString(globalData.constantData.CLUB_BENEFIT_BONUS_EXTRA_REWARD.."%")
    end
    -- setDefaultTextureType("RGBA4444",nil)

end
function CashBonusIcon:playAnim(active)
    if self.m_active and  self.m_active == active then
        return
    end
    self.m_active = active
    if active then
        self:runCsbAction("breath",true)
    else
        self:runCsbAction("idle",true)
    end
end


return CashBonusIcon