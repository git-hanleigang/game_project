
local FlamingPompeiiSlotNode = class("FlamingPompeiiSlotNode",util_require("Levels.SlotsNode"))

FlamingPompeiiSlotNode.SymbolImageAddNodeName = "FlamingPompeiiBonusAddNode"
FlamingPompeiiSlotNode.CCBNameToCsbName = {
    Socre_FlamingPompeii_Bonus1 = "FlamingPompeii_Bonus1_Label.csb",
    Socre_FlamingPompeii_Bonus2 = "FlamingPompeii_Bonus2_Label.csb",
}

-- 解决静态图的展示问题 修改静态图可见性和图片资源的地方都要调用
function FlamingPompeiiSlotNode:upDateFlamingPompeiiSlotNodeImage(_ccbName)
    -- 不在静态图展示状态
    if nil == self.p_symbolImage or not self.p_symbolImage:isVisible() then
        return
    end

    local ccbName = _ccbName or self.m_ccbName
    local csbPath = self.CCBNameToCsbName[ccbName]
    -- 没有配置的信号在开启静态图展示时把新增节点移除掉
    if not csbPath then
        local addNode = self.p_symbolImage:getChildByName(self.SymbolImageAddNodeName)
        if addNode then
            -- util_printLog("[FlamingPompeiiSlotNode:upDateFlamingPompeiiSlotNodeImage] 移除bonus的静态图附加节点")
            addNode:removeFromParent()
            -- util_printLog("[FlamingPompeiiSlotNode:upDateFlamingPompeiiSlotNodeImage] 移除bonus的静态图附加节点 完毕")
        end
        return
    end
end
-- 创建bonus 和 bonus2 静态图的分数展示节点
function FlamingPompeiiSlotNode:createBonusAddNode()
    local addNode = nil
    -- 不存在静态图节点
    if nil == self.p_symbolImage then
        return addNode
    end
    -- 信号配置
    local csbPath = self.CCBNameToCsbName[self.m_ccbName]
    if nil == csbPath then
        return addNode
    end
    -- 不存在的话创建一下
    addNode = self:getBonusAddNode()
    if not addNode then
        addNode       = util_createAnimation(csbPath)
        self.p_symbolImage:addChild(addNode, 10)
        addNode:setName(self.SymbolImageAddNodeName)
        --静态图0.5缩放
        addNode:setScale(2)
        --关卡小块尺寸的宽高
        local size = self.p_symbolImage:getContentSize()
        local pos  = cc.p(size.width/2, size.height/2) 
        addNode:setPosition(pos)
    end

    addNode:findChild("grand"):setVisible(false)
    addNode:findChild("mega"):setVisible(false)
    addNode:findChild("major"):setVisible(false)
    addNode:findChild("minor"):setVisible(false)
    addNode:findChild("mini"):setVisible(false)
    addNode:findChild("m_lb_coins"):setVisible(false)
    addNode:findChild("Node_2"):setVisible(false)
    addNode:setVisible(true)

    return addNode
end
function FlamingPompeiiSlotNode:getBonusAddNode()
    local addNode = nil
    -- 不存在静态图节点
    if nil == self.p_symbolImage then
        return addNode
    end
    addNode = self.p_symbolImage:getChildByName(self.SymbolImageAddNodeName)
    return addNode
end

function FlamingPompeiiSlotNode:reset()
    FlamingPompeiiSlotNode.super.reset(self)
    self:upDateFlamingPompeiiSlotNodeImage()
end
function FlamingPompeiiSlotNode:resetReelStatus()
    FlamingPompeiiSlotNode.super.resetReelStatus(self)
    self:upDateFlamingPompeiiSlotNodeImage()
end
function FlamingPompeiiSlotNode:initSlotNodeByCCBName(ccbName,symbolType)
    FlamingPompeiiSlotNode.super.initSlotNodeByCCBName(self, ccbName,symbolType)
    self:upDateFlamingPompeiiSlotNodeImage(ccbName)
end
function FlamingPompeiiSlotNode:changeSymbolImageByName(ccbName)
    FlamingPompeiiSlotNode.super.changeSymbolImageByName(self, ccbName)
    self:upDateFlamingPompeiiSlotNodeImage(ccbName)
end

return FlamingPompeiiSlotNode