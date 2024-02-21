--[[--
    黑曜卡入口
]]
local CardSeasonBottomObsidian_3 = class("CardSeasonBottomObsidian_3", BaseView)

function CardSeasonBottomObsidian_3:getCsbName()
    return "CardRes/season202301/cash_season_obsidian_3.csb"
end

function CardSeasonBottomObsidian_3:initCsbNodes()
    self.m_spPickGame = self:findChild("sp_pickGame")
    self.m_nodeRedPoint = self:findChild("node_redPoint")
    self.m_lbTime = self:findChild("lb_time")

    self.m_touch = self:findChild("Panel_touch")
    self:addClick(self.m_touch)
end

function CardSeasonBottomObsidian_3:initUI()
    CardSeasonBottomObsidian_3.super.initUI(self)
end

function CardSeasonBottomObsidian_3:clickFunc(sender)
    local name = sender:getName()
    if name == "Panel_touch" then
        G_GetMgr(G_REF.ObsidianCard):showMainLayer()
    end
end

function CardSeasonBottomObsidian_3:onEnter()
    CardSeasonBottomObsidian_3.super.onEnter(self)
end

function CardSeasonBottomObsidian_3:setTimeStr(str)
    if type(str) ~= "string" then
        return
    end
    if self.m_lbTime then
        self.m_lbTime:setString(str)
    end
end

return CardSeasonBottomObsidian_3
