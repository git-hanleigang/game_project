--[[
    
]]
local QuestPassProgress = class("QuestPassProgress", BaseView)

function QuestPassProgress:initDatas(_widthCount, _cellSize)
    self.m_widthCount = _widthCount
    self.m_cellSize = _cellSize
    self.m_Dvalue = 28
    self.m_gameData = G_GetMgr(ACTIVITY_REF.Quest):getRunningData()
end

function QuestPassProgress:getCsbName()
    return QUEST_RES_PATH.QuestPassProgress
end

function QuestPassProgress:initCsbNodes()
    self.m_sp_progress_bg = self:findChild("progressBg")
    self.m_sp_progress = self:findChild("progress")
    self.m_progressBg_right = self:findChild("progressBg_right")
    self.m_lb_num = self:findChild("lb_num")
    self.m_sp_bg = self:findChild("sp_bg")
end

function QuestPassProgress:initUI()
    QuestPassProgress.super.initUI(self)

    self:setProgressWidth()
    self:setPointNum()
    self:setCurPoint()
end

function QuestPassProgress:setProgressWidth()
    local size = self.m_sp_progress_bg:getContentSize()
    local progressSize = self.m_sp_progress:getContentSize()
    local curProgress = 0
    local passData = self.m_gameData:getPassData()
    local freeRewards = passData:getFreeRewards()
    local points = passData:getCurExp()
    local index = 0
    local count = #freeRewards
    if points ~= 0 then 
        for i,v in ipairs(freeRewards) do
            if points >= v.p_exp then
                index = i
            else
                break
            end
        end

        if index == 0 then 
            curProgress = self.m_cellSize.width
        elseif index == count then
            curProgress = self.m_widthCount + self.m_Dvalue
        else
            local passPoint = freeRewards[index].p_exp
            local lastPoint = freeRewards[index + 1].p_exp
            local curWidth = self.m_cellSize.width * index
            curProgress = curWidth + (points - passPoint) / (lastPoint - passPoint) * self.m_cellSize.width
        end
    else
        curProgress = self.m_cellSize.width
    end

    self.m_sp_progress_bg:setContentSize(cc.size(self.m_widthCount, size.height))
    self.m_sp_progress:setContentSize(cc.size(curProgress, progressSize.height))
    local progressX = self.m_sp_progress_bg:getPositionX()
    self.m_progressBg_right:setPositionX(self.m_widthCount + progressX)
end

function QuestPassProgress:setPointNum()
    local passData = self.m_gameData:getPassData()
    local freeRewards = passData:getFreeRewards()
    for i,v in ipairs(freeRewards) do
        local txt = ccui.Text:create(v.p_exp, "res/CommonButton/font/Neuron Heavy_2.ttf", 22)
        txt:setPosition(self.m_cellSize.width * i - 20, 21)
        self.m_sp_progress_bg:addChild(txt)
    end
end

function QuestPassProgress:setCurPoint()
    local passData = self.m_gameData:getPassData()
    local curExp = passData:getCurExp()
    local isHide = passData:isGetAllReward()
    self.m_lb_num:setString(curExp)
    self:updateLabelSize({label = self.m_lb_num}, 60)
    self.m_lb_num:setVisible(not isHide)
    self.m_sp_bg:setVisible(not isHide)
end

return QuestPassProgress