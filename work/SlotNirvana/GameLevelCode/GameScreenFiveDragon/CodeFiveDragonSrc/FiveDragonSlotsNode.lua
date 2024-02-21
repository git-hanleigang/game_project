local FiveDragonSlotsNode = class("FiveDragonSlotsNode", util_require("Levels.SlotsNode"))
FiveDragonSlotsNode.m_machine = nil

function FiveDragonSlotsNode:init()
    self.m_TAG_CCBNODE = 10
    self.m_lineAnimName = nil
    self.p_idleIsLoop = true
end

function FiveDragonSlotsNode:runLineAnim()

    local animName = self:getLineAnimName()

    self:runAnim(animName,true)
end

function FiveDragonSlotsNode:runIdleAnim()
    if self.p_idleIsLoop == nil then
        self.p_idleIsLoop = false
    end

    local csbNode = self:getCCBNode()
    if csbNode ~= nil then  -- 不用图片代替时才会直接播放默认动画
        self:runAnim(self:getIdleAnimName(),self.p_idleIsLoop)
    end
    
end

function FiveDragonSlotsNode:runAnim(animName,loop,func)

    local ccbNode = self:checkLoadCCbNode()
    if ccbNode ~= nil and self.p_symbolImage ~= nil then
        self.p_symbolImage:setVisible(false)
    end

    local isPlay = ccbNode:runAnim(animName,loop,func)
    if self.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
        local spineNode = ccbNode:getCcbProperty("Spine")
        if spineNode then
            if spineNode:getChildByName("Classic") == nil then
                local animationNode = util_spineCreate("Socre_FiveDragon_Wild_Anim", true, true)
                animationNode:setName("Classic")
                spineNode:addChild(animationNode,1, self.m_TAG_CCBNODE)
                util_spinePlay(animationNode, animName)
            else
                local spine = spineNode:getChildByName("Classic")
                if spine then
                    util_spinePlay(spine, animName)
                end
            end
        end
        
    end
    if isPlay == true then
        self.m_slotAnimaLoop = loop
        self.m_currAnimName = animName

        if self.m_animaCallBackFun ~= nil then
            self.m_animaCallBackFun(self)
        end

    end
    
end

return FiveDragonSlotsNode
