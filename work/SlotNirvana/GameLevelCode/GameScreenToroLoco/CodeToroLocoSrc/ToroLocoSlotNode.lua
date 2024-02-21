
--fixios0223
local ToroLocoSlotNode = class("ToroLocoSlotNode",require("Levels.SlotsNode"))

---
-- 还原到初始被创建的状态
function ToroLocoSlotNode:reset()
    if self.m_updateCoinsAction then
        self:stopAction(self.m_updateCoinsAction)
        self.m_updateCoinsAction = nil
    end

    ToroLocoSlotNode.super.reset(self)
end

---
-- clipy 起始的位置
-- clipW
-- clipH 
--
function ToroLocoSlotNode:showBigSymbolClip(clipy, clipW, clipH, col, row)
    if col then
        if self.p_bigSymbolMaskNode == nil then
            if col == 1 then
                if row == 3 then
                    self.p_bigSymbolMaskNode = cc.ClippingRectangleNode:create({x=-clipW*0.5,y=clipy*3.5,width = clipW*2,height = clipH})
                elseif row == 1 then
                    self.p_bigSymbolMaskNode = cc.ClippingRectangleNode:create({x=-clipW*0.5,y=clipy*0.5,width = clipW*2,height = clipH})
                else
                    self.p_bigSymbolMaskNode = cc.ClippingRectangleNode:create({x=-clipW*0.5,y=clipy,width = clipW*2,height = clipH})
                end
            elseif col == 5 then
                if row == 3 then
                    self.p_bigSymbolMaskNode = cc.ClippingRectangleNode:create({x=-clipW*1.5,y=clipy*3.5,width = clipW*2,height = clipH})
                elseif row == 1 then
                    self.p_bigSymbolMaskNode = cc.ClippingRectangleNode:create({x=-clipW*1.5,y=clipy*0.5,width = clipW*2,height = clipH})
                else
                    self.p_bigSymbolMaskNode = cc.ClippingRectangleNode:create({x=-clipW*1.5,y=clipy,width = clipW*2,height = clipH})
                end
            end
            self:addChild(self.p_bigSymbolMaskNode)
            
            self:checkAddToBigSymbolMask()
        end
    else
        ToroLocoSlotNode.super.showBigSymbolClip(self, clipy, clipW, clipH)
    end
end

return ToroLocoSlotNode