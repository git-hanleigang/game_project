-- Created by jfwang on 2019-05-21.
-- QuestNewTaskProgress 基类
--
local QuestNewTaskProgress = class("QuestNewTaskProgress", util_require("base.BaseView"))

-- function QuestNewTaskProgress:ctor()
--     QuestNewTaskProgress.super.ctor(self)

--     self:mergePlistInfos(QUEST_PLIST_PATH.QuestNewTaskProgress)
-- end

function QuestNewTaskProgress:getCsbNodePath()
    return QUESTNEW_RES_PATH.QuestNewTaskProgress
end

function QuestNewTaskProgress:getEffectCsbNodePath()
    return QUESTNEW_RES_PATH.QuestNewTaskProgressEffect
end

function QuestNewTaskProgress:initUI(data)
    self:createCsbNode(self:getCsbNodePath())

    self.m_proNode = self:findChild("jindutiao")
    self.m_proNode:setVisible(true)

    self.m_bar_node = self:findChild("LoadingBar_1")
    self.m_bar_lb_value = self:findChild("lb_shuzi")
    self.m_node_effect = self:findChild("Node_Effect")

    self.m_lizi_jindu = self:findChild("lizi_jindu")

    self.m_lb_xingxingshu = self:findChild("lb_xingxingshu")

    local bar_size = self.m_bar_node:getContentSize()
    self.bar_width = bar_size.width
    self.bar_height = bar_size.height
    --初始化tipsView内容
    self:initTipView(data)
    self:initSpine()
    self:updateView(data)
end

--创建tips
function QuestNewTaskProgress:initTipView(data)
    self.m_bet_tipNode = util_createFindView(QUESTNEW_CODE_PATH.QuestNewTaskTipNode, data)
    if self.m_bet_tipNode ~= nil then
        self:addChild(self.m_bet_tipNode, -1)
        self.m_bet_tipNode:setPosition(0, -2)
        self.m_bet_tipNode:setScale(0.98)
    end
end

-- 创建气泡
function QuestNewTaskProgress:initSpine()
    if self.m_bar_node and QUESTNEW_RES_PATH.QuestNewTaskProgressSpine and QUESTNEW_RES_PATH.QuestNewTaskProgressSpine ~= nil then
        local bubble_spine = util_spineCreate(QUESTNEW_RES_PATH.QuestNewTaskProgressSpine, false, true, 1)
        if bubble_spine then
            bubble_spine:setRotation(-90)
            bubble_spine:setPositionY(self.bar_width / 2)
            util_spinePlay(bubble_spine, "idle", true)
            self.bubble_spine = bubble_spine
            bubble_spine:addTo(self.m_bar_node)
        end
    end
end

--刷新数据
function QuestNewTaskProgress:updateView(data)
    if data == nil then
        return
    end

    local function showProcess(curNum, maxNum)
        if curNum > maxNum then
            curNum = maxNum
        end
        local pool = math.floor(curNum / maxNum * 100)
        if self.m_bar_node ~= nil then
            self.m_bar_node:setPercent(pool)
            if self.m_lizi_jindu then
                self.m_lizi_jindu:setContentSize(77, 70 * pool * 0.01)
            end
            if self.bubble_spine then
                local height = self.bar_height * pool / 100
                local height2 = math.abs(height - self.bar_height / 2)
                self.bubble_spine:setPositionX(height)
                local scale = math.sqrt(math.pow(self.bar_height / 2, 2) - math.pow(height2, 2)) / (self.bar_height / 2)
                self.bubble_spine:setScale(scale)
            end

            local clip_node = self:findChild("clip_node")
            if clip_node then
                clip_node:setContentSize(78.54, 78.54 * pool * 0.01)
            end
        end

        if self.m_bar_lb_value ~= nil then
            if maxNum >= 10000 then
                self.m_bar_lb_value:setString(pool .. "%")
            else
                curNum = util_formatCoins(curNum, 3)
                maxNum = util_formatCoins(maxNum, 3)
                self.m_bar_lb_value:setString(curNum .. "/" .. maxNum)
            end
            local width = self.m_bar_lb_value:getContentSize().width
            if width > 60 then
                local scale = math.min(60 / width, 1)
                self.m_bar_lb_value:setScale(scale)
            end
        end
    end

    --显示最近未完成
    showProcess(data.p_process[1], data.p_params[1])

    --第二个条件展示,显示剩余次数
    if #data.p_params > 1 and #data.p_process > 1 then
        local t = data.p_params[2] - data.p_process[2]
        if not self.m_taskSpinNode then
            if self.m_proNode ~= nil then
                local spinNode = util_createFindView(QUESTNEW_CODE_PATH.QuestNewTaskNum, t)
                if spinNode ~= nil then
                    spinNode:setPosition(30, 30)
                    spinNode:setScale(0.5)
                    self.m_proNode:addChild(spinNode)
                    self.m_taskSpinNode = spinNode
                end
            end
        else
            self.m_taskSpinNode:updateView(t)
        end
    end

    --进度完成，显示完成标志
    if data.p_completed or data.p_process[1] >= data.p_params[1] then
        if self.m_bar_lb_value ~= nil then
            self.m_bar_lb_value:setVisible(false)
        end

        if self.m_taskSpinNode ~= nil then
            self.m_taskSpinNode:setVisible(false)
        end
        self:showCompleted(data)
    end

    self.m_lb_xingxingshu:setString("" .. data.p_stars)
end

function QuestNewTaskProgress:addBoostBuffEffect()
    if self.m_node_effect then
        self.m_boost, self.m_boostAct = util_csbCreate(self:getEffectCsbNodePath())
        self.m_node_effect:addChild(self.m_boost)
        util_csbPlayForKey(self.m_boostAct, "idle", true)
    end
end

function QuestNewTaskProgress:removeBoostBuffEffect()
    if self.m_boost then
        self.m_boost:removeFromParent()
        self.m_boost = nil
    end
end

--待机
function QuestNewTaskProgress:showIdle()
    if self.m_isShowCompleted then
        return
    end
    self:runCsbAction("bubble", true, nil, 60)
end
--完成
function QuestNewTaskProgress:showCompleted(data)
    if self.m_isShowCompleted then
        return
    end
    self.m_isShowCompleted = true
    --播放完成动画
    self:runCsbAction(
        "full",
        false,
        function()
            local icon_done = self:findChild("icon_done")
            if icon_done then
                icon_done:setVisible(true)
            end
        end,
        60
    )
end

--默认展示tips
function QuestNewTaskProgress:onEnter()
    self:showIdle()
    local btn_click = self:findChild("btn_click")
    if btn_click then
        self:addClick(btn_click)
    end
    self:addObserverRegister()
end

function QuestNewTaskProgress:addObserverRegister()
    gLobalNoticManager:addObserver(
        self,
        function(target, data)
            self:addBoostBuffEffect()
        end,
        ViewEventType.NOTIFY_QUEST_ADD_PROMOT_EFFECT
    )

    gLobalNoticManager:addObserver(
        self,
        function(target, data)
            self:removeBoostBuffEffect()
        end,
        ViewEventType.NOTIFY_QUEST_REMOVE_PROMOT_EFFECT
    )
end

--打开betTips
function QuestNewTaskProgress:showTipsView(isPlayMusic, defaultShow)
    if self.m_bet_tipNode == nil then
        return
    end

    if not self.m_showBetTips then
        self.m_showBetTips = true
        if isPlayMusic then
            gLobalSoundManager:playSound("QuestNewSounds/QuestNew_qipao.mp3")
        end
        self.m_bet_tipNode:showTipView(
            function()
                if not defaultShow then
                    --3s自动消失
                    performWithDelay(
                        self,
                        function()
                            self:hideTipsView()
                        end,
                        3
                    )
                end
            end
        )
    end
end

function QuestNewTaskProgress:hideTipsView(isFore)
    if self.m_bet_tipNode == nil then
        return
    end
    if isFore then
        self.m_showBetTips = false
        self.m_bet_tipNode:hideFore()
        return
    end
    if self.m_showBetTips then
        self.m_bet_tipNode:hideTipView(
            function()
                self.m_showBetTips = false
            end
        )
    end
end

function QuestNewTaskProgress:clickFunc(sender)
    local name = sender:getName()
    if name == "btn_click" then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_QUEST_TASK_CELL_CHANGE)
    end
end

return QuestNewTaskProgress
