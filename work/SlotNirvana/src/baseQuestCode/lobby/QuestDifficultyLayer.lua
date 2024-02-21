-- Created by jfwang on 2019-05-21.
-- Quest 难度选择
--

local QuestDifficultyLayer = class("QuestDifficultyLayer", BaseLayer)

function QuestDifficultyLayer:initDatas(data)
    QuestDifficultyLayer.super.initDatas(self)

    --阶段
    self.m_config = G_GetMgr(ACTIVITY_REF.Quest):getRunningData()
    self:setLandscapeCsbName(self:getCsbNodePath())
    self.m_isHideActionEnabled = false
    -- self:mergePlistInfos(QUEST_PLIST_PATH.QuestDifficultyLayer)
    self:setExtendData("QuestDifficultyLayer")
end

function QuestDifficultyLayer:getCsbNodePath()
    return QUEST_RES_PATH.QuestDifficultyLayer
end

function QuestDifficultyLayer:initUI(data)
    QuestDifficultyLayer.super.initUI(self)

    if self.m_config ~= nil and self.m_config:getPhaseIdx() then
        local m_lb_phase = self:findChild("m_lb_phase")
        if m_lb_phase then
            m_lb_phase:setString(self.m_config:getPhaseIdx())
        end
    end
end

function QuestDifficultyLayer:onShowedCallFunc()
    self:runCsbAction("idle", false, nil, 60)
    if not self.play_schedule then
        self.play_schedule =
            util_schedule(
            self,
            function()
                self:runCsbAction("idle", false, nil, 60)
            end,
            5
        )
    end
end

function QuestDifficultyLayer:playShowAction()
    local userDefAction = function(callFunc)
        self:runCsbAction(
            "show",
            false,
            function()
                if callFunc then
                    callFunc()
                end
            end,
            60
        )
    end
    QuestDifficultyLayer.super.playShowAction(self, userDefAction)
end

function QuestDifficultyLayer:updateView(d)
    if d == nil or d.data == nil or #d.data <= 0 then
        return
    end
    local rewardList = d.data
    self.m_difficultyList = {}
    for i = 1, #rewardList do
        local rewardData = rewardList[i]
        self:createCell(i, rewardData)
        self.m_difficultyList[i] = rewardData.difficulty
    end
end

function QuestDifficultyLayer:createCell(index, data)
    local nodeCell = self:findChild("node_cell" .. index)
    if not nodeCell then
        return
    end

    local m_lb_point = self:findChild("m_lb_point" .. index)
    if m_lb_point then
        m_lb_point:setString("+" .. data.points)
    end

    local sp_coin = self:findChild("sp_coin" .. index)
    local m_lb_coins = self:findChild("lb_coins" .. index)
    m_lb_coins:setString(util_formatCoins(data.coins, 9))

    util_alignCenter({{node = sp_coin, alignX = 5}, {node = m_lb_coins}})
end

function QuestDifficultyLayer:hasCoins(data)
    if data and data.coins and tonumber(data.coins) > 0 then
        return true
    end
    return false
end

function QuestDifficultyLayer:clickDifficulty(index)
    if not self.m_difficultyList then
        return
    end

    if self.isClickDiff then
        return
    end
    self.isClickDiff = true
    performWithDelay(
        self,
        function()
            self.isClickDiff = nil
        end,
        3
    )

    local difficulty = index
    if self.m_difficultyList and self.m_difficultyList[index] then
        difficulty = self.m_difficultyList[index]
    end
    gLobalSendDataManager:getNetWorkFeature():sendActionQuestSelectDifficulty(difficulty)
    gLobalSendDataManager:getLogQuestActivity():sendQuestUILog("ActivityDifficulty", "Click")
end

function QuestDifficultyLayer:registerListener()
    QuestDifficultyLayer.super.registerListener(self)

    --选择难度成功
    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            self:closeUI()
        end,
        ViewEventType.NOTIFY_ACTIVITY_QUEST_DIFFICULTY
    )

    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            if params.name == ACTIVITY_REF.Quest then
                target:closeUI()
            end
        end,
        ViewEventType.NOTIFY_ACTIVITY_TIMEOUT
    )
end

function QuestDifficultyLayer:onEnter()
    QuestDifficultyLayer.super.onEnter(self)
    gLobalSendDataManager:getLogQuestActivity():sendQuestUILog("ActivityDifficulty", "Open")
end

function QuestDifficultyLayer:onExit()
    QuestDifficultyLayer.super.onExit(self)

    if not self.play_schedule then
        self:stopAction(self.play_schedule)
        self.play_schedule = nil
    end
end

function QuestDifficultyLayer:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()
    if name == "btn_close" then
        sender:setTouchEnabled(false)
        self:closeUI()
    end

    if name == "btn_1" then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        self:clickDifficulty(1)
    elseif name == "btn_2" then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        self:clickDifficulty(2)
    elseif name == "btn_3" then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        self:clickDifficulty(3)
    end
end

function QuestDifficultyLayer:closeUI()
    QuestDifficultyLayer.super.closeUI(self)
    -- 界面关闭
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_QUEST_DIFFICULTY_CLOSED)
end

return QuestDifficultyLayer
