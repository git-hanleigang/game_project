local CodeGameScreenGoldenGhostMachine = util_require("CodeGameScreenGoldenGhostMachine")
local GoldenGhostBonusScore = class("GoldenGhostBonusScore",util_require("base.BaseView"))

function GoldenGhostBonusScore:initUseNode( )

    self.lbRedScore = self:findChild("m_lb_score_red")
    self.lbGreenScore = self:findChild("m_lb_score_green")
    self.lbYellowScore = self:findChild("m_lb_score_yellow")
    
end

function GoldenGhostBonusScore:initUI()

    self:createCsbNode("bonus_fly.csb")

    self:initUseNode( )

    self:__setScoreLabelVisible(false)


end


--symbolType:nil:不显示
function GoldenGhostBonusScore:playAnimation(symbolType,score,destPos,callBack,endCallBack)
    symbolType = self.machine:formatAddSpinSymbol(symbolType)
    self.lbRedScore:setVisible(symbolType == CodeGameScreenGoldenGhostMachine.SYMBOL_FIX_BONUS_LV1)
    self.lbGreenScore:setVisible(symbolType == CodeGameScreenGoldenGhostMachine.SYMBOL_FIX_BONUS_LV2)
    self.lbYellowScore:setVisible(symbolType == CodeGameScreenGoldenGhostMachine.SYMBOL_FIX_BONUS_LV3)
    if symbolType == CodeGameScreenGoldenGhostMachine.SYMBOL_FIX_BONUS_LV1 then
        self.lbRedScore:setString(score)
    end
    if symbolType == CodeGameScreenGoldenGhostMachine.SYMBOL_FIX_BONUS_LV2 then
        self.lbGreenScore:setString(score)
    end
    if symbolType == CodeGameScreenGoldenGhostMachine.SYMBOL_FIX_BONUS_LV3 then
        self.lbYellowScore:setString(score)
    end
    self:runCsbAction("animation0",false,function()
        if endCallBack ~= nil then
            endCallBack()
        end
        self:removeFromParent()
    end)
    local function animCallBack(sender)
        self:__setScoreLabelVisible(false)
        if callBack ~= nil then
            callBack()
        end
    end
    self:runAction(cc.Sequence:create(
        cc.MoveTo:create(0.3,destPos),
        cc.CallFunc:create(animCallBack)))
end

function GoldenGhostBonusScore:playSmallAnimation(symbolType,score,destPos,callBack,endCallBack)
    symbolType = self.machine:formatAddSpinSymbol(symbolType)
    self.lbRedScore:setVisible(symbolType == CodeGameScreenGoldenGhostMachine.SYMBOL_FIX_BONUS_LV1)
    self.lbGreenScore:setVisible(symbolType == CodeGameScreenGoldenGhostMachine.SYMBOL_FIX_BONUS_LV2)
    self.lbYellowScore:setVisible(symbolType == CodeGameScreenGoldenGhostMachine.SYMBOL_FIX_BONUS_LV3)
    if symbolType == CodeGameScreenGoldenGhostMachine.SYMBOL_FIX_BONUS_LV1 then
        self.lbRedScore:setString(score)
    end
    if symbolType == CodeGameScreenGoldenGhostMachine.SYMBOL_FIX_BONUS_LV2 then
        self.lbGreenScore:setString(score)
    end
    if symbolType == CodeGameScreenGoldenGhostMachine.SYMBOL_FIX_BONUS_LV3 then
        self.lbYellowScore:setString(score)
    end
    self:runCsbAction("animation0",false,function()
        if endCallBack ~= nil then
            endCallBack()
        end
        self:removeFromParent()
    end)
    local function animCallBack(sender)
        self:__setScoreLabelVisible(false)
        if callBack ~= nil then
            callBack()
        end
    end
    self:runAction(cc.Spawn:create(
                    cc.Sequence:create(cc.MoveTo:create(0.3,destPos),
                                        cc.CallFunc:create(animCallBack)),
                    cc.ScaleTo:create(0.3,0.5)))
end

function GoldenGhostBonusScore:__setScoreLabelVisible(flag)
    self.lbRedScore:setVisible(flag)
    self.lbGreenScore:setVisible(flag)
    self.lbYellowScore:setVisible(flag)
end

function GoldenGhostBonusScore:setMachineInfo(machine)
    self.machine = machine
end

return GoldenGhostBonusScore