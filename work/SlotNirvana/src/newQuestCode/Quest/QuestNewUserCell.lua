-- Created by jfwang on 2019-05-21.
-- QuestNewUserCell
--
local QuestNewUserCell = class("QuestNewUserCell", util_require("base.BaseView"))

function QuestNewUserCell:initUI(data, isEnd, mainView, rewardBox, carpetItem)
    self:createCsbNode("NewUserQuest/Activity/NewUser_QuestCell.csb")
    self.m_csbNode:setScale(1.2)
    --是否是最后关卡
    self.m_isEnd = isEnd

    --地毯
    self.m_carpetItem = carpetItem
    --阶段序号
    self.m_curPhase = data.phase
    --关卡之后的宝箱
    self.m_rewardBox = rewardBox
    --关卡序号
    self.m_curStage = data.stage
    --唯一标示
    self.m_index = data.index

    --当前关卡数据
    self.m_data = data.d

    self.m_mainView = mainView

    self.m_logoNode = self:findChild("logo")
    self.m_logoNode1 = self:findChild("logo1")

    self.btn_close = self:findChild("btn_close")
    self.btn_click = self:findChild("btn_click")
    self.btn_click:setSwallowTouches(false)
    self.btn_lock = self:findChild("btn_lock")
    self.btn_lock:setSwallowTouches(false)

    self.m_offIconY = 0
    local questConfig = self:getQuestData()
    if questConfig ~= nil then
        self.m_lastStage = questConfig:getStageIdx()

        if self.m_isEnd and questConfig.p_questJackpot then
            self.m_jackpotValue = questConfig.p_questJackpot
        end
    end

    self.m_isSpinIdle = false
    self:initInfo()
end

function QuestNewUserCell:getQuestData()
    return G_GetMgr(ACTIVITY_REF.Quest):getRunningData()
end

function QuestNewUserCell:getIndex()
    return self.m_index
end

--初始化关卡配置信息并检测下载状态
function QuestNewUserCell:initInfo()
    -- local levelInfo = globalData.slotRunData.p_machineDatas
    -- if levelInfo and #levelInfo > 0 then
    --     for index = 1, #levelInfo do
    --         local data = levelInfo[index]
    --         if data.p_id == self.m_data.p_gameId then
    --             self.m_info = data
    --             break
    --         end
    --     end
    -- end
    self.m_info = globalData.slotRunData:getLevelInfoById(self.m_data.p_gameId)

    self:initView()

    if self.m_info and not self.m_info.p_fastLevel then
        local percent = gLobaLevelDLControl:getLevelPercent(self.m_info.p_levelName)
        if percent then
            self:createDownLoadNode(percent)
        end
    end
end

function QuestNewUserCell:IsUnLock()
    local questConfig = self:getQuestData()
    if questConfig ~= nil then
        local phase_idx = questConfig:getPhaseIdx()
        local stage_idx = questConfig:getStageIdx()
        if self.m_curPhase < phase_idx or (self.m_curPhase == phase_idx and self.m_curStage <= stage_idx) then
            return true
        end
    end

    return false
end

function QuestNewUserCell:IsNeedNextStage()
    local questConfig = self:getQuestData()
    if questConfig ~= nil then
        local phase_idx = questConfig:getPhaseIdx()
        local stage_idx = questConfig:getStageIdx()
        if self.m_curPhase == phase_idx and self.m_curStage == stage_idx then
            return true
        end
    end

    return false
end

-- 获得Spine资源名称
function QuestNewUserCell:getSpineFileName(levelName, prefixName)
    prefixName = prefixName or ""
    local fileName = prefixName .. "_level_spine_" .. levelName
    if globalData.GameConfig:checkLevelGroupA(levelName) then
        -- 是AB Test的 A 组
        fileName = fileName .. "_abtest"
    end
    return fileName
end

-- 获得Spin资源信息
function QuestNewUserCell:getSpinFileInfo(levelName, prefixName)
    local spineName = self:getSpineFileName(levelName, prefixName)
    local spinepath = "LevelNodeSpine/" .. spineName
    local spinePngName = self:getSpineFileName(levelName, "common")
    local spinePngPath = "LevelNodeSpine/" .. spinePngName
    local spineTexture = spinePngPath .. ".png"
    local pngFullPath = CCFileUtils:sharedFileUtils():fullPathForFilename(spineTexture)
    local isPngExist = CCFileUtils:sharedFileUtils():isFileExist(pngFullPath)
    if not isPngExist then
        spineTexture = spinepath .. ".png"
    end

    local fileNamePath = CCFileUtils:sharedFileUtils():fullPathForFilename(spinepath .. ".skel")
    local isExist = CCFileUtils:sharedFileUtils():isFileExist(fileNamePath)
    if not isExist then
        return false, "", ""
    else
        return true, spinepath, spineTexture
    end
end

function QuestNewUserCell:updateQuestIcon()
    --关卡头像
    local levelName = globalData.slotRunData:getLevelName(self.m_data.p_gameId)
    if levelName then
        local level_icon = self:showSpine(levelName)
        if not level_icon then
            level_icon = self:showSprite(levelName)
        end
        if level_icon then
            level_icon:setName("level_icon")
            self.m_logoNode:removeChildByName("level_icon")
            self.m_logoNode:addChild(level_icon)
            self.m_sp_cell = level_icon
            self.m_sp_cell:setScale(0.8)
            self.m_sp_cell:setPositionY(self.m_offIconY)
        end
    end
end

function QuestNewUserCell:showSpine(levelName)
    local spine = nil
    local isExist, spinepath, spineTexture = self:getSpinFileInfo(levelName, LEVEL_ICON_TYPE.SMALL)
    if isExist then
        spine = util_spineCreate(spinepath, true, true, 1)
        if spine then
            util_spinePlay(spine, "actionframe", true)
        end
    end
    return spine
end

function QuestNewUserCell:showSprite(levelName)
    local p_sprite = nil
    --local path = globalData.GameConfig:getLevelIconPath(levelName, LEVEL_ICON_TYPE.SMALL)
    --if util_IsFileExist(path) then
    --    p_sprite = util_createSprite(path)
    --else
    local loading_path = "newIcons/Order/cashlink_Small_loading.png" -- 矩形图    "quest_loading_icon.png" -- 圆形图
    p_sprite = util_createSprite(loading_path)
    local notifyName = util_getFileName(self.m_info.p_csbName)
    if globalDynamicDLControl:checkDownloading(notifyName) then
        --注册下载通知
        gLobalNoticManager:addObserver(
            self,
            function(self, params)
                if not tolua.isnull(self) then
                    self:updateQuestIcon()
                end
            end,
            notifyName
        )
    --end
    end
    return p_sprite
end

function QuestNewUserCell:initView()
    if self.m_data == nil then
        return
    end

    self:updateQuestIcon()

    self.m_zorder = self:getZOrder()
end

function QuestNewUserCell:onEnter()
    self:registerHandler()

    self:updateView()
end

-- 能否播放当前关卡的完成动画
function QuestNewUserCell:isNeedPlayNextLevel()
    local questConfig = self:getQuestData()
    if questConfig and questConfig.p_completeAct and questConfig.p_completeAct[1] == self.m_curPhase and questConfig.p_completeAct[2] == self.m_curStage then
        return true
    end
    return false
end

function QuestNewUserCell:updateView(data)
    if data then
        self.m_data = data
    end
    -- self:initTipView(self.m_data)
    --该关卡是否解锁
    self.m_isUnLock = self:IsUnLock()
    if self.m_isUnLock then
        if self.m_sp_cell then
            self.m_sp_cell:setColor(cc.c3b(255, 255, 255))
        end
        --维护关卡直接改为完成状态
        if self:IsNeedNextStage() and self.m_info.p_maintain then
            self.m_data.p_status = "FINISHED"
        end

        if self:isNeedPlayNextLevel() then
            --完成调转下一关
            self:playCollectAnim()
        elseif self.m_data.p_status == "FINISHED" then
            --改关卡已经完成断线重连
            if self:IsNeedNextStage() then
                self:playCollectAnim()
            else
                if self.m_carpetItem then
                    self.m_carpetItem:setVisible(true)
                    local animName = "idleSmall"
                    if self.m_isEnd then
                        animName = "idleBig"
                    end
                    self.m_carpetItem:playAction(animName)
                end
                if self.m_rewardBox then
                    self.m_rewardBox:playCollectedAnima()
                end
                self:runCsbAction("done")
            end
        elseif self.m_data.p_status == "INIT" then
            --小手引导特效
            self:showHandView()
            if self.m_rewardBox then
                self.m_rewardBox:playIdleAnima()
            end
            if self.m_carpetItem then
                self.m_carpetItem:setVisible(true)
                local animName = "unOpenSmall"
                if self.m_isEnd then
                    animName = "unOpenBig"
                end
                self.m_carpetItem:playAction(animName)
            end
        else
            --小手引导特效
            self:showHandView()
            if self.m_rewardBox then
                self.m_rewardBox:playIdleAnima()
            end
            if self.m_carpetItem then
                self.m_carpetItem:setVisible(true)
                local animName = "unOpenSmall"
                if self.m_isEnd then
                    animName = "unOpenBig"
                end
                self.m_carpetItem:playAction(animName)
            end
        end
    else
        if self.m_rewardBox then
            self.m_rewardBox:playIdleAnima()
        end
        if self.m_carpetItem then
            self.m_carpetItem:setVisible(true)
            local animName = "unOpenSmall"
            if self.m_isEnd then
                animName = "unOpenBig"
            end
            self.m_carpetItem:playAction(animName)
        end
        self:showLock()
    end
end
function QuestNewUserCell:playCollectAnim()
    local mask = util_newMaskLayer(false)
    mask:setOpacity(0)
    mask:setName("questNewUserCellMask")
    gLobalViewManager:showUI(mask)

    self:runCsbAction(
        "spin2",
        false,
        function()
            self:runCsbAction(
                "done_act",
                false,
                function()
                    local questConfig = self:getQuestData()
                    if self.m_carpetItem then
                        local animName = "openSmall"
                        if self.m_isEnd then
                            animName = "openBig"
                        end
                        self.m_carpetItem:setVisible(true)
                        self.m_carpetItem:playAction(
                            animName,
                            false,
                            function()
                                self:getTaskReward(
                                    function()
                                        if mask then
                                            mask:removeSelf()
                                        end

                                        if self.m_flashFunc then
                                            self.m_flashFunc()
                                        end
                                        -- 消息发送，执行轮盘和关卡的解锁逻辑
                                        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_QUEST_NEXT_UNLOCK, {index = self.m_index})
                                        questConfig.p_completeAct = nil
                                        if self.m_isEnd then
                                            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_QUEST_CLOSEBOX_NEXTSTAGE)
                                        end
                                        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_NEWUSER_QUEST_UPDATECELL)
                                    end
                                )
                            end
                        )
                    else
                        self:getTaskReward(
                            function()
                                if mask then
                                    mask:removeSelf()
                                end

                                if self.m_flashFunc then
                                    self.m_flashFunc()
                                end
                                -- 消息发送，执行轮盘和关卡的解锁逻辑
                                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_QUEST_NEXT_UNLOCK, {index = self.m_index})
                                questConfig.p_completeAct = nil
                                if self.m_isEnd then
                                    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_QUEST_CLOSEBOX_NEXTSTAGE)
                                end
                                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_NEWUSER_QUEST_UPDATECELL)
                            end
                        )
                    end
                end,
                60
            )
        end,
        60
    )
end

function QuestNewUserCell:registerHandler()
    gLobalNoticManager:addObserver(
        self,
        function()
            self:updateView()
        end,
        ViewEventType.NOTIFY_ACTIVITY_QUEST_NEXTSTAGE
    )

    gLobalNoticManager:addObserver(
        self,
        function()
            local questConfig = self:getQuestData()
            if not questConfig then
                return
            end
            if self.m_curPhase and self.m_curStage then
                self.m_data = questConfig:getStageData(self.m_curPhase, self.m_curStage)
            end
            self.m_rewardBox.m_data = self.m_data
            self:updateView()
        end,
        ViewEventType.NOTIFY_QUEST_CLOSEBOX_NEXTSTAGE
    )
    gLobalNoticManager:addObserver(
        self,
        function()
            local questConfig = self:getQuestData()
            if not questConfig then
                return
            end
            if self.m_curPhase and self.m_curStage then
                self.m_data = questConfig:getStageData(self.m_curPhase, self.m_curStage)
            end
            self.m_rewardBox.m_data = self.m_data
        end,
        ViewEventType.NOTIFY_NEWUSER_QUEST_UPDATECELL
    )
end

function QuestNewUserCell:onExit()
    gLobalNoticManager:removeAllObservers(self)
end
--新手引导
function QuestNewUserCell:checkGuide()
    local questConfig = self:getQuestData()
    if questConfig and questConfig.p_expireAt then
        --轮盘引导
        local isWheelGuide = gLobalDataManager:getBoolByField("quest_wheelGuide" .. questConfig.p_expireAt, true)
        if isWheelGuide then
            return true
        end
    end
    return false
end

function QuestNewUserCell:showChange()
    self:runCsbAction(
        "unlock_act",
        false,
        function()
            self:showSpin()
        end,
        60
    )
end
--显示spin按钮
function QuestNewUserCell:showSpin()
    if self.m_sp_cell then
        self.m_sp_cell:setColor(cc.c3b(255, 255, 255))
    end
    self.m_isSpinIdle = true
    self:runCsbAction("spin", true)
end
--显示锁住状态
function QuestNewUserCell:showLock()
    if self.m_sp_cell then
        self.m_sp_cell:setColor(cc.c3b(180, 180, 180))
    end
    self.m_isSpinIdle = false
    self:runCsbAction("unlock")
end

--小手引导特效
function QuestNewUserCell:showHandView()
    local questConfig = self:getQuestData()
    local isGuide = false
    if self.m_curPhase == 1 and self.m_curStage == 1 then
        if questConfig and questConfig.p_completeAct then
            self:showChange()
        end
        isGuide = self:checkGuide()
    end

    --如果不是处在完成关卡动画并且有开启下一关动画执行下面
    if questConfig and not questConfig.p_completeAct and questConfig.p_nextAct and questConfig.p_nextAct[1] == self.m_curPhase and questConfig.p_nextAct[2] == self.m_curStage then
        --兼容掉线情况
        questConfig.p_nextAct = nil
        if self.showChange then
            self:showChange()
        end
    elseif self.m_lastStage and self.m_lastStage ~= questConfig:getStageIdx() then
        if self.showChange then
            self:showChange()
        end
    else
        if questConfig and questConfig.p_completeAct and questConfig.p_nextAct and questConfig.p_nextAct[1] == self.m_curPhase and questConfig.p_nextAct[2] == self.m_curStage then
            if self.m_curPhase == 1 and self.m_curStage == 1 then
                self:showSpin()
            else
                self:showLock()
            end
        else
            self:showSpin()
        end
    end

    --不是第一关引导
    if not isGuide then
        return false
    end
end

--检测下载状态并进入游戏
function QuestNewUserCell:checkDownLoadGotoLevel(isClickMusic)
    local info = self.m_info
    if not info then
        return
    end
    local percent = gLobaLevelDLControl:getLevelPercent(info.p_levelName)
    if info.p_fastLevel then
        self:checkGotoLevel()
    elseif percent then
        self:createDownLoadNode(percent)
    elseif gLobaLevelDLControl:isDownLoadLevel(info) == 2 then
        self:checkGotoLevel()
    elseif info.p_freeOpen and gLobaLevelDLControl:isUpdateFreeOpenLevel(info.p_levelName, info.p_levelName.p_md5) == false then
        self:checkGotoLevel()
    else
        self:createDownLoadNode(nil, isClickMusic)
    end
end

--创建下载节点
function QuestNewUserCell:createDownLoadNode(percent, isClickMusic)
    local info = self.m_info
    if not info then
        return
    end
    if self.m_dlView then
        return
    end
    self.m_dlView =
        util_createFindView(
        "newQuestCode/Quest/QuestNewUserCellDL",
        info,
        function()
            self.m_dlView:removeFromParent()
            self.m_dlView = nil
            self:checkGotoLevel()
        end,
        function()
            self.m_dlView:removeFromParent()
            self.m_dlView = nil
        end
    )
    if self.m_dlView ~= nil then
        self.m_logoNode1:addChild(self.m_dlView, 1)
        self.m_dlView:setPositionY(self.m_offIconY)
        self.m_dlView:setScale(1.3)
        self.m_dlView:updateStartDl(percent)
        if not percent then
            if isClickMusic then
                gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
            end
            --下载入口记录
            if gLobalSendDataManager and gLobalSendDataManager.getLogGameLevelDL then
                gLobalSendDataManager:getLogGameLevelDL():setDownloadInfo(self.m_info.p_levelName, {type = "newQuest", siteType = "RegularArea"})
            end
            gLobaLevelDLControl:checkDownLoadLevel(info)
        end
    end
end

--进入关卡
function QuestNewUserCell:checkGotoLevel()
    local info = self.m_info
    if not info then
        return
    end

    --根据app版本检测关卡是否可以进入
    if not gLobalViewManager:checkEnterLevelForApp(info.p_id) then
        gLobalViewManager:showUpgradeAppView()
        return
    end

    local notifyName = util_getFileName(self.m_info.p_csbName)
    if globalDynamicDLControl:checkDownloading(notifyName) then
        --入口未下载
        return
    end

    local questConfig = self:getQuestData()
    if not questConfig then
        return
    end

    --已完成关卡不能进入
    if not self.m_data or not self.m_data.p_status or self.m_data.p_status == "FINISHED" then
        return
    end

    --不是当前关卡
    if self.m_curPhase ~= questConfig:getPhaseIdx() or self.m_curStage ~= questConfig:getStageIdx() then
        return
    end

    gLobalSendDataManager:getLogSlots():resetEnterLevel()
    local isSucc = gLobalViewManager:gotoSlotsScene(info, "QuestLobby")
    if isSucc then
        -- 确定从quest活动，进入关卡
        questConfig.class.m_IsQuestLogin = true
        questConfig.p_nextAct = nil
    end
end

function QuestNewUserCell:onTouchClick(isClick)
    gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
    self:checkDownLoadGotoLevel(true)
end

function QuestNewUserCell:getTaskReward(callback)
    gLobalSendDataManager:getNetWorkFeature():sendActionQuestNewUserNextStage(
        function(success)
            if not success then
                util_restartGame()
                return
            end
            if self.m_rewardBox then
                self.m_rewardBox:playCollectAnima(
                    function()
                        -- play 礼盒收集
                        local coins = self.m_data.p_coins
                        if self.m_isEnd then
                            if self.m_jackpotValue then
                                coins = coins + self.m_jackpotValue
                            end
                        end
                        local view =
                            util_createView(
                            "newQuestCode.Quest.QuestNewUserRewardView",
                            {coins = coins, isEnd = self.m_isEnd, rewardItem = self.m_data},
                            function()
                                if self and self.m_rewardBox then
                                    self.m_rewardBox:playCarpetCollectAnima(
                                        function()
                                            --礼盒上的毯子特效
                                            if callback then
                                                callback()
                                            end
                                        end
                                    )
                                end
                            end
                        )
                        if view then
                            gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
                        else
                            --礼盒上的毯子特效
                            if callback then
                                callback()
                            end
                        end
                    end
                )
            end
        end,
        true
    )
end

function QuestNewUserCell:canClick()
    if self.m_clicked == true then
        return false
    end
    return true
end

function QuestNewUserCell:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

    if not self:canClick() then
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
        if self.m_isSpinIdle and self:IsUnLock() then
            self:onTouchClick(true)
        end
    elseif name == "btn_lock" then
        if not self.m_info then
            return
        end
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        local notifyName = util_getFileName(self.m_info.p_csbName)
        if globalDynamicDLControl:checkDownloading(notifyName) then
            --入口未下载
            return
        end
        if not self:IsUnLock() then
            self:showLock()
        end
    end
end

return QuestNewUserCell
