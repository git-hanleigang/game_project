--[[
Author: cxc
Date: 2022-03-23 17:57:46
LastEditTime: 2022-03-23 17:58:57
LastEditors: cxc
Description: 3日行为付费聚合活动   阶段节点
FilePath: /SlotNirvana/src/activities/Activity_WildChallenge/views/phaseView/WildChallengeActBasePhaseNode.lua
--]]
local WildChallengeActBasePhaseNode = class("WildChallengeActBasePhaseNode", BaseView)
local Config = require("activities.Activity_WildChallenge.config.WildChallengeConfig")

function WildChallengeActBasePhaseNode:initDatas(_idx, _phaseData, _curOpenIdx)
    self.m_bReqing = false
    self.m_idx = _idx
    self.m_curOpenIdx = _curOpenIdx
    self.m_phaseData = _phaseData
end

function WildChallengeActBasePhaseNode:updateData(_phaseData, _curOpenIdx)
    self.m_phaseData = _phaseData
    self.m_curOpenIdx = _curOpenIdx
end

function WildChallengeActBasePhaseNode:initCsbNodes()
    self.m_nodeContent = self:findChild("node_content")
    self.m_nodeLock = self:findChild("node_lock")
    self.m_nodeMissionTip = self:findChild("node_mission")
    self.m_btn = self:findChild("btn_go")
    self.m_layoutTouch = self:findChild("layout_touch")
    self.m_layoutTouch:setSwallowTouches(false)
    self:addClick(self.m_layoutTouch)

    self.m_nodeNpc = self:findChild("node_npc") -- 新增
end

function WildChallengeActBasePhaseNode:getTaskNpcWorldPos()
    if self.m_nodeNpc then
        local wPos = self.m_nodeNpc:getParent():convertToWorldSpace(cc.p(self.m_nodeNpc:getPosition()))
        return wPos
    end
    return nil
end

function WildChallengeActBasePhaseNode:getResLockPath()
    return ""
end
function WildChallengeActBasePhaseNode:getCodeMissionTipPath()
    return ""
end

function WildChallengeActBasePhaseNode:checkIsEndPhaseNode()
    return false
end

function WildChallengeActBasePhaseNode:initUI()
    WildChallengeActBasePhaseNode.super.initUI(self)

    -- 道具
    self:initItemsUI()
    -- 锁
    self:initLockUI()
    -- 任务tip
    self:initMissionTipUI()
    -- 状态
    self:initState()
end

-- 道具
function WildChallengeActBasePhaseNode:initItemsUI()
    if self:checkIsEndPhaseNode() then
        -- 最后一个 特殊不用塞道具
        return
    end

    local itemList = self.m_phaseData:getItemList()
    if #itemList == 1 then
        local parent = self:findChild("node_reward3")
        local itemNode = gLobalItemManager:addPropNodeList(itemList, ITEM_SIZE_TYPE.REWARD, 1)
        parent:addChild(itemNode)
        util_setCascadeOpacityEnabledRescursion(parent, true)
        return
    end

    for i = 1, #itemList do
        local parent = self:findChild("node_reward" .. i)
        local itemData = itemList[i]
        if parent and itemData then
            local itemNode = gLobalItemManager:createRewardNode(itemData, ITEM_SIZE_TYPE.REWARD, 1)
            parent:addChild(itemNode)
            util_setCascadeOpacityEnabledRescursion(parent, true)
        end
    end
end

-- 锁
function WildChallengeActBasePhaseNode:initLockUI()
    local path = self:getResLockPath()
    local view = util_createAnimation(path)
    self.m_nodeLock:addChild(view)
    self.m_aniLockObj = view
end

-- 任务tip
function WildChallengeActBasePhaseNode:initMissionTipUI()
    local path = self:getCodeMissionTipPath()
    local view = util_createView(path, self.m_phaseData, self:checkIsEndPhaseNode())
    self.m_nodeMissionTip:addChild(view)
    self.m_nodeTipObj = view
end

-- 状态 任务状态 0初始化 1开启 2完成 3已领取
function WildChallengeActBasePhaseNode:initState()
    local status = self.m_phaseData:getStatus()
    if status == 0 then
        self:updateState(Config.TASK_STATE.LOCK)
    elseif status == 1 then
        self:updateState(Config.TASK_STATE.UNDONE)
    elseif status == 2 then
        -- 完成未领取一上来播放动画
        self:updateState(Config.TASK_STATE.CAN_COLLECT)
    elseif status == 3 then
        self:updateState(Config.TASK_STATE.COLLECTED)
    end
end

function WildChallengeActBasePhaseNode:updateState(_state, _cb)
    self.m_state = _state

    local actName = ""
    local bLoop = false
    local callFunc = function()end
    if _state == Config.TASK_STATE.LOCK then
        -- 未解锁
        actName = "lock"
        self.m_aniLockObj:playAction("idle")
        util_setCascadeColorEnabledRescursion(self.m_nodeContent, true)
    elseif _state == Config.TASK_STATE.UNLOCK then
        -- 解锁
        actName = "unlock"
        callFunc = function()
            -- 解锁后 (判断完成还是 未完成)
            self:initState()
        end
        self.m_aniLockObj:playAction("open")
    elseif _state == Config.TASK_STATE.UNDONE then
        -- 解锁但不可领 任务未完成
        actName = "open"
        bLoop = true
    elseif _state == Config.TASK_STATE.CAN_COLLECT then
        -- 任务完成 可以领取
        actName = "open"
        bLoop = true
    elseif _state == Config.TASK_STATE.COLLECTED then
        -- 已领取
        actName = (self.m_curOpenIdx - self.m_idx) == 1 and "idleCat" or "collected"
        bLoop = true
        self.m_nodeTipObj:setVisible(false)
        self.m_btn:setVisible(false)
    elseif _state == Config.TASK_STATE.GO_COLLECT then
        -- 起跳
        actName = (self.m_curOpenIdx - self.m_idx) == 1 and "luodi" or "qitiao"
        callFunc = function()
            if _cb then
                _cb()
            end
            self:updateState(Config.TASK_STATE.COLLECTED)
        end
        self.m_nodeTipObj:setVisible(false)
        self.m_btn:setVisible(false)
    end

    self:runCsbAction(actName, bLoop, callFunc, 60)
    self:runSpineAction(_state)
    self:updateLockVisible()
    self:updateMissionTipVisible()
    self:updateBtnVisible()
end

function WildChallengeActBasePhaseNode:runSpineAction(_state)
end

-- 更新锁 显示状态
function WildChallengeActBasePhaseNode:updateLockVisible()
    local bVisible = false
    if self.m_state == Config.TASK_STATE.LOCK or self.m_state == Config.TASK_STATE.UNLOCK then
        bVisible = true
    end
    self.m_aniLockObj:setVisible(bVisible)
end

-- 更新任务提示 显示状态
function WildChallengeActBasePhaseNode:updateMissionTipVisible()
    local bVisible = true
    if self.m_state == Config.TASK_STATE.GO_COLLECT or self.m_state == Config.TASK_STATE.COLLECTED then
        bVisible = false
    end
    self.m_nodeTipObj:setVisible(bVisible)
end

-- 更新按钮 显示状态
function WildChallengeActBasePhaseNode:updateBtnVisible()
    local bVisible = true
    if self.m_state == Config.TASK_STATE.GO_COLLECT or self.m_state == Config.TASK_STATE.COLLECTED then
        bVisible = false
    end
    self.m_btn:setVisible(bVisible)

    local tipStr = gLobalLanguageChangeManager:getStringByKey("WildChallengeActBasePhaseNode_BTN_LOCKED") or "LOCKED"
    if self.m_state ~= Config.TASK_STATE.LOCK then
        tipStr = self.m_phaseData:getBtnDescStr()
    end
    self:setButtonLabelContent("btn_go", tipStr)
end

function WildChallengeActBasePhaseNode:clickFunc(sender)
    local name = sender:getName()
    
    if name == "btn_go" then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        if self.m_state == Config.TASK_STATE.UNDONE then
            local jumpTo = function()
                local key = self.m_phaseData:getNavigateKey()
                -- 竖版关卡显示横版商城有问题。 关闭界面回调回来弹商城
                util_nextFrameFunc(function()
                    -- 下一帧横竖屏旋转回来弹其他功能
                    local view = G_GetMgr(G_REF.JumpTo):jumpToFeature(key)
                end)
            end
            gLobalNoticManager:postNotification(Config.EVENT_NAME.WILD_CHALLENGE_COLSE_MIAN_LAYER, jumpTo)
        elseif self.m_state == Config.TASK_STATE.CAN_COLLECT and not self.m_bReqing then
            self.m_bReqing = true
            gLobalNoticManager:addObserver(self, "collectFaildEvt", Config.EVENT_NAME.WILD_CHALLENGE_COLLECT_FAILD) -- 任务领取失败
            G_GetMgr(ACTIVITY_REF.WildChallenge):sendCollectReq(self.m_idx)
        end
    end
end

-- 获取猫节点 世界坐标
function WildChallengeActBasePhaseNode:getCatNodePosW()
    local nodeCat = self:findChild("node_cat")
    if not nodeCat then
        return self:convertToWorldSpaceAR(cc.p(0, 0))
    end

    local posX = nodeCat:getPositionX()
    local posY = nodeCat:getPositionY()
    return self:convertToWorldSpaceAR(cc.p(posX, posY))
end

-- 检查 该 任务是否可以自动领取 (非 free 类型的自动领) _bForce（可领取就领）
function WildChallengeActBasePhaseNode:checkAutoCollect(_bForce)
    if self.m_bReqing then
        -- 请求中不监测了
        return
    end

    if self.m_state ~= Config.TASK_STATE.CAN_COLLECT then
        return 
    end

    if self.m_phaseData:getProgressLimit() > 0 or _bForce then
        gLobalNoticManager:addObserver(self, "collectFaildEvt", Config.EVENT_NAME.WILD_CHALLENGE_COLLECT_FAILD) -- 任务领取失败
        G_GetMgr(ACTIVITY_REF.WildChallenge):sendCollectReq(self.m_idx)
        self.m_bReqing = true
        return true
    end
end

-- 任务领取失败
function WildChallengeActBasePhaseNode:collectFaildEvt(_idx)
    self.m_bReqing = false
    gLobalNoticManager:removeObserver(self, Config.EVENT_NAME.WILD_CHALLENGE_COLLECT_FAILD)
end

return WildChallengeActBasePhaseNode