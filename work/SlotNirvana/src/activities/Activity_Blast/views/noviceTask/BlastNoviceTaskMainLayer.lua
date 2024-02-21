--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-05-27 14:20:15
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-05-27 17:15:51
FilePath: /SlotNirvana/src/activities/Activity_Blast/views/noviceTask/BlastNoviceTaskMainLayer.lua
Description: 新手blast 任务 主界面
--]]
local BlastNoviceTaskMainLayer = class("BlastNoviceTaskMainLayer", BaseLayer)

function BlastNoviceTaskMainLayer:initDatas()
    BlastNoviceTaskMainLayer.super.initDatas(self)

    self.m_data = G_GetMgr(ACTIVITY_REF.BlastNoviceTask):getData()
    self.m_bastActData = G_GetMgr(ACTIVITY_REF.Blast):getData()

    self.m_curMissionData = self.m_data:getCurMissionData()

    self.m_bCompletedAndReward = false -- 领奖了 关闭的时候界面的时候监测下blast切章节

    self:setPauseSlotsEnabled(true)
    self:setName("BlastNoviceTaskMainLayer")
    self:setLandscapeCsbName("Activity/BlastBlossomTask/csb/blastMission_mainLayer.csb")
end

function BlastNoviceTaskMainLayer:initCsbNodes()
    self.m_lbLeftTime = self:findChild("lb_time")

    -- 按钮文本
    self:setButtonLabelContent("btn_play", "PLAY NOW!")
    self:setButtonLabelContent("btn_collect", "COLLECT")
end

function BlastNoviceTaskMainLayer:initView()
    --初始化标题
    self:initTitleUI()
    -- 时间
    self:initTimeUI()
    --初始化任务奖励
    self:initTaskRewardUI()
    -- 气泡
    self:initBubbleUI()
    --进度条 进度
    self:updateProgUI()
    -- 更新进度条奖励显隐
    self:updatePhaseInfoVisibleUI()
    -- 更新当前 进度 按钮状态
    self:updateBtnState()
    -- 动画
    self:checkPlayAnimationEf()

    self:addClickSound({"btn_x"}, SOUND_ENUM.SOUND_HIDE_VIEW)
end

--初始化标题
function BlastNoviceTaskMainLayer:initTitleUI()
    local parent = self:findChild("node_title")
    local titleView = util_createView("activities.Activity_Blast.views.noviceTask.BlastNoviceTaskTitleUI", self.m_data)
    parent:addChild(titleView)
    self.m_titleView = titleView
end

--初始化任务奖励
function BlastNoviceTaskMainLayer:initTaskRewardUI()
    -- 大图
    local displayRewardList = {}
    local missionList = self.m_data:getMissionList()
    table.walk(missionList, function(_missionData, _idx)
        -- 进度条旁阶段任务奖励——通用道具
        self:addProgNormalItemNode(_missionData, _idx)
        -- 进度条旁阶段任务奖励-金币
        self:addProgCoinsNode(_missionData, _idx)
        -- 合并 显示奖励
        table.insertto(displayRewardList, _missionData:getDisplayRewardList())
    end)

    for i=1, math.min(#displayRewardList, 6) do
        local shopItem = displayRewardList[i]
        local itemNode = gLobalItemManager:createRewardNode(shopItem, ITEM_SIZE_TYPE.REWARD)
        if itemNode.getLabelStrAndHideLable then
            itemNode:getLabelStrAndHideLable(true)
        end
        self:findChild("node_" .. i):addChild(itemNode)
    end
end
-- 进度条旁阶段任务奖励——通用道具
function BlastNoviceTaskMainLayer:addProgNormalItemNode(_missionData, _idx)
    if _idx > 3 then
        return
    end
    local nodeName = "node_mr" .. _idx
    local rewardList = _missionData:getRewardList()
    local coinSG = self:findChild(nodeName .. "_ef_sao")
    if coinSG then
        coinSG:setVisible(false)
    end
    for i=1, math.min(#rewardList, 3) do
        local parent = self:findChild(nodeName .. "_" .. i + 1)
        local shopItem = rewardList[i]
        local itemNode = gLobalItemManager:createRewardNode(shopItem, ITEM_SIZE_TYPE.REWARD)
        if itemNode.getLabelStrAndHideLable then
            itemNode:getLabelStrAndHideLable(true)
        end
        parent:addChild(itemNode)
    end
end
-- 进度条旁阶段任务奖励-金币
function BlastNoviceTaskMainLayer:addProgCoinsNode(_missionData, _idx)
    if _idx > 3 then
        return
    end

    local coins = _missionData:getCoins()
    if coins <= 0 then
        return
    end
    local nodeName = "node_mr" .. _idx
    local coinSG = self:findChild(nodeName .. "_ef_sao")
    if coinSG then
        coinSG:setVisible(true)
    end

    local parent = self:findChild(nodeName .. "_" .. 1)
    local shopItem = gLobalItemManager:createLocalItemData("Coins", coins)
    local itemNode = gLobalItemManager:createRewardNode(shopItem, ITEM_SIZE_TYPE.REWARD)
    if itemNode.getLabelStrAndHideLable then
        itemNode:getLabelStrAndHideLable(true)
    end
    parent:addChild(itemNode)
end


--初始化进度条 进度
function BlastNoviceTaskMainLayer:updateProgUI()
    local missionData = self.m_curMissionData

    local processMax = missionData:getProcessMax()
    local curProcess = missionData:getCurProcess()
    local percent = math.floor(curProcess / processMax * 100)
    local progUI = self:findChild("prg_main")
    progUI:setPercent(percent)

    local lbProg = self:findChild("lb_prg")
    if missionData:checkCompleted() then
        lbProg:setString("COMPLETED")
    else
        if missionData:getMissionType() == "WIN_COINS" then
            lbProg:setString(string.format("%s/%s", util_formatCoins(tonumber(curProcess), 3), util_formatCoins(tonumber(processMax), 3)))
        else
            lbProg:setString(string.format("%s/%s", curProcess, processMax))
        end
    end 

    -- 任务描述
    local lbDesc = self:findChild("lb_dec")
    local desc = missionData:getContent()
    if string.find(desc, "%%s") then
        if missionData:getMissionType() == "WIN_COINS" then
            desc = string.format(desc, util_formatCoins(tonumber(processMax), 3))
        else
            desc = string.format(desc, processMax)
        end
    end
    lbDesc:setString(desc)
end

-- 气泡
function BlastNoviceTaskMainLayer:initBubbleUI()
    local parent = self:findChild("node_qipao")
    local bubbleView = util_createView("activities.Activity_Blast.views.noviceTask.BlastNoviceTaskBubbleUI", self.m_data)
    parent:addChild(bubbleView)
    self.m_bubbleView = bubbleView
end

-- 时间
function BlastNoviceTaskMainLayer:initTimeUI()
    self.m_scheduler = schedule(self, handler(self, self.onUpdateTimeUISec), 1)
    self:onUpdateTimeUISec()
end
function BlastNoviceTaskMainLayer:onUpdateTimeUISec()
    local expireAt = self.m_bastActData:getExpireAt()
    local timeStr, bOver = util_daysdemaining(expireAt, true)
    self.m_lbLeftTime:setString(timeStr)
    if bOver then
        self:clearScheduler()
    end
end

-- 阶段任务 显隐
function BlastNoviceTaskMainLayer:updatePhaseInfoVisibleUI()
    local curPhaseIdx = self.m_data:getCurPhaseIdx()

    for i=1,3 do
        local spTaskImg = self:findChild("sp_m" .. i) --阶段1任务的描述图标
        local nodeTaskReward = self:findChild("node_mr" .. i) --阶段1任务的奖励图标
        spTaskImg:setVisible(curPhaseIdx == i)
        nodeTaskReward:setVisible(curPhaseIdx == i)
    end

    -- 所有任务是否完成
    local bAllOver = false
    if self.m_curMissionData:checkCompleted() and self.m_curMissionData:checkHadSendReward() then
        bAllOver = true
    end
    --用于显示下个任务的预告，没有下个任务则不显示
    local nodeNextTaskTip = self:findChild("node_complete1")
    nodeNextTaskTip:setVisible(bAllOver)
    if bAllOver then
        local lbOverTitle = self:findChild("lb_nextmission")
        local lbOverDesc = self:findChild("lb_next_time")
        lbOverTitle:setString("Congratulations!")
        lbOverDesc:setString("All missions completed.")
    end
    -- 进度条
    local nodeProg = self:findChild("node_progress")
    nodeProg:setVisible(not bAllOver)
    local nodeProgDesc = self:findChild("node_firstmission")
    nodeProgDesc:setVisible(not bAllOver)
    -- 时间
    local nodeTime = self:findChild("node_time")
    nodeTime:setVisible(not bAllOver)
end

-- 更新当前 进度 按钮状态
function BlastNoviceTaskMainLayer:updateBtnState()
    local btnPlay = self:findChild("btn_play")
    local btnCollect = self:findChild("btn_collect")

    local missionData = self.m_curMissionData
    local bCompleted = missionData:checkCompleted()
    btnPlay:setVisible(not bCompleted)
    btnCollect:setVisible(bCompleted and not missionData:checkHadSendReward())
end

-- 动画
function BlastNoviceTaskMainLayer:checkPlayAnimationEf()
    local actName = "idle2"
    local coins = self.m_curMissionData:getCoins()
    if coins > 0 then
        actName = "idle1"
    end
    self:runCsbAction(actName, true)
end

function BlastNoviceTaskMainLayer:clickFunc(_sender)
    local senderName = _sender:getName()

    if senderName == "btn_x" then
        if self.m_curMissionData:checkCompleted() and not self.m_curMissionData:checkHadSendReward() then
            -- 完成未 领奖 去领奖
            self:sendCollectReq()
            return
        end
        self:closeUI()
    elseif senderName == "btn_play" then
        local cb = function()
            self:setVisible(false)
            G_GetMgr(ACTIVITY_REF.Blast):showMainLayer()
        end
        self:closeUI(cb)
    elseif senderName == "btn_collect" then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        self:sendCollectReq()
    elseif senderName == "btn_info" then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        self.m_bubbleView:switchBubbleVisible()
    end
end

function BlastNoviceTaskMainLayer:closeUI(_cb)
    local cb = function()
        if _cb then
            _cb()
        end
        if self.m_bCompletedAndReward then
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_TASK_VIEW_CLOSE)
        else
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_TASK_VIEW_CLOSE_NORMAL)
        end
    end
    BlastNoviceTaskMainLayer.super.closeUI(self, cb)
end

-- 清楚定时器
function BlastNoviceTaskMainLayer:clearScheduler()
    if not self.m_scheduler then
        return
    end
    self:stopAction(self.m_scheduler)
    self.m_scheduler = nil
end

-- 请求领奖
function BlastNoviceTaskMainLayer:sendCollectReq()
    if self.m_bSendColReqing then
        -- 领奖中
        return
    end
    self.m_bubbleView:hideBubbleTip()
    self.m_bSendColReqing = true
    G_GetMgr(ACTIVITY_REF.BlastNoviceTask):sendNoviceTaskCollectReq(self.m_curMissionData:getActivityType(), self.m_curMissionData:getPhase())
end

-- 事件 领奖成功
function BlastNoviceTaskMainLayer:onReciveCollectSuccessEvt()
    self.m_bSendColReqing = false
    self.m_bCompletedAndReward = true -- 领奖了 关闭的时候界面的时候监测下blast切章节
    self:runCsbAction("start3", nil, function()
        
        self:updateUI()
        self:checkPlayAnimationEf()
    end, 60)
    G_GetMgr(ACTIVITY_REF.BlastNoviceTask):showRewardLayer(self.m_curMissionData)
end
-- 事件 领奖失败
function BlastNoviceTaskMainLayer:onReciveCollectFaildEvt()
    self.m_bSendColReqing = false
end
-- 事件 活动结束
function BlastNoviceTaskMainLayer:onTimeOutEvt(_params)
    if _params and _params.name == ACTIVITY_REF.Blast then
        self:closeUI()
    end
end
function BlastNoviceTaskMainLayer:updateUI()
    self.m_curMissionData = self.m_data:getCurMissionData()

    self.m_titleView:updateUI()
    self.m_bubbleView:updateUI()

    self:updateProgUI()
    self:updatePhaseInfoVisibleUI()
    self:updateBtnState()
end
function BlastNoviceTaskMainLayer:registerListener()
    BlastNoviceTaskMainLayer.super.registerListener(self)

    gLobalNoticManager:addObserver(self, "onReciveCollectSuccessEvt", ViewEventType.NOTIFY_ACTIVITY_TASK_COLLECT_SUCCESS)
    gLobalNoticManager:addObserver(self, "onReciveCollectFaildEvt", ViewEventType.NOTIFY_ACTIVITY_TASK_COLLECT_FAILED)
    gLobalNoticManager:addObserver(self, "onTimeOutEvt", ViewEventType.NOTIFY_ACTIVITY_TIMEOUT)
end

return BlastNoviceTaskMainLayer