--[[
    author:{author}
    time:2019-08-14 15:38:45
]]

local KangaroosShopNeedMore = class("KangaroosShopNeedMore", util_require("base.BaseView"))

function KangaroosShopNeedMore:initUI()

    local resourceFilename = "OutbackFrontierShop/Socre_Kangaroos_qipao.csb"
    self:createCsbNode(resourceFilename)
    util_setCascadeOpacityEnabledRescursion(self.m_csbNode, true)
end

function KangaroosShopNeedMore:closeUI(callFunc)
    self:runCsbAction("over", false, function()
        self:setVisible(false)
        if callFunc then
            callFunc()
        end
    end)
end

function KangaroosShopNeedMore:showUI(callFunc)
    self:setVisible(true)
    self:runCsbAction("start", false, function()
        self:runCsbAction("idle", true)
        if type(callFunc) == "function" then
            callFunc()
        end
    end)
end


return KangaroosShopNeedMore