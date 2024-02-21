

local KoiBlissSlotsNode = class("KoiBlissSlotsNode", util_require("Levels.SlotsNode"))
KoiBlissSlotsNode.m_labNode = nil
KoiBlissSlotsNode.SYMBOL_BONUS_1 = 94
KoiBlissSlotsNode.SYMBOL_BONUS_2 = 95
function KoiBlissSlotsNode:addLabel()
    self:clearLabelNode()
    if self.p_symbolType == self.SYMBOL_BONUS_1 then
        self.m_labNode = util_createAnimation("Socre_KoiBliss_Bouns1_Lab.csb")
        self:addChild(self.m_labNode,20)
    elseif self.p_symbolType == self.SYMBOL_BONUS_2 then
        self.m_labNode = util_createAnimation("Socre_KoiBliss_Bouns2_Lab.csb")
        self:addChild(self.m_labNode,20)
    end
end

function KoiBlissSlotsNode:runLabAnim(anim)
    if self.m_labNode ~= nil then
        self.m_labNode:playAction(anim)
    end
end
function KoiBlissSlotsNode:clearLabelNode()
    if self.m_labNode then
        self.m_labNode:stopAllActions()
        local ccbNode = self:getCCBNode()
        if self.p_symbolType == self.SYMBOL_BONUS_2 and ccbNode and ccbNode.m_spineNode then
            -- util_spineClearBindNode(ccbNode.m_spineNode)
            self.m_labNode:removeFromParent()
        else
            self.m_labNode:removeFromParent()
        end
        self.m_labNode = nil
    end
end
function KoiBlissSlotsNode:reset()
    self:clearLabelNode()
    self.super.reset(self)
end
function KoiBlissSlotsNode:onExit()
    self:clearLabelNode()
    self:clear()
end
function KoiBlissSlotsNode:initOnExit()
    self:registerScriptHandler( function(tag)
        if "exit" == tag then
            if self.onExit then
                self:onExit()
            end
        end
    end )
end
return KoiBlissSlotsNode