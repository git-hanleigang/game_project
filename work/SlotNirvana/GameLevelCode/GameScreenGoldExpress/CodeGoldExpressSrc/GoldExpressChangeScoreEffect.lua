---
--island
--2018年4月12日
--GoldExpressChangeScoreEffect.lua
---- respin 玩法结算时中 mini mijor等提示界面
local GoldExpressChangeScoreEffect = class("GoldExpressChangeScoreEffect", util_require("base.BaseView"))

function GoldExpressChangeScoreEffect:initUI(data)
    self.m_click = false

    local resourceFilename = "GoldExpress_tishi.csb"
    self:createCsbNode(resourceFilename)

end


function GoldExpressChangeScoreEffect:onEnter()
end

function GoldExpressChangeScoreEffect:onExit()
end

function GoldExpressChangeScoreEffect:runAnimation(animation, isLoop, func, fps)
    self:runCsbAction(animation, isLoop, func, fps)
end

return GoldExpressChangeScoreEffect