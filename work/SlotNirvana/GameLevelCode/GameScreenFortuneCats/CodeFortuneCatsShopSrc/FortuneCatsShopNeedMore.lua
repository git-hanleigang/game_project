

local FortuneCatsShopNeedMore = class("FortuneCatsShopNeedMore", util_require("base.BaseView"))

function FortuneCatsShopNeedMore:initUI()

    local resourceFilename = "FortuneCats_qipao.csb"
    self:createCsbNode(resourceFilename)
    util_setCascadeOpacityEnabledRescursion(self.m_csbNode, true)
end

function FortuneCatsShopNeedMore:showUI(func)
    self:setVisible(true)
    self:runCsbAction("start", false, function()
        self:runCsbAction("idle", true)
        if type(func) == "function" then
            func()
        end
    end)
end

function FortuneCatsShopNeedMore:closeUI(callFunc)
    self:runCsbAction("over", false, function()
        if callFunc then
            callFunc()
        end
        self:setVisible(false)
    end)
end


return FortuneCatsShopNeedMore