--[[--
]]
local CardDropMachine = class("CardDropMachine", BaseView)

function CardDropMachine:getCsbName()
    --移动资源到包内
    return "CardsBase201903/CardRes/season201903/DropNew2/machine_node.csb"
end

function CardDropMachine:initCsbNodes()
    self.m_numLB = self:findChild("num")
    -- self.m_checkitBtn = self:findChild("Button_checkit")
end

function CardDropMachine:initUI()
    CardDropMachine.super.initUI(self)
end

function CardDropMachine:getMachineBtn()
    return self.m_numLB
end

function CardDropMachine:updateNum(num)
    self.m_numLB:setString(num)
    -- self:updateLabelSize({label=self.m_numLB,sx=0.82,sy=0.82},35)
end

-- function CardDropMachine:playStart(overFunc)
--     self:runCsbAction("show", false, overFunc)
-- end

function CardDropMachine:playFlyto()
    self:runCsbAction("flyto")
end

-- function CardDropMachine:playShowBtn(overFunc)
--     self:runCsbAction("anniu", false, overFunc)
-- end

-- function CardDropMachine:clickFunc(sender)
--     local name = sender:getName()
--     if name == "Button_checkit" then
--         gLobalSoundManager:playSound(CardResConfig.CARD_MUSIC.BtnBack)
--         if self.m_dropView then
--             self.m_dropView:clickCheckIt()
--         end
--     end
-- end

return CardDropMachine
