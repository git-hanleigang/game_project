---
--island
--2018年4月12日
--GoldExpressSelectedColEffect.lua
---- respin 玩法结算时中 mini mijor等提示界面
local GoldExpressSelectedColEffect = class("GoldExpressSelectedColEffect", util_require("base.BaseView"))

function GoldExpressSelectedColEffect:initUI(data)
    self.m_click = false

    local resourceFilename = "GoldExpress_tishi2.csb"
    self:createCsbNode(resourceFilename)

end


function GoldExpressSelectedColEffect:onEnter()
end

function GoldExpressSelectedColEffect:onExit()
end

function GoldExpressSelectedColEffect:runAnimation(animation, isLoop, func, fps)
    self:runCsbAction(animation, isLoop, func, fps)
end

return GoldExpressSelectedColEffect