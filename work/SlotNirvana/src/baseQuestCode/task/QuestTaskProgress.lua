-- Created by jfwang on 2019-05-21.
-- QuestTaskProgress 基类
--
local QuestTaskProgress = class("QuestTaskProgress", util_require("base.BaseView"))

function QuestTaskProgress:getCsbNodePath()
    return QUEST_RES_PATH.QuestTaskProgress
end

function QuestTaskProgress:getEffectCsbNodePath()
    return QUEST_RES_PATH.QuestTaskProgressEffect
end

function QuestTaskProgress:initUI(data)
    self:createCsbNode(self:getCsbNodePath())

    self.m_proNode = self:findChild("jindutiao")
    self.m_proNode:setVisible(true)

    self.m_bar_node = self:findChild("LoadingBar_1")
    self.m_bar_lb_value = self:findChild("BitmapFontLabel_1")
    self.m_node_effect = self:findChild("Node_Effect")

    local bar_size = self.m_bar_node:getContentSize()
    self.bar_width = bar_size.width
    self.bar_height = bar_size.height
    --初始化tipsView内容
    self:initTipView(data)
    self:initSpine()
    self:updateView(data)
end

--创建tips
function QuestTaskProgress:initTipView(data)
    self.m_bet_tipNode = util_createFindView(QUEST_CODE_PATH.QuestTaskTipNode, data)
    if self.m_bet_tipNode ~= nil then
        self:addChild(self.m_bet_tipNode, -1)
        self.m_bet_tipNode:setPosition(0, -2)
        self.m_bet_tipNode:setScale(0.98)
    end
end

-- 创建气泡
function QuestTaskProgress:initSpine()
    if self.m_bar_node and QUEST_RES_PATH.QuestTaskProgressSpine and QUEST_RES_PATH.QuestTaskProgressSpine ~= nil then
        local bubble_spine = util_spineCreate(QUEST_RES_PATH.QuestTaskProgressSpine, false, true, 1)
        if bubble_spine then
            bubble_spine:setRotation(-90)
            bubble_spine:setPositionY(self.bar_width / 2)
            util_spinePlay(bubble_spine, "idle_wu", true)
            self.bubble_spine = bubble_spine
            bubble_spine:addTo(self.m_bar_node)
        end
    end
end

--刷新数据
function QuestTaskProgress:updateView(data)
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

    --进度完成，显示完成标志
    if data.p_completed or data.p_process[1] >= data.p_params[1] then
        if self.m_bar_lb_value ~= nil then
            self.m_bar_lb_value:setVisible(false)
        end

        self:showCompleted(data)
    end
end

--待机
function QuestTaskProgress:showIdle()
    if self.m_isShowCompleted then
        return
    end
    self:runCsbAction("bubble", true, nil, 60)
end
--完成
function QuestTaskProgress:showCompleted(data)
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
function QuestTaskProgress:onEnter()
    self:showIdle()
    local btn_click = self:findChild("btn_click")
    if btn_click then
        self:addClick(btn_click)
    end
end

--打开betTips
function QuestTaskProgress:showTipsView(defaultShow)
    if self.m_bet_tipNode == nil then
        return
    end

    if not self.m_showBetTips then
        self.m_showBetTips = true

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

function QuestTaskProgress:hideTipsView(isFore)
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

function QuestTaskProgress:clickFunc(sender)
    local name = sender:getName()
    if name == "btn_click" then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_QUEST_TASK_CELL_CHANGE)
    end
end

return QuestTaskProgress
