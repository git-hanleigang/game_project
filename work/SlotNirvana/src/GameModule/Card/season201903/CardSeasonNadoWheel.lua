local CardSeasonNadoWheel = class("CardSeasonNadoWheel", util_require("base.BaseView"))

function CardSeasonNadoWheel:getCsbName()
    return string.format(CardResConfig.seasonRes.CardSeasonNadoWheelRes, "season201903")
end

function CardSeasonNadoWheel:getRedPointLua()
    return "GameModule.Card.season201903.CardRedPoint"
end

function CardSeasonNadoWheel:initUI()
    self:createCsbNode(self:getCsbName())
    self:addClick(self:findChild("touch"))
    self.m_numNode = self:findChild("Node_num")
    self:updateNum()
end

function CardSeasonNadoWheel:clickFunc(sender)
    local name = sender:getName()
    if name == "touch" then
        CardSysManager:showNadoMachine("menu")
    end
end

function CardSeasonNadoWheel:updateNum()
    -- local linkGameData = CardSysRuntimeMgr:getLinkGameData()
    -- local leftNum = linkGameData and linkGameData.nadoGames or 0
    local leftNum = CardSysRuntimeMgr:getNadoGameLeftCount() or 0
    if leftNum > 0 then
        self.m_numNode:setVisible(true)
        if not self.m_numUI then
            self.m_numUI = util_createView(self:getRedPointLua())
            self.m_numNode:addChild(self.m_numUI)
        end
        leftNum = math.min(999, leftNum)
        self.m_numUI:updateNum(leftNum)
    else
        self.m_numNode:setVisible(false)
        if self.m_numUI ~= nil then
            self.m_numUI:removeFromParent()
            self.m_numUI = nil
        end
    end
end

return CardSeasonNadoWheel
