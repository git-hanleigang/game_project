local CashBonusMutiBarItem = class("CashBonusMutiBarItem", util_require("base.BaseView"))

function CashBonusMutiBarItem:initUI(rate)
    -- setDefaultTextureType("RGBA8888",nil)
    self:createCsbNode("NewCashBonus/CashBonusNew/CashBonus_multItem.csb")
    local panel = self:findChild("panel")
    local size = panel:getContentSize()
    panel:setContentSize(size.width*rate/100,size.height)
    self:runCsbAction("idle",true)
    -- setDefaultTextureType("RGBA4444",nil)

end

return CashBonusMutiBarItem