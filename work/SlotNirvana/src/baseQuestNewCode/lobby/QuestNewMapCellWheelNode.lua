
-- QuestNewMapCellWheelNode   地图转盘节点
--
local QuestNewMapCellWheelNode = class("QuestNewMapCellWheelNode", util_require("base.BaseView"))

function QuestNewMapCellWheelNode:getCsbNodePath()
    return QUESTNEW_RES_PATH.QuestNewMapCellWheelNode
end

function QuestNewMapCellWheelNode:initDatas(data)
    self.m_chapterId = data.chapterId
    self:updateCellData()
end

function QuestNewMapCellWheelNode:updateCellData()
    self.m_wheelData = G_GetMgr(ACTIVITY_REF.QuestNew):getChapterWheelDataByChapterId(self.m_chapterId)
end

function QuestNewMapCellWheelNode:initUI()
    self:createCsbNode(self:getCsbNodePath())
    self:initView()
end

function QuestNewMapCellWheelNode:initCsbNodes()
    local btn_click = self:findChild("btn_click")
    if btn_click then
        self:addClick(btn_click)
        btn_click:setSwallowTouches(false)
    end
    self.m_panel_click = btn_click

    self.m_lb_jindu = self:findChild("lb_jindu")
    self.m_bar_wheel_jdt = self:findChild("bar_wheel_jdt")

    self.m_node_progress = self:findChild("node_progress")
    self.m_Node_qipao = self:findChild("node_qipao")

    self.m_sp_wancheng = self:findChild("sp_wancheng")
    
end

function QuestNewMapCellWheelNode:initView()
    if self.m_wheelData == nil then
        return
    end
    self:initStepNode()

    if self.m_wheelData:isUnlock() and not self.m_wheelData:isWillDoWheelUnlock() then
        local wheelType = self.m_wheelData:getType()
        if wheelType == 2 or self.m_wheelData:isWillchangeToLevelThree(true) then
            self:runCsbAction("minor2", true)
        elseif wheelType == 3 or self.m_wheelData:isWillchangeToLevelFour(true)  then
            self:runCsbAction("major", true)
        else
            self:runCsbAction("grand", true)
        end
        if self.m_wheelData:isWheelFinish() then
            self.m_node_progress:setVisible(false)
        end
    else
        self:runCsbAction("minor", true)
        self:createLockAct()
    end

    self.m_sp_wancheng:setVisible(self.m_wheelData:isWheelFinish())

    local needCount ,maxCount,nextLevel = self.m_wheelData:getWheelNextLevelUnlockStars()
    local rata =(maxCount-needCount)/maxCount *100
    self.m_bar_wheel_jdt:setPercent(rata)
    self.m_lb_jindu:setString(""..(maxCount-needCount).."/"..maxCount)
end

function QuestNewMapCellWheelNode:initStepNode()
    local unlock = self.m_wheelData:isUnlock() and not self.m_wheelData:isWillDoWheelUnlock()
    self.m_stepNode = util_createView(QUESTNEW_CODE_PATH.QuestNewMapStepNode, {type = "wheel",index = 8 ,unlock = unlock})
    self:addChild(self.m_stepNode)
end

function QuestNewMapCellWheelNode:createLockAct()
    local unlockAct = util_createAnimation(QUESTNEW_RES_PATH.QuestNewMapCellWheelNode_UnlockAct)
    self:addChild(unlockAct,200,200)
    unlockAct:runCsbAction("idle", true)
    self.m_unlockAct = unlockAct
end

function QuestNewMapCellWheelNode:doUnlockAct(callback)
    self.m_stepNode:doStepAct(function ()
        gLobalSoundManager:playSound(QUESTNEW_RES_PATH.QuestNew_Sound_WheelLevelUp)
        self.m_unlockAct:runCsbAction("jiesuo", false, function ()
            self.m_unlockAct:removeFromParent()
            self:runCsbAction("minor2", true)
            if callback then
                callback()
            end
        end)
    end)
end

function QuestNewMapCellWheelNode:doUnloclLevelThreeAct(callback)
    if self.m_wheelData:isWillchangeToLevelThree(true) then
        gLobalSoundManager:playSound(QUESTNEW_RES_PATH.QuestNew_Sound_WheelLevelUp)
        self.m_wheelData:clearWillchangeToLevelThree(true)
        self:runCsbAction("start1", false,function ()
            self:runCsbAction("major", true)
            if callback then
                callback()
            end
        end)
    end
end

function QuestNewMapCellWheelNode:doUnloclLevelFourAct(callback)
    if self.m_wheelData:isWillchangeToLevelFour(true) then
        gLobalSoundManager:playSound(QUESTNEW_RES_PATH.QuestNew_Sound_WheelLevelUp)
        self.m_wheelData:clearWillchangeToLevelFour(true)
        self:runCsbAction("start2", false,function ()
            self:runCsbAction("grand", true)
            if callback then
                callback()
            end
        end)
    end
end

function QuestNewMapCellWheelNode:onEnter()
    --self:registerHandler()
end

function QuestNewMapCellWheelNode:registerHandler()
    gLobalNoticManager:addObserver(
        self,
        function()
            self:updateView()
        end,
        ViewEventType.NOTIFY_ACTIVITY_QUEST_NEXTSTAGE
    )
end

function QuestNewMapCellWheelNode:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

    if G_GetMgr(ACTIVITY_REF.QuestNew):isDoingMapCheckLogic() then
        return
    end
    -- local willDoStep4 = G_GetMgr(ACTIVITY_REF.QuestNew):getGuide():isGuideGoing("enterQuestMap_4")
    -- if willDoStep4 then
    --     gLobalNoticManager:postNotification(ViewEventType.NOTIFY_NEWQUEST_STARLAYER_CLOSE)
    -- end
    
    if self.m_clicked then
        return
    end
    self.m_clicked = true
    performWithDelay(
        self,
        function()
            self.m_clicked = false
        end,
        0.5
    )
    if name == "btn_click" then
        self:onTouchClick(true)
    end
end

function QuestNewMapCellWheelNode:onTouchClick(isClick)
    if self.m_wheelData:isUnlock() and not self.m_wheelData:isWheelFinish() then
        local wheelType = self.m_wheelData:getType()
        if wheelType == 4 then
            G_GetMgr(ACTIVITY_REF.QuestNew):showWheelView(self.m_chapterId)
        else
            local chapterId = self.m_chapterId
            G_GetMgr(ACTIVITY_REF.QuestNew):showTipView({chapterId = chapterId,type = 1,callBack = function ()
                G_GetMgr(ACTIVITY_REF.QuestNew):showWheelView(chapterId)
            end})
        end
    elseif not self.m_wheelData:isUnlock() then
        self:addBubble()
        self.m_bubbleNode:setType(1)
        self.m_bubbleNode:doShowOrHide()
    elseif self.m_wheelData:isWheelFinish() then
        self:addBubble()
        self.m_bubbleNode:setType(2)
        self.m_bubbleNode:doShowOrHide()
    end
end

function QuestNewMapCellWheelNode:addBubble()
    if not self.m_bubbleNode then
        self.m_bubbleNode = util_createView(QUESTNEW_CODE_PATH.QuestNewMapWheelBubbleNode)
        self.m_Node_qipao:addChild(self.m_bubbleNode,2000)
    end
end

return QuestNewMapCellWheelNode
