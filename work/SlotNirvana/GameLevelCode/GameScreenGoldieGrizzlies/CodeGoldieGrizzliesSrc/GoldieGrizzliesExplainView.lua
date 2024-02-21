

local GoldieGrizzliesExplainView = class("GoldieGrizzliesExplainView", util_require("Levels.BaseLevelDialog"))


function GoldieGrizzliesExplainView:initUI(params)
    self:createCsbNode("GoldieGrizzlies/GameStart.csb")
    self:runCsbAction("idle",true)
    self:addClick(self:findChild("Panel_1"))
    performWithDelay(self,function()
        self:clickFunc()
    end,3)
end

function GoldieGrizzliesExplainView:clickFunc(sender)
    if self.m_isClicked then
        return
    end
    self.m_isClicked = true

    self:runCsbAction("over",false,function()
        self:removeFromParent()
    end)
end

return GoldieGrizzliesExplainView