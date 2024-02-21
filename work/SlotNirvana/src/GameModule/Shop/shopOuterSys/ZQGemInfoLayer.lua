--[[
    钻石商城info弹板
]]
local ZQGemInfoLayer = class("ZQGemInfoLayer", BaseLayer)

function ZQGemInfoLayer:ctor()
    ZQGemInfoLayer.super.ctor(self)
    self:setKeyBackEnabled(true)
    self:setLandscapeCsbName("Shop_Res/GemStoreInfoLayer.csb")
end

function ZQGemInfoLayer:clickFunc(sender)
    local senderName = sender:getName()
    if senderName == "btn_close" then
        self:closeUI()
    end
end

return ZQGemInfoLayer
