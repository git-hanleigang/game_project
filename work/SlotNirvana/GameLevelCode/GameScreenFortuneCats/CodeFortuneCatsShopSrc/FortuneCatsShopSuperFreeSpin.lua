--[[
    des:商店中特殊玩法触发的超级freespin的弹框
    author:{author}
    time:2019-08-13 18:01:18
]]
local FortuneCatsShopSuperFreeSpin = class("FortuneCatsShopSuperFreeSpin", util_require("base.BaseView"))

function FortuneCatsShopSuperFreeSpin:initUI(pageIndex, callFunc)
    

    local resourceFilename = "SuperFreeSpin/SuperFreeSpin.csb"
    self:createCsbNode(resourceFilename)
    util_setCascadeOpacityEnabledRescursion(self.m_csbNode, true)

    self:runCsbAction("start", false, function()
        self:runCsbAction("idle", true)
    end)

    self.m_pageIndex = pageIndex
    self.m_callFunc = callFunc

    self:updateUI()
end

function FortuneCatsShopSuperFreeSpin:onEnter()
    gLobalSoundManager:playSound("FortuneCatsSounds/sound_FortuneCats_shop_super_freespin.mp3")
end

function FortuneCatsShopSuperFreeSpin:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()
    if name == "backBtn" then
        self:closeUI()
        if self.m_callFunc then
            self.m_callFunc()
        end
    end
end

function FortuneCatsShopSuperFreeSpin:updateUI()
    for i=1,5 do
        self:findChild("up"..i):setVisible(self.m_pageIndex == i)
        self:findChild("down"..i):setVisible(self.m_pageIndex == i) 
    end
end

function FortuneCatsShopSuperFreeSpin:closeUI()
    if self.isClose then
        return 
    end
    self.isClose = true

    self:runCsbAction("over", false, function ()
        self:removeFromParent()
    end)
end

return FortuneCatsShopSuperFreeSpin