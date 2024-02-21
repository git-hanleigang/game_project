-- quest主界面 quest挑战活动入口
-- FIX IOS 150 v465

local BaseView = util_require("base.BaseView")
local Activity_QuestNewRushEntryBase = class("Activity_QuestNewRushEntryBase", BaseView)

-- 任务类型
local QuestNewRush_RushType = {
    STAR = "1001", -- 累积星星完成任务
    STAGE = "1002", -- 累积过关完成任务
    CHAPTER = "1003" -- 累积章节完成任务
}

function Activity_QuestNewRushEntryBase:initUI(_bUpdate)
    self.m_data = G_GetMgr(ACTIVITY_REF.QuestNewRush):getRunningData()
    
    BaseView.initUI(self)

    self.m_csbNode:setScale(1.6)
    self:runCsbAction("idle", true)

    self:initPreProgressUI()
    if _bUpdate then
        self:updateProgressUI()
    end
end

function Activity_QuestNewRushEntryBase:getCsbName()
   
end

-- 显示之前的 进度信息
function Activity_QuestNewRushEntryBase:initPreProgressUI()
    local processBar = self:findChild("process")
    local lbProg = self:findChild("lb_number")

    local rushType = G_GetMgr(ACTIVITY_REF.QuestNewRush):getRushType()
    if rushType == QuestNewRush_RushType.STAGE or rushType == QuestNewRush_RushType.CHAPTER then
        -- 不需要显示进度条 如果有 隐藏
        if processBar then
            processBar:setVisible(false)
        end
        if lbProg then
            lbProg:setVisible(false)
        end
        return
    end

    local preProg, curProg = self:getPreAndCurProg()
    processBar:setPercent(preProg)
    lbProg:setString(preProg .. "%")
end

-- 初始化进度条
function Activity_QuestNewRushEntryBase:updateProgressUI()
    if not G_GetMgr(ACTIVITY_REF.QuestNewRush):getRunningData() then
        return
    end
    local rushType = G_GetMgr(ACTIVITY_REF.QuestNewRush):getRushType()
    if rushType == QuestNewRush_RushType.STAR then
        self:playStarAction()
    elseif rushType == QuestNewRush_RushType.STAGE or rushType == QuestNewRush_RushType.CHAPTER then
        -- 没有进度条 不需要刷新
        self:popOnComplete()
    end
end

-- 播放获得星星动画
function Activity_QuestNewRushEntryBase:playStarAction()
    if not G_GetMgr(ACTIVITY_REF.QuestNewRush):getRunningData() then
        return
    end
    local processBar = self:findChild("process")
    local lbProg = self:findChild("lb_number")

    local preProg, curProg = self:getPreAndCurProg()
    local addStarNum = G_GetMgr(ACTIVITY_REF.QuestNewRush):getAddStarNum()
    if addStarNum <= 0 then
        -- 没有增加 也要重刷 有可能是重置
        processBar:setPercent(curProg)
        lbProg:setString(curProg .. "%")
        return
    end

    -- 1. 播放动画
    local lbAddStar = self:findChild("BitmapFontLabel_1")
    if lbAddStar then
        lbAddStar:setString("+" .. addStarNum)
    end

    -- 2. 进度条走
    local tempProg = preProg
    local step = 1
    local bPop = G_GetMgr(ACTIVITY_REF.QuestNewRush):checkMainViewPopActPanel()
    if not bPop then
        G_GetMgr(ACTIVITY_REF.QuestNewRush):resetOldData()
    end
    self.m_csbAct:gotoFrameAndPause(0)
    util_nextFrameFunc(
        function()
            self:runCsbAction(
                "actionframe",
                false,
                function()
                    -- 3. 打开面板
                    if bPop then
                        if G_GetMgr(ACTIVITY_REF.QuestNew):isDoingMapCheckLogic() then
                            G_GetMgr(ACTIVITY_REF.QuestNew):setWillAutoShowRushLayer(true)
                        else
                            G_GetMgr(ACTIVITY_REF.QuestNewRush):showMainView()
                        end
                    end
                    self:runCsbAction("idle", true, nil, 60)
                end,
                60
            )
        end,
        0
    )
    local delayTime = (400 - 260) / 60
    performWithDelay(
        self,
        function()
            self.m_schedule =
                schedule(
                self,
                function()
                    tempProg = tempProg + step
                    step = step + 1
                    if tempProg > curProg then
                        processBar:setPercent(curProg)
                        lbProg:setString(curProg .. "%")

                        self:clearScheduler()
                        return
                    end
                    processBar:setPercent(tempProg)
                    lbProg:setString(tempProg .. "%")
                end,
                0.2
            )
        end,
        delayTime
    )
end

-- 完成阶段任务 弹出面板
function Activity_QuestNewRushEntryBase:popOnComplete()
    if not G_GetMgr(ACTIVITY_REF.QuestNewRush):getRunningData() then
        return
    end
    local bPop = G_GetMgr(ACTIVITY_REF.QuestNewRush):checkMainViewPopActPanel()
    if not bPop then
        G_GetMgr(ACTIVITY_REF.QuestNewRush):resetOldData()
    else
        if G_GetMgr(ACTIVITY_REF.QuestNew):isDoingMapCheckLogic() then
            G_GetMgr(ACTIVITY_REF.QuestNew):setWillAutoShowRushLayer(true)
        else
            util_nextFrameFunc(
                function()
                    G_GetMgr(ACTIVITY_REF.QuestNewRush):showMainView()
                end,
                0
            )
        end
    end
    self:runCsbAction("idle", true, nil, 60)
end

function Activity_QuestNewRushEntryBase:onEnter()
end

function Activity_QuestNewRushEntryBase:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()
    gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
    if name == "btn_touch" then
        G_GetMgr(ACTIVITY_REF.QuestNewRush):showMainView()
    end
end

-- 清楚定时器
function Activity_QuestNewRushEntryBase:clearScheduler()
    if self.m_schedule then
        self:stopAction(self.m_schedule)
        self.m_schedule = nil
    end
end

-- 获取上一次 和 这次的 进度
function Activity_QuestNewRushEntryBase:getPreAndCurProg()
    local actData = G_GetMgr(ACTIVITY_REF.QuestNewRush):getRunningData()
    if not actData then
        return
    end
    local preStarNum = actData:getPreProcess()
    local curStarNum = actData:getCurProcess()
    local maxStarNum = actData:getRushCompleteCondition()
    maxStarNum = math.max(maxStarNum, 1)
    local preProg = math.floor(preStarNum / maxStarNum * 100)
    local curProg = math.floor(curStarNum / maxStarNum * 100)

    return math.min(preProg, 100), math.min(curProg, 100)
end

-- 获取 特效所在星星的 世界坐标
function Activity_QuestNewRushEntryBase:getEfStarWorldPos()
    local nodeStar = self:findChild("node_star")
    local worldPos = nodeStar:convertToWorldSpace(cc.p(0, 0))

    return worldPos
end

return Activity_QuestNewRushEntryBase
