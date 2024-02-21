--[[--
    黑曜卡入口
]]
local CardSeasonBottomObsidian_4 = class("CardSeasonBottomObsidian_4", BaseView)

function CardSeasonBottomObsidian_4:getCsbName()
    return "CardRes/season202304/cash_season_obsidian_4.csb"
end

function CardSeasonBottomObsidian_4:initCsbNodes()
    self.m_spPickGame = self:findChild("sp_pickGame")
    self.m_nodeRedPoint = self:findChild("node_redPoint")
    self.m_lbTime = self:findChild("lb_time")

    self.m_touch = self:findChild("Panel_touch")
    self:addClick(self.m_touch)
end

function CardSeasonBottomObsidian_4:initUI()
    CardSeasonBottomObsidian_4.super.initUI(self)
end

function CardSeasonBottomObsidian_4:clickFunc(sender)
    local name = sender:getName()
    if name == "Panel_touch" then
        G_GetMgr(G_REF.ObsidianCard):showMainLayer()
    end
end

function CardSeasonBottomObsidian_4:onEnter()
    CardSeasonBottomObsidian_4.super.onEnter(self)
end

function CardSeasonBottomObsidian_4:setTimeStr(str)
    if type(str) ~= "string" then
        return
    end
    if self.m_lbTime then
        self.m_lbTime:setString(str)
    end
end

return CardSeasonBottomObsidian_4
