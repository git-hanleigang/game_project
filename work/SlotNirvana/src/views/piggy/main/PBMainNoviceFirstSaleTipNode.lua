local PBMainNoviceFirstSaleTipNode = class("PBMainNoviceFirstSaleTipNode", BaseView)

function PBMainNoviceFirstSaleTipNode:getCsbName()
    if globalData.slotRunData.isPortrait == true then
        return "PigBank2022/csb/main/PB1STMore_Portrait.csb"
    end
    return "PigBank2022/csb/main/PB1STMore.csb"
end

function PBMainNoviceFirstSaleTipNode:initUI()
    PBMainNoviceFirstSaleTipNode.super.initUI(self)

    local discountRate = G_GetMgr(G_REF.PiggyBank):getNoviceFirstBuyDisCount()
    local lbDisc = self:findChild("lb_num")
    lbDisc:setString("" .. discountRate .. "%")
end

return PBMainNoviceFirstSaleTipNode