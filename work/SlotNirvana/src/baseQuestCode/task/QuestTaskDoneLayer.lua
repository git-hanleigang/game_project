-- Created by jfwang on 2019-05-21.
-- Quest任务完成界面
--

local QuestTaskDoneLayer = class("QuestTaskDoneLayer", BaseLayer)
function QuestTaskDoneLayer:ctor()
    QuestTaskDoneLayer.super.ctor(self)
    self:setLandscapeCsbName(QUEST_RES_PATH.QuestTaskDoneLayer)
    self:setPauseSlotsEnabled(true)

    self:setExtendData("QuestTaskDoneLayer")
end

function QuestTaskDoneLayer:initUI(data)
    self.m_config = G_GetMgr(ACTIVITY_REF.Quest):getRunningData()

    QuestTaskDoneLayer.super.initUI(self)
end

function QuestTaskDoneLayer:initCsbNodes()
    self.m_daojvNode = self:findChild("Node_daojv")
    self.m_doneNode = self:findChild("icon_done")
    self.m_logoNode = self:findChild("logo")
    self.m_keepBtn = self:findChild("btn_keep")

    self.m_rewardNode = self:findChild("node_reward")
    self.m_rewardCoins = self:findChild("m_lb_coins")
    self.m_rewardLighting = self:findChild("m_lb_num")
    self.m_sp_star = self:findChild("m_sp_star")

    self.m_sp_coins = self:findChild("m_sp_coins")
    self.m_node_star = self:findChild("node_star")
    self.m_node_coin = self:findChild("node_coin")

    self.m_node_rank_up = self:findChild("node_rank_up")
    self.m_node_rank_down = self:findChild("node_rank_down")
    self.m_lb_rank_up = self:findChild("m_lb_rank_up")
    self.m_lb_rank_down = self:findChild("m_lb_rank_down")

    if self:hasCoins() then
        self.m_node_coin:setVisible(true)
    else
        self.m_node_coin:setVisible(false)
    end
end

function QuestTaskDoneLayer:hasCoins()
    if self.m_config ~= nil then
        local data = self.m_config:getCurStageData()
        if data ~= nil and data.p_coins and tonumber(data.p_coins) > 0 then
            if self.m_config:getStageIdx() == 6 then
                --这里不显示钱通过宝箱加
                return false
            else
                return true
            end
            return true
        end
    end
    return false
end

function QuestTaskDoneLayer:initView()
    --关卡头像
    local levelName = ""
    if globalData.slotRunData.machineData and globalData.slotRunData.machineData.p_levelName then
        levelName = globalData.slotRunData.machineData.p_levelName
    end

    if levelName ~= "" then
        local newPath = globalData.GameConfig:getLevelIconPath(levelName, LEVEL_ICON_TYPE.UNLOCK)
        if util_IsFileExist(newPath) then
            local sp = util_createSprite(newPath)
            if not sp then
                return
            end
            self.m_logoNode:addChild(sp)
            -- sp:setScale(0.66)
            local mask = util_createSprite(newPath)
            local flash = util_createSprite("QuestNewUser/Activity/NewQuestOther/quest_l_flash_a.png")
            flash:setBlendFunc(770, 1)
            local clip_node = cc.ClippingNode:create()
            clip_node:setAlphaThreshold(0.9)
            clip_node:setStencil(mask)
            sp:addChild(clip_node)
            local w, h = sp:getContentSize().width * 0.5, sp:getContentSize().height * 0.5
            clip_node:setPosition(w, h)
            clip_node:addChild(flash)
            flash:setPosition(-w * 3, 0)
            flash:runAction(cc.MoveTo:create(3, cc.p(w * 3, 0)))
        end
    end

    self.m_node_rank_up:setVisible(false)
    self.m_node_rank_down:setVisible(false)
    --完成，显示奖励信息
    if self.m_config ~= nil then
        local data = self.m_config:getCurStageData()
        if data ~= nil then
            self:showReward(data)
        end
    end
    --显示排名变化
    if self.m_config and self.m_config.p_rankUp then
        if self.m_config.p_rankUp > 0 then
            self.m_node_rank_up:setVisible(true)
            self.m_lb_rank_up:setString(self.m_config.p_rankUp)
        elseif self.m_config.p_rankUp < 0 then
            self.m_node_rank_down:setVisible(true)
            self.m_lb_rank_down:setString(math.abs(self.m_config.p_rankUp))
        end
    end
end

--显示奖励信息
function QuestTaskDoneLayer:showReward(data)
    if data ~= nil then
        local buffmul = 1
        local buffInfo = globalData.buffConfigData:getBuffDataByType(BUFFTYPY.BUFFTYPE_SPECIALCLAN_QUEST)
        if buffInfo then
            local nMuti = tonumber(buffInfo.buffMultiple)
            buffmul = buffmul + nMuti / 100
        end

        local buffInfo_1 = globalData.buffConfigData:getBuffDataByType(BUFFTYPY.BUFFTYPE_QUESTICONS_MORE)
        if buffInfo_1 then
            local nMuti = tonumber(buffInfo_1.buffMultiple) -1
            buffmul = buffmul + nMuti 
        end
        
        self.m_rewardCoins:setString(util_formatCoins(data.p_coins * buffmul, 9))
        local size = self.m_rewardCoins:getContentSize()
        local scaleX = self.m_rewardCoins:getScaleX()
        local posX = self.m_rewardCoins:getPositionX()
        self.m_sp_coins:setPositionX(posX - size.width * scaleX / 2 - 25)
        self.m_rewardLighting:setString(math.floor(data.p_points))
        if data.p_points >= 100 then
            self.m_rewardLighting:setPositionX(self.m_rewardLighting:getPositionX() - 22)
            self.m_sp_star:setPositionX(self.m_sp_star:getPositionX() - 22)
        end
    end
end

function QuestTaskDoneLayer:onKeepGoing()
    if self.isOnKeepGoing then
        return
    end
    self.isOnKeepGoing = true
    local questConfig = G_GetMgr(ACTIVITY_REF.Quest):getRunningData()
    if questConfig ~= nil then
        if questConfig:getStageIdx() == 6 then
            --宝箱返回大厅通过重连打开防止提前变化地图
            gLobalViewManager:gotoSceneByType(SceneType.Scene_Lobby)
            return
        end
    end

    --领取奖励，打点
    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            if not tolua.isnull(self) then
                gLobalNoticManager:removeObserver(self, ViewEventType.NOTIFY_ACTIVITY_QUEST_MSG_RESPONSE)
                self:onMsgResponse(params)
            end
        end,
        ViewEventType.NOTIFY_ACTIVITY_QUEST_MSG_RESPONSE
    )

    gLobalSendDataManager:getNetWorkFeature():sendActionQuestNextStage("Reward")
end

function QuestTaskDoneLayer:onMsgResponse(bl_success)
    if not bl_success then
        return
    end

    local isFlyCoins = self:hasCoins()
    if isFlyCoins then
        local startPos = self.m_keepBtn:getParent():convertToWorldSpace(cc.p(self.m_keepBtn:getPosition()))
        local endPos = globalData.flyCoinsEndPos
        local baseCoins = globalData.topUICoinCount
        local rewardCoins = globalData.userRunData.coinNum - globalData.topUICoinCount
        gLobalViewManager:pubPlayFlyCoin(
            startPos,
            endPos,
            baseCoins,
            rewardCoins,
            function()
                if not tolua.isnull(self) then
                    self:checkHolidayChallenge()
                end
            end,
            false,
            20
        )
    else
        self:checkHolidayChallenge()
    end
end

function QuestTaskDoneLayer:playShowAction()
    QuestTaskDoneLayer.super.playShowAction(self, "show", false)
end

function QuestTaskDoneLayer:onEnter()
    QuestTaskDoneLayer.super.onEnter(self)
    --完成，欢呼音效
    gLobalSoundManager:playSound("QuestSounds/Quest_huanhu.mp3")

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

function QuestTaskDoneLayer:playHideAction()
    gLobalSoundManager:playSound("Sounds/soundHideView.mp3")
    QuestTaskDoneLayer.super.playHideAction(self, "over", false)
end

function QuestTaskDoneLayer:onKeyBack()
    self:onKeepGoing()
end

function QuestTaskDoneLayer:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()
    gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)

    if name == "btn_keep" then
        sender:setTouchEnabled(false)
        self:onKeepGoing()
    end
end

function QuestTaskDoneLayer:closeUI()
    if self.isClose then
        return
    end
    self.isClose = true
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_RESUME_MACHINE_POPUPVIEW)
    QuestTaskDoneLayer.super.closeUI(self)
end

--csc 2021年07月29日 检测当前是否有聚合挑战 比赛任务完成
function QuestTaskDoneLayer:checkHolidayChallenge()
    local callback = function()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_RESUME_MACHINE_POPUPVIEW)
        gLobalViewManager:gotoSceneByType(SceneType.Scene_Lobby)
    end
    local holidayChallenge_mgr = G_GetMgr(ACTIVITY_REF.HolidayChallenge)
    if holidayChallenge_mgr:getLeaguesCollectStatus() then
        holidayChallenge_mgr:setLeaguesCollectStatus(false)
        local taskType = holidayChallenge_mgr.TASK_TYPE.LEAGUES
        if holidayChallenge_mgr:getHasTaskCompletedByType(taskType) then
            holidayChallenge_mgr:chooseCreatePopLayer(
                taskType,
                function()
                    G_GetMgr(ACTIVITY_REF.BattleMatch):doCheckShowActivityLayer(
                        function()
                            callback()
                        end,
                        false
                    )
                end
            )
        else
            G_GetMgr(ACTIVITY_REF.BattleMatch):doCheckShowActivityLayer(
                function()
                    callback()
                end,
                false
            )
        end
    else
        G_GetMgr(ACTIVITY_REF.BattleMatch):doCheckShowActivityLayer(
            function()
                callback()
            end,
            false
        )
    end
end

return QuestTaskDoneLayer
