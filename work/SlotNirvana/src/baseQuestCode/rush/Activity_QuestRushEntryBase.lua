-- quest主界面 quest挑战活动入口
-- FIX IOS 150 v465

local BaseView = util_require("base.BaseView")
local Activity_QuestRushEntryBase = class("Activity_QuestRushEntryBase", BaseView)

function Activity_QuestRushEntryBase:initUI(_bUpdate)
    self.m_data = G_GetMgr(ACTIVITY_REF.QuestRush):getRunningData()
    self.m_config = G_GetMgr(ACTIVITY_REF.QuestRush):getConfig()

    BaseView.initUI(self)

    self.m_csbNode:setScale(1.6)
    self:runCsbAction("idle", true)

    self:initPreProgressUI()
    if _bUpdate then
        self:updateProgressUI()
    end
end

function Activity_QuestRushEntryBase:getCsbName()
    local theme_name = self.m_data:getThemeName()
    local themeConfig = self.m_config.RESOURCE[theme_name]
    if not themeConfig then
        printError("quest挑战 主题名不明确")
        return
    end

    local rushType = G_GetMgr(ACTIVITY_REF.QuestRush):getRushType()
    local csbPath = themeConfig[rushType].ENTRY
    if not csbPath then
        printError("quest挑战 活动入口资源没配置 " .. theme_name)
    end
    return csbPath
end

-- 显示之前的 进度信息
function Activity_QuestRushEntryBase:initPreProgressUI()
    local processBar = self:findChild("process")
    local lbProg = self:findChild("lb_number")

    local rushType = G_GetMgr(ACTIVITY_REF.QuestRush):getRushType()
    if rushType == self.m_config.RUSH_TYPE.STAGE or rushType == self.m_config.RUSH_TYPE.CHAPTER then
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
function Activity_QuestRushEntryBase:updateProgressUI()
    if not G_GetMgr(ACTIVITY_REF.QuestRush):getRunningData() then
        return
    end
    local rushType = G_GetMgr(ACTIVITY_REF.QuestRush):getRushType()
    if rushType == self.m_config.RUSH_TYPE.STAR then
        self:playStarAction()
    elseif rushType == self.m_config.RUSH_TYPE.STAGE or rushType == self.m_config.RUSH_TYPE.CHAPTER then
        -- 没有进度条 不需要刷新
        self:popOnComplete()
    end
end

-- 播放获得星星动画
function Activity_QuestRushEntryBase:playStarAction()
    if not G_GetMgr(ACTIVITY_REF.QuestRush):getRunningData() then
        return
    end
    local processBar = self:findChild("process")
    local lbProg = self:findChild("lb_number")

    local preProg, curProg = self:getPreAndCurProg()
    local addStarNum = G_GetMgr(ACTIVITY_REF.QuestRush):getAddStarNum()
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
    local bPop = G_GetMgr(ACTIVITY_REF.QuestRush):checkMainViewPopActPanel()
    if not bPop then
        G_GetMgr(ACTIVITY_REF.QuestRush):resetOldData()
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
                        G_GetMgr(ACTIVITY_REF.QuestRush):showMainView()
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
function Activity_QuestRushEntryBase:popOnComplete()
    if not G_GetMgr(ACTIVITY_REF.QuestRush):getRunningData() then
        return
    end
    local bPop = G_GetMgr(ACTIVITY_REF.QuestRush):checkMainViewPopActPanel()
    if not bPop then
        G_GetMgr(ACTIVITY_REF.QuestRush):resetOldData()
    else
        util_nextFrameFunc(
            function()
                G_GetMgr(ACTIVITY_REF.QuestRush):showMainView()
            end,
            0
        )
    end
    self:runCsbAction("idle", true, nil, 60)
end

function Activity_QuestRushEntryBase:onEnter()
    -- 更新宝箱状态（version1 的特效）
    gLobalNoticManager:addObserver(
        self,
        function(self)
            self:runCsbAction(
                "fankui",
                false,
                function()
                    self:runCsbAction("idle", true)
                    G_GetMgr(ACTIVITY_REF.QuestRush):showMainView()
                end,
                60
            )
        end,
        self.m_config.EVENT_NAME.PLAY_ENTRY_COLLECT_STAR_ACT
    )
end

function Activity_QuestRushEntryBase:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()
    gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
    if name == "btn_touch" then
        G_GetMgr(ACTIVITY_REF.QuestRush):showMainView()
    end
end

-- 清楚定时器
function Activity_QuestRushEntryBase:clearScheduler()
    if self.m_schedule then
        self:stopAction(self.m_schedule)
        self.m_schedule = nil
    end
end

-- 获取上一次 和 这次的 进度
function Activity_QuestRushEntryBase:getPreAndCurProg()
    local actData = G_GetMgr(ACTIVITY_REF.QuestRush):getRunningData()
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
function Activity_QuestRushEntryBase:getEfStarWorldPos()
    local nodeStar = self:findChild("node_star")
    local worldPos = nodeStar:convertToWorldSpace(cc.p(0, 0))

    return worldPos
end

return Activity_QuestRushEntryBase
