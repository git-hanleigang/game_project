--[[
]]
local DailyMissionPassPreviewCellProgressNode = class("DailyMissionPassPreviewCellProgressNode", BaseView)

function DailyMissionPassPreviewCellProgressNode:getCsbName()
    if G_GetMgr(ACTIVITY_REF.NewPass):isThreeLinePass() then
        return DAILYPASS_RES_PATH.DailyMissionPass_PreviewCellProgressNode_ThreeLine  
    end
    return DAILYPASS_RES_PATH.DailyMissionPass_PreviewCellProgressNode
end

function DailyMissionPassPreviewCellProgressNode:initCsbNodes()
    self.m_lbNum = self:findChild("lb_num")
    self.m_pro = self:findChild("progress_bar")
end

function DailyMissionPassPreviewCellProgressNode:initUI()
    DailyMissionPassPreviewCellProgressNode.super.initUI(self)
end

function DailyMissionPassPreviewCellProgressNode:updateProgress(_cur, _max)
    if _cur ~= nil and _max ~= nil and _max > 0 then
        self.m_lbNum:setString(_cur.."/".._max)
        local percent = math.floor(_cur / _max * 100)
        self.m_pro:setPercent(percent)
    end
end

return DailyMissionPassPreviewCellProgressNode
