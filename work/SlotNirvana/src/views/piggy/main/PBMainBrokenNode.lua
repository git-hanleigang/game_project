--[[--
    被砸的小猪
]]
local PBMainBrokenNode = class("PBMainBrokenNode", BaseView)

function PBMainBrokenNode:getCsbName()
    return "PigBank2022/csb/main/PBBroken.csb"
end

function PBMainBrokenNode:initDatas(_breakCallFunc)
    self.m_breakTotalCount = 3
    self.m_breakCurCount = 0 -- 砸小猪当前次数
    self.m_breakCallFunc = _breakCallFunc
end

function PBMainBrokenNode:initCsbNodes()
    self.m_panelBreak = self:findChild("Panel_break")
    self:addClick(self.m_panelBreak)
end

function PBMainBrokenNode:initUI()
    PBMainBrokenNode.super.initUI(self)
    self:initView()
end

function PBMainBrokenNode:initView()
end

function PBMainBrokenNode:playLie(_index, _over)
    self:runCsbAction("lie" .. _index, false, _over, 60)
end

function PBMainBrokenNode:breakPiggy(_over)
    self.m_breakCurCount = self.m_breakCurCount + 1

    -- 砸完小猪要弹出结算界面
    if self.m_breakCurCount == self.m_breakTotalCount then
        gLobalSoundManager:playSound("PigBank2022/other/music/brokenPiggy_broken.mp3")
        util_performWithDelay(
            self,
            function()
                G_GetMgr(G_REF.PiggyBank):showRewardLayer()
            end,
            (175 - 140) / 60
        )
    else
        gLobalSoundManager:playSound("PigBank2022/other/music/brokenPiggy_click.mp3")
    end
    self:playLie(
        self.m_breakCurCount,
        function()
            if self.m_breakCurCount < self.m_breakTotalCount then
                if _over then
                    _over()
                end
            end
        end
    )
end

function PBMainBrokenNode:canBreak()
    local view = gLobalViewManager:getViewByName("PiggyBankLayer")
    if view then
        if view:isGoingBreakPig() then
            return false
        end
        if view:isBreakingPig() then
            return false
        end
    end
    if self.m_breakCurCount == self.m_breakTotalCount then
        return false
    end
    return true
end

function PBMainBrokenNode:clickFunc(sender)
    if not self:canBreak() then
        return
    end
    local name = sender:getName()
    if name == "Panel_break" then
        if self.m_breakCallFunc then
            self.m_breakCallFunc()
        end
    end
end

return PBMainBrokenNode
