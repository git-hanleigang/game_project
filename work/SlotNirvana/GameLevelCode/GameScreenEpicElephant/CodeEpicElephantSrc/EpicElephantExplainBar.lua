---
--xcyy
--2018年5月23日
--EpicElephantExplainBar.lua
--说明条

local EpicElephantExplainBar = class("EpicElephantExplainBar",util_require("Levels.BaseLevelDialog"))


function EpicElephantExplainBar:initUI(params)
    self.m_machine = params.machine
    self:createCsbNode("EpicElephant_shuoming.csb")
    self.m_tipsId = 1
    self:qieHuanTips(true)
end

function EpicElephantExplainBar:qieHuanTips(isFirst)
    local nodeName = {"Node_mini", "Node_minor", "Node_major", "Node_mega"}
    if isFirst then
        for i,vNode in ipairs(nodeName) do
            self:findChild(vNode):setVisible(false)
        end
        self:findChild(nodeName[self.m_tipsId]):setVisible(true)
    else
        local lastTipId = self.m_tipsId - 1
        if self.m_tipsId == 1 then
            lastTipId = 4
        end
        util_nodeFadeIn(self:findChild(nodeName[lastTipId]), 0.5, 255, 0, nil, function()
            self:findChild(nodeName[lastTipId]):setVisible(false)
        end)
        self:findChild(nodeName[self.m_tipsId]):setVisible(true)
        util_nodeFadeIn(self:findChild(nodeName[self.m_tipsId]), 0.5, 0, 255, nil, nil)
    end

    self.m_machine:delayCallBack(5,function()
        self.m_tipsId = self.m_tipsId + 1
        if self.m_tipsId > 4 then
            self.m_tipsId = 1
        end
        self:qieHuanTips()
    end)
end


return EpicElephantExplainBar