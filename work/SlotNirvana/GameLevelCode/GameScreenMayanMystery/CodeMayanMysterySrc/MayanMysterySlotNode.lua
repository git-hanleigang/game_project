
local MayanMysterySlotNode = class("MayanMysterySlotNode",require("Levels.SlotsNode"))

--添加拖尾
function MayanMysterySlotNode:addTuoWeiSpine(parentNode)
    if self.m_isLastSymbol ~= true and self.m_trailingNode == nil then
        if self.p_symbolType == 93 then
            self.m_trailingNode = util_spineCreate("Socre_MayanMystery_Wild2_tuowei",true,true)
        else
            self.m_trailingNode = util_spineCreate("Socre_MayanMystery_Wild1_tuowei",true,true)
        end
        util_spinePlay(self.m_trailingNode, "idleframe", false)
        self:addChild(self.m_trailingNode, -1)
    end
end

--更新图标坐标
-- function MayanMysterySlotNode:updateDistance(distance)
--     MayanMysterySlotNode.super.updateDistance(self,distance)
--     if not tolua.isnull(self.m_trailingNode) then
--         self.m_trailingNode:setPosition(cc.p(self:getPosition()))
--     end
-- end

function MayanMysterySlotNode:removeTuoWeiSpine()
    if not tolua.isnull(self.m_trailingNode) then
        self.m_trailingNode:removeFromParent()
        self.m_trailingNode = nil
    end
end

-- 还原到初始被创建的状态
function MayanMysterySlotNode:reset()
    if not tolua.isnull(self.m_trailingNode) then
        self:removeTuoWeiSpine()
    end
    MayanMysterySlotNode.super.reset(self)
end

return MayanMysterySlotNode