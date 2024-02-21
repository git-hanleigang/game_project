
---
--xcyy
--2018年5月23日
--ClassicRapid2_ClassicReelView.lua

local ClassicRapid2_ClassicReelView = class("ClassicRapid2_ClassicReelView",util_require("base.BaseView"))


function ClassicRapid2_ClassicReelView:initUI(data)

    self:createCsbNode("ClassicRapid2_Classical.csb")
    self.m_jackpotList = {}
    self.m_jackpotTopList = {}
    for i=1,5 do
        self.m_jackpotList[i] = self:findChild("jackpotBg"..i)
        self.m_jackpotTopList[i] = self:findChild("jackpotTop"..i)
    end
    self:runCsbAction("idle"..data)
end

function ClassicRapid2_ClassicReelView:initReelElement(machineElement,machine)

    for i=1,#machineElement do
          local nodeInfo = machineElement[i]
        local parent = self:findChild("Node_"..nodeInfo.ArrayPos.iY.."_"..nodeInfo.ArrayPos.iX)--Node_1_5  Node_1_5
        parent:removeAllChildren()
        if parent then
            local machineNode = machine:getSlotNodeBySymbolType(nodeInfo.Type, nodeInfo.ArrayPos.iX, nodeInfo.ArrayPos.iY, true)
            parent:addChild(machineNode, nodeInfo.Zorder, self.REPIN_NODE_TAG)
        end

    end
end
-- end
function ClassicRapid2_ClassicReelView:showWheel()
    self:findChild("reayWheel111"):setVisible(true)
end

function ClassicRapid2_ClassicReelView:hideWheel()
    self:findChild("reayWheel111"):setVisible(false)
end

function ClassicRapid2_ClassicReelView:onEnter()


end

function ClassicRapid2_ClassicReelView:onExit()

end

--默认按钮监听回调
function ClassicRapid2_ClassicReelView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

end


return ClassicRapid2_ClassicReelView