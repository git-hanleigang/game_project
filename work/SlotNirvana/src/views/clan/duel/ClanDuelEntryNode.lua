--[[
    公会对决 - 左边条入口
]]
local ClanManager = util_require("manager.System.ClanManager"):getInstance()
local ClanDuelEntryNode = class("ClanDuelEntryNode", BaseView)

local DUEL_STATUS = {
    UP = "UP",
    DOWN = "DOWN",
    SAME = "SAME"
}

function ClanDuelEntryNode:getCsbName()
    return "Club/csd/Duel/Duel_GameSceneUiNode.csb"
end

function ClanDuelEntryNode:initDatas()
    ClanDuelEntryNode.super.initDatas(self)
    local clanData = ClanManager:getClanData()
    self.m_duelData = clanData:getClanDuelData()
    self.m_status = self.m_duelData:getDuelStatus() --UP DOWN SAME
    self.m_layerDirction = gLobalActivityManager:getLeftFrameDirection()
    self.m_isAnimationing = false
end

function ClanDuelEntryNode:initCsbNodes()
    self.m_node_entrytips = self:findChild("node_entrytips")
    self.m_node_qipao = self:findChild("node_qipao")
    self.m_btn_open = self:findChild("btn_open")
    self.m_lb_time = self:findChild("lb_time")
end

function ClanDuelEntryNode:initUI()
    ClanDuelEntryNode.super.initUI(self)
    self:initTips()
    self:showDownTimer()
end

--初始化对决图标
function ClanDuelEntryNode:initTips()
    local tips = util_createAnimation("Club/csd/Duel/node_duel_entry_tips.csb")
    self.m_node_entrytips:addChild(tips)
    self.m_sp_lead = tips:findChild("sp_lead")
    self.m_sp_trail = tips:findChild("sp_trail")
    self:updateTips()
end

--初始化对决图标
function ClanDuelEntryNode:updateTips()
    if self.m_sp_lead then
        self.m_sp_lead:setVisible(self.m_status == DUEL_STATUS.UP)
    end
    if self.m_sp_trail then
        self.m_sp_trail:setVisible(self.m_status == DUEL_STATUS.DOWN)
    end
end

-- 刷新对决状态
function ClanDuelEntryNode:updateDuelStatus()
    local clanData = ClanManager:getClanData()
    self.m_duelData = clanData:getClanDuelData()
    self.m_status = self.m_duelData:getDuelStatus() --UP DOWN SAME
    self:updateTips()
end


--显示倒计时
function ClanDuelEntryNode:showDownTimer()
    self:stopTimerAction()
    self.timerAction = schedule(self, handler(self, self.updateLeftTime), 1)
    self:updateLeftTime()
end

function ClanDuelEntryNode:updateLeftTime()
    if self.m_duelData then
        local strLeftTime, isOver = util_daysdemaining(self.m_duelData:getExpireAt())
        if isOver then
            self:stopTimerAction()
            self:closeUI()
            return
        end
        self.m_lb_time:setString(strLeftTime)
    else
        self:stopTimerAction()
        self:closeUI()
    end
end

function ClanDuelEntryNode:stopTimerAction()
    if self.timerAction ~= nil then
        self:stopAction(self.timerAction)
        self.timerAction = nil
    end
end

function ClanDuelEntryNode:forceHideBubble()
    if not self.m_isAnimationing then
        return
    end
    if not self.m_curBubble then
        return
    end
    self.m_isAnimationing = false
    self.m_curBubble:pauseForIndex(0)
    if self.m_actionID then
        self.m_curBubble:stopAction(self.m_actionID)
        self.m_actionID = nil
    end
end

function ClanDuelEntryNode:showBubbleTips()
    local _isVisible = gLobalActivityManager:getEntryNodeVisible(self:getRefName())
    if not _isVisible then
        return
    end
    local pushRootPos = self.m_node_qipao:getParent():convertToWorldSpace(cc.p(self.m_node_qipao:getPosition()))
    local leadTips = gLobalActivityManager:getPushViews(self:getRefName(), "Describe_QiPao_1", pushRootPos)
    local trailTips = gLobalActivityManager:getPushViews(self:getRefName(), "Describe_QiPao_2", pushRootPos)
    if leadTips and self.m_status == DUEL_STATUS.UP then
        self:forceHideBubble()
        self:bubbleAction(leadTips)
    end
    if trailTips and self.m_status == DUEL_STATUS.DOWN then
        self:forceHideBubble()
        self:bubbleAction(trailTips)
    end
end

function ClanDuelEntryNode:bubbleAction(tips)
    if self.m_isAnimationing then
        return
    end
    tips:setVisible(true)
    self.m_isAnimationing = true
    self.m_curBubble = tips
    tips:playAction(
        "show",
        false,
        function()
            tips:playAction("idle", true, nil, 30)
        end,
        30
    )
    self.m_actionID = performWithDelay(
        tips,
        function()
            if not tolua.isnull(tips) then
                tips:playAction(
                    "over",
                    false,
                    function()
                        if not tolua.isnull(self) then
                            self.m_isAnimationing = false
                            self.m_curBubble = nil
                        end
                    end,
                    30
                )
            end
        end,
        110 / 30
    )
end

function ClanDuelEntryNode:getPushViewNode()
    return self.m_node_qipao
end

function ClanDuelEntryNode:getBubblePath1()
    return "Club/csd/Duel/node_duel_qipao.csb"
end

function ClanDuelEntryNode:getBubblePath2()
    return "Club/csd/Duel/node_duel_qipao2.csb"
end

function ClanDuelEntryNode:getRefName()
    return "ClanDuelEntryNode"
end

function ClanDuelEntryNode:createPushViews()
    local pushRootPos = self.m_node_qipao:getParent():convertToWorldSpace(cc.p(self.m_node_qipao:getPosition()))
    gLobalActivityManager:addPushViews(self:getRefName(), pushRootPos, self:getBubblePath1(), "Describe_QiPao_1")
    gLobalActivityManager:addPushViews(self:getRefName(), pushRootPos, self:getBubblePath2(), "Describe_QiPao_2")
end

function ClanDuelEntryNode:onEnter()
    ClanDuelEntryNode.super.onEnter(self)
    self:createPushViews()

    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            if params[1] == true then
                local spinData = params[2]
                if spinData and spinData.extend then
                    if spinData.extend.ClanDuelStatus then
                        local curStatus = spinData.extend.ClanDuelStatus
                        if curStatus ~= DUEL_STATUS.SAME and self.m_status ~= curStatus then
                            self.m_status = curStatus
                            self:showBubbleTips()
                            self:updateTips()
                            self.m_duelData:setDuelStatus(curStatus)
                        end
                    end
                    if spinData.extend.ClanDuelPoints then
                        self.m_duelData:setMyPoints(spinData.extend.ClanDuelPoints)
                    end
                    if spinData.extend.ClanDuelOtherPoints then
                        self.m_duelData:setDuelClanPoints(spinData.extend.ClanDuelOtherPoints)
                    end
                end
            end
        end,
        ViewEventType.NOTIFY_GET_SPINRESULT
    )

    -- 停靠位置发生变化
    gLobalNoticManager:addObserver(
        self,
        function(node, direction)
            if direction then
                self.m_layerDirction = direction
                self:updateBubble()
            end
        end,
        ViewEventType.NOTIFY_FRAME_LAYER_CHANGE_STOP_DIRECTION_LEFTFRAME
    )
end

function ClanDuelEntryNode:updateBubble()
    local pushRootPos = self.m_node_qipao:getParent():convertToWorldSpace(cc.p(self.m_node_qipao:getPosition()))
    local leadTips = gLobalActivityManager:getPushViews(self:getRefName(), "Describe_QiPao_1", pushRootPos)
    local trailTips = gLobalActivityManager:getPushViews(self:getRefName(), "Describe_QiPao_2", pushRootPos)
    if leadTips then
        local img_qipao = leadTips:findChild("Panel_1")
        if img_qipao then
            img_qipao:setVisible(self.m_layerDirction == "left")
        end
        local img_qipao_right = leadTips:findChild("Panel_2")
        if img_qipao_right then
            img_qipao_right:setVisible(self.m_layerDirction == "right")
        end
    end
    if trailTips then
        local img_qipao = trailTips:findChild("Panel_1")
        if img_qipao then
            img_qipao:setVisible(self.m_layerDirction == "left")
        end
        local img_qipao_right = trailTips:findChild("Panel_2")
        if img_qipao_right then
            img_qipao_right:setVisible(self.m_layerDirction == "right")
        end
    end
end

function ClanDuelEntryNode:getPanelSize()
    local size = self:findChild("Node_PanelSize"):getContentSize()
    return {widht = size.width, height = size.height}
end

-- 活动结束 去除图标 --
function ClanDuelEntryNode:closeUI()
    gLobalActivityManager:removePushViews(self:getRefName(), "Describe_QiPao_1")
    gLobalActivityManager:removePushViews(self:getRefName(), "Describe_QiPao_2")
    gLobalActivityManager:removeActivityEntryNode(self:getRefName())
end

function ClanDuelEntryNode:clickFunc(sender)
    local name = sender:getName()
    if name == "btn_open" then
        ClanManager:sendClanInfo(
            function()
                if not tolua.isnull(self) then
                    self:updateDuelStatus()
                end
                ClanManager:popClanDuelMainLayer()
            end
        )
    end
end

-- 监测 有小红点或者活动进度满了
function ClanDuelEntryNode:checkHadRedOrProgMax()
    local bHadRed = false
    if self.m_sp_lead then
        bHadRed = self.m_sp_lead:isVisible() 
    end
    local bProgMax = false
    return {bHadRed, bProgMax}
end

return ClanDuelEntryNode
