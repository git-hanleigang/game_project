--[[--
    黑曜卡入口
]]
local CardSeasonBottomObsidian_7 = class("CardSeasonBottomObsidian_7", BaseView)

function CardSeasonBottomObsidian_7:getCsbName()
    return "CardRes/season202304/cash_season_obsidian_7.csb"
end

function CardSeasonBottomObsidian_7:initCsbNodes()
    self.m_spPickGame = self:findChild("sp_pickGame")
    self.m_nodeRedPoint = self:findChild("node_redPoint")
    self.m_lbTime = self:findChild("lb_time")

    self.m_touch = self:findChild("Panel_touch")
    self:addClick(self.m_touch)
end

function CardSeasonBottomObsidian_7:initUI()
    CardSeasonBottomObsidian_7.super.initUI(self)
end

function CardSeasonBottomObsidian_7:clickFunc(sender)
    local name = sender:getName()
    if name == "Panel_touch" then
        G_GetMgr(G_REF.ObsidianCard):showMainLayer()
    end
end

function CardSeasonBottomObsidian_7:onEnter()
    CardSeasonBottomObsidian_7.super.onEnter(self)
end

function CardSeasonBottomObsidian_7:setTimeStr(str)
    if type(str) ~= "string" then
        return
    end
    if self.m_lbTime then
        self.m_lbTime:setString(str)
    end
end

return CardSeasonBottomObsidian_7
