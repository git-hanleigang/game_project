--[[
    --新版每日任务pass主界面 赛季进度
    csc 2021-06-21
]]
local QuestPassSeasonProgressNode = class("QuestPassSeasonProgressNode", util_require("base.BaseView"))
function QuestPassSeasonProgressNode:initUI()
    self:createCsbNode(self:getCsbName())

    -- 读取csb 节点
    self.m_barProgress = self:findChild("bar_rewards")
    self.m_labProgress = self:findChild("lb_num")

    self.m_nodeReward = self:findChild("node_rewards")
    self.m_sprSafeBox = self:findChild("sp_safe")

    self:updateView()
end

function QuestPassSeasonProgressNode:getCsbName()
    return QUEST_RES_PATH.QuestPassSeasonProgressNode
end

function QuestPassSeasonProgressNode:updateView()
    local actData = G_GetMgr(ACTIVITY_REF.Quest):getRunningData()
    if not actData then
        self:setVisible(false)
        return
    end
    local passData = actData:getPassData()
    if not passData then
        self:setVisible(false)
        return
    end
    local curLevel,maxLevel = passData:getLevelValue()
    -- 判断当前是否满级
    if curLevel >= maxLevel then
        -- 显示保险箱图片
        self.m_nodeReward:removeAllChildren()
        self.m_nodeReward:setVisible(false)
        self.m_sprSafeBox:setVisible(true)
        self.m_bInSafeBox = true

        local boxData = passData:getBoxReward()
        local curExp = boxData.p_curExp
        local nextExp = boxData.p_totalExp
        local per = curExp / nextExp
        self.m_barProgress:setPercent(per)
        self.m_labProgress:setString("" .. curExp .."/" ..nextExp)
    else
        self.m_nodeReward:setVisible(true)
        --self.m_sprSafeBox:setVisible(false)

        local payPointInfo = passData:getPayRewards()
        local pointInfo_cur = payPointInfo[curLevel]
        local pointInfo = payPointInfo[curLevel + 1]
        local showPointInfo = passData:getPassInfoByIndex(curLevel + 1)
        -- 加载道具
        if pointInfo then
            self:addRewardNode(showPointInfo)
        end
        local curExp = passData:getCurExp()
        local nextExp = pointInfo.p_exp
        local per = (nextExp - curExp) /(pointInfo.p_exp - pointInfo_cur.p_exp) * 100
        if curExp == 0 and curLevel == 1 then
            per = 0
        end
        self.m_barProgress:setPercent(per)
        self.m_labProgress:setString("" .. curExp .."/" ..nextExp)
    end

end

function QuestPassSeasonProgressNode:addRewardNode(_pointInfo)
    self.m_nodeReward:removeAllChildren()
    local payRewardNode = util_createView(QUEST_CODE_PATH.QuestPassRewardNode, _pointInfo, "pay",nil,true)
    self.m_nodeReward:addChild(payRewardNode)
    payRewardNode:setPositionY(-5)
    payRewardNode:setScale(0.5)
end

-- 重置进度条给多开保险箱使用
function QuestPassSeasonProgressNode:resetExpPro()
    local curExp, nextExp = self:getCurrData()
    curExp = 0
    local per, strPer = self:getPercent()
    self.m_barProgress:setPercent(per)
    self.m_labProgress:setString(strPer)

    self.m_lastExp = 0
    self.m_lastNextExp = nextExp --
    self.m_currProExp = 0

    self:updateExpPro(nextExp)
end

return QuestPassSeasonProgressNode
