--点击选择
local PagingStepNode = class("PagingStepNode", util_require("base.BaseView"))

function PagingStepNode:initUI(nameStr,stepNum)
    local csbName = "RateUs/PagingStepNode"
    if nameStr then
        csbName = nameStr
    end
    self:createCsbNode(csbName..".csb")

    self.m_unReachList = {}
    self.m_reachedList = {}
    self.m_achieveList = {}

    for i=1,stepNum do
        local unClick = self:findChild("unReach"..i)
        local clicked = self:findChild("reached"..i)
        local achieve = self:findChild("achieve"..i)
        clicked:setVisible(false)
        achieve:setVisible(false)

        self.m_unReachList[#self.m_unReachList+1] = unClick
        self.m_reachedList[#self.m_reachedList+1] = clicked
        self.m_achieveList[#self.m_achieveList+1] = achieve
    end
end

function PagingStepNode:updateClicked(stepNum)
    for i=1,stepNum do
        if stepNum <= #self.m_unReachList then
            -- self.m_unReachList[i]:setVisible(false)
            self.m_reachedList[i]:setVisible(true)
        end
        if i-1 > 0 then
            self.m_achieveList[i-1]:setVisible(true)
        end
    end
end



return PagingStepNode