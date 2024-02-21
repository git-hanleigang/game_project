--[[--
    黑曜卡入口
]]
local CardSeasonBottomObsidian_2 = class("CardSeasonBottomObsidian_2", BaseView)

function CardSeasonBottomObsidian_2:getCsbName()
    return "CardRes/season202204/cash_season_obsidian_2.csb"
end

function CardSeasonBottomObsidian_2:initCsbNodes()
    self.m_spPickGame = self:findChild("sp_pickGame")
    self.m_nodeRedPoint = self:findChild("node_redPoint")
    self.m_lbTime = self:findChild("lb_time")

    self.m_touch = self:findChild("Panel_touch")
    self:addClick(self.m_touch)
end

function CardSeasonBottomObsidian_2:initUI()
    CardSeasonBottomObsidian_2.super.initUI(self)
end

function CardSeasonBottomObsidian_2:clickFunc(sender)
    local name = sender:getName()
    if name == "Panel_touch" then
        G_GetMgr(G_REF.ObsidianCard):showMainLayer()
    end
end

function CardSeasonBottomObsidian_2:onEnter()
    CardSeasonBottomObsidian_2.super.onEnter(self)
end

function CardSeasonBottomObsidian_2:setTimeStr(str)
    if type(str) ~= "string" then
        return
    end
    if self.m_lbTime then
        self.m_lbTime:setString(str)
    end
end

return CardSeasonBottomObsidian_2
