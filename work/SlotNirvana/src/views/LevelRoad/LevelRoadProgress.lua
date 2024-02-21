-- 等级里程碑进度界面
local LevelRoadProgress = class("LevelRoadProgress", util_require("base.BaseView"))

function LevelRoadProgress:initUI()
    LevelRoadProgress.super.initUI(self)
    self:initView()
end

function LevelRoadProgress:initDatas()
    self.m_phaseStartPercent = 0
    self.m_phasePercent = 0
    self.m_maxLen = 2444 -- 进度条底默认长度
    self.m_maxBarLen = 2320 -- 进度条默认长度
    self.m_singleLen = globalData.slotRunData.isPortrait and 340 or 464 -- 俩个奖励节点之间的长度固定（根据这个值设置进度条的长度）
    self.m_progressNum = -1
    self.m_originPosX = 200 -- 第一个点距开始位置差
    self.m_particleOriginPosX = globalData.slotRunData.isPortrait and 2 or 20
    self.m_firstRewardNodePos = cc.p(0, 0)
    self.m_firstRewardNode = nil
end

function LevelRoadProgress:getCsbName()
    if globalData.slotRunData.isPortrait then
        return "LevelRoad/csd/Main_Portrait/LevelRoad_levelbar_Portrait.csb"
    end
    return "LevelRoad/csd/LevelRoad_levelbar.csb"
end

function LevelRoadProgress:initCsbNodes()
    self.m_sp_bar_di = self:findChild("sp_bar_di")
    self.m_progress = self:findChild("LoadingBar_1")
    self.m_node_start = self:findChild("node_start")
    self.m_node_level_phase = self:findChild("node_level_phase")
    self.m_node_progress = self:findChild("node_progress")
    self.m_particle = self:findChild("Particle_1")
end

function LevelRoadProgress:onEnter()
    LevelRoadProgress.super.onEnter(self)
    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            util_performWithDelay(
                self,
                function()
                    local moveDistance = self.m_originPosX + self.m_progressNum * self.m_singleLen
                    local action = nil
                    if globalData.slotRunData.isPortrait then
                        local posX = self.m_node_progress:getPositionX()
                        action = cc.MoveTo:create(1, cc.p(posX, -moveDistance))
                    else
                        local posY = self.m_node_progress:getPositionY()
                        action = cc.MoveTo:create(1, cc.p(-moveDistance, posY))
                    end
                    self.m_node_progress:runAction(action)
                end,
                30 / 60
            )
        end,
        ViewEventType.NOTIFY_LEVELROAD_CLOSE_REWARDLAYER
    )
end

function LevelRoadProgress:initView()
    self:initStartNode()
    self:initPhaseNode()
    self:initProgressBar()
end

function LevelRoadProgress:initStartNode()
    local data = G_GetMgr(G_REF.LevelRoad):getRunningData()
    if data then
        local startLevel = globalData.userRunData.levelNum
        local startNode = util_createAnimation("LevelRoad/csd/LevelRoad_levelbar_start.csb")
        self.m_node_start:addChild(startNode)
        local lb_start_level = startNode:findChild("lb_start_level")
        lb_start_level:setString("" .. startLevel)
        local node_head = startNode:findChild("node_head")
        if node_head then
            local fbid = globalData.userRunData.facebookBindingID
            local headId = globalData.userRunData.HeadName
            local headSize = cc.size(56, 56)
            local nodeAvatar = G_GetMgr(G_REF.AvatarFrame):createCommonAvatarNode(fbid, headId, "", nil, headSize)
            nodeAvatar:addTo(node_head)
        end
    end
end

function LevelRoadProgress:initPhaseNode()
    local data = G_GetMgr(G_REF.LevelRoad):getRunningData()
    if data then
        local phase = data:getPhaseData()
        if #phase > 0 then
            local inx = #phase - 1
            self.m_maxBarLen = self.m_originPosX + self.m_singleLen * inx
            self.m_maxLen = self.m_maxBarLen + 24
            self.m_sp_bar_di:setContentSize(cc.size(self.m_maxLen, self.m_sp_bar_di:getContentSize().height))
            self.m_progress:setContentSize(cc.size(self.m_maxBarLen, self.m_progress:getContentSize().height))
            self.m_phaseStartPercent = (self.m_originPosX / self.m_maxBarLen) * 100
            if inx > 0 then
                self.m_phasePercent = (100 - self.m_phaseStartPercent) / inx
            end
            for i = 1, #phase do
                -- 奖励气泡节点
                local rewardNode = util_createView("views.LevelRoad.LevelRoadRewardNode", {phaseData = phase[i]})
                self.m_node_level_phase:addChild(rewardNode)
                local posX = self.m_originPosX + (i - 1) * self.m_singleLen
                -- 等级节点
                local levelPhaseNode = nil
                if phase[i].type ~= "CoinsItems" then
                    levelPhaseNode = util_createView("views.LevelRoad.LevelRoadLevelPhase", {phaseData = phase[i]})
                    self.m_node_level_phase:addChild(levelPhaseNode)
                end

                if globalData.slotRunData.isPortrait then
                    rewardNode:setPositionY(posX)
                    if levelPhaseNode then
                        levelPhaseNode:setPositionY(posX)
                    end
                else
                    rewardNode:setPositionX(posX)
                    if levelPhaseNode then
                        levelPhaseNode:setPositionX(posX)
                    end
                end
                if i == 1 then
                    self.m_firstRewardNode = rewardNode
                    local offsetPos = rewardNode:getOffsetPos()
                    local nodePos = cc.p(rewardNode:getPosition())
                    self.m_firstRewardNodePos = cc.p(nodePos.x + offsetPos.x, nodePos.y + offsetPos.y)
                end
            end
        end
    end
end

function LevelRoadProgress:initProgressBar()
    local data = G_GetMgr(G_REF.LevelRoad):getRunningData()
    if data then
        local nextPhaseLevel = 0
        local curLevel = globalData.userRunData.levelNum
        local phase = data:getPhaseData()
        local perLevel = curLevel
        for i = 1, #phase do
            if phase[i].level > curLevel then
                nextPhaseLevel = phase[i].level
                break
            else
                perLevel = phase[i].level
                if phase[i].type == "CoinsItems" then --老玩家
                    perLevel = curLevel
                end
                self.m_progressNum = self.m_progressNum + 1
            end
        end
        local ratio = 0
        if nextPhaseLevel > perLevel then
            ratio = (curLevel - perLevel) / (nextPhaseLevel - perLevel)
        end
        local progressNum = math.max(self.m_progressNum, 0)
        local startPer = self.m_progressNum >= 0 and self.m_phaseStartPercent or 0
        local percent = startPer + self.m_phasePercent * (progressNum + ratio)
        percent = math.floor(percent + 0.5)
        self.m_progress:setPercent(percent)
        self.m_particle:setVisible(percent > 0)
        local pos = self.m_particleOriginPosX + self.m_maxBarLen * percent * 0.01
        if globalData.slotRunData.isPortrait then
            self.m_particle:setPositionY(pos)
        else
            self.m_particle:setPositionX(pos)
        end
    end
end

function LevelRoadProgress:getFirstRewardNodePos()
    local worldPos = self.m_node_level_phase:convertToWorldSpace(cc.p(self.m_firstRewardNodePos))
    return worldPos
end

function LevelRoadProgress:hideFirstNode()
    if self.m_firstRewardNode then
        self.m_firstRewardNode:setVisible(false)
    end
end

return LevelRoadProgress
