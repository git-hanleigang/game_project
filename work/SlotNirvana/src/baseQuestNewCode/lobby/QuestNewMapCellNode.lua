
-- QuestNewMapCellNode   地图节点
--
local QuestNewMapCellNode = class("QuestNewMapCellNode", util_require("base.BaseView"))

function QuestNewMapCellNode:getCsbNodePath()
    return QUESTNEW_RES_PATH.QuestNewMapCellNode
end
--奖励礼盒
function QuestNewMapCellNode:getGiftCsbNodePath()
    return QUESTNEW_RES_PATH.QuestNewMapCellNodeGift
end

function QuestNewMapCellNode:initDatas(data)
    self.m_chapterId = data.chapterId
    self.m_index = data.index
    self.m_boxNode = data.boxNode
    self:updateCellData()
    self.m_gameInfo = globalData.slotRunData:getLevelInfoById(self.m_cellData.p_gameId)
end

function QuestNewMapCellNode:getIndex()
    return self.m_index
end

function QuestNewMapCellNode:updateCellData()
    self.m_cellData = G_GetMgr(ACTIVITY_REF.QuestNew):getPointDataByChapterIdAndIndex(self.m_chapterId,self.m_index)
end

function QuestNewMapCellNode:getSelfData()
    return self.m_cellData 
end

function QuestNewMapCellNode:initUI()
    self:createCsbNode(self:getCsbNodePath())
    self:initView()
end

function QuestNewMapCellNode:initCsbNodes()
    self.m_sp_loading = self:findChild("sp_loading")
    self.m_node_icon = self:findChild("node_guanqia") 

    self.m_bar_jdt = self:findChild("bar_jdt") 
    self.m_lb_shuzi = self:findChild("lb_shuzi") 

    self.m_sp_dizuo = self:findChild("sp_dizuo") 
    self.m_sp_jdtdi = self:findChild("sp_jdtdi") 
    self.m_slotstar_39 = self:findChild("slotstar_39") 
    
    
    local btn_click = self:findChild("btn_click")
    if btn_click then
        self:addClick(btn_click)
        btn_click:setSwallowTouches(false)
    end
    self.m_panel_click = btn_click
end

function QuestNewMapCellNode:initView()
    if self.m_cellData == nil then
        return
    end
    local rate,points ,maxPoints = self.m_cellData:getStarRate()
    self.m_lb_shuzi:setString("" .. points .. "/" .. maxPoints)
    self.m_bar_jdt:setPercent(rate)
    self:initStepNode()
    self:initBoxNode()
    self:updateQuestIcon()
    --self:updateNado()

    self.m_sp_loading:setVisible(false)

    if self.m_gameInfo and not self.m_gameInfo.p_fastLevel then
        local percent = gLobaLevelDLControl:getLevelPercent(self.m_gameInfo.p_levelName)
        if percent then
            self.m_sp_loading:setVisible(true)
            self:createDownLoadNode(percent)
        end
    end

    if not self.m_cellData:isWillDoUnlock() and self.m_cellData:isUnlock() then
        if self.m_cellData:isCompleted() and not self.m_cellData:isWillDoCompleted() then
            self:runCsbAction("an", true)
            self.m_panel_click:setVisible(not self.m_cellData:isCompleted())
        else
            self:runCsbAction("idle", true)
        end
    else
        --self.m_panel_click:setVisible(false)
        self.m_sp_dizuo:setColor(cc.c3b(140, 140, 140))
        self.m_sp_jdtdi:setColor(cc.c3b(140, 140, 140))
        self.m_slotstar_39:setColor(cc.c3b(140, 140, 140))
        self.m_lb_shuzi:setColor(cc.c3b(140, 140, 140))

        self:runCsbAction("lock", true)
    end
end

function QuestNewMapCellNode:initStepNode()
    local unlock = not self.m_cellData:isWillDoUnlock() and self.m_cellData:isUnlock()
    self.m_stepNode = util_createView(QUESTNEW_CODE_PATH.QuestNewMapStepNode, {type = "cell",index = self.m_index ,unlock = unlock})
    self:addChild(self.m_stepNode)
end


function QuestNewMapCellNode:initBoxNode()
    if self.m_cellData:isHaveBox() and self.m_boxNode ~= nil then
        local cupNode = util_createView(QUESTNEW_CODE_PATH.QuestNewMapBoxNode, {data_box = self.m_cellData})
        cupNode:setScale(0.6)
        self.m_boxNode:addChild(cupNode)
        self.m_boxCell = cupNode
    end
end

function QuestNewMapCellNode:doBoxCompleteAct(callback)
    if self.m_cellData:isHaveBox() and self.m_boxCell then
        if self.m_cellData:isBoxUnlock() and self.m_cellData:isWillDoBoxOpen() then
            self:updateCellData()
            self.m_boxCell:doBoxOpen(callback)
        else
            if callback then
                callback()
            end
        end
    else
        if callback then
            callback()
        end
    end
end

function  QuestNewMapCellNode:refreshBoxState()
    if self.m_cellData:isHaveBox() and self.m_boxCell then
        self:updateCellData()
        self.m_boxCell:refreshByData(self.m_cellData)
    end
end

function QuestNewMapCellNode:IsNeedNextStage()
    local questConfig = G_GetMgr(ACTIVITY_REF.Quest):getRunningData()
    if questConfig ~= nil then
        local phase_idx = questConfig:getPhaseIdx()
        local stage_idx = questConfig:getStageIdx()
        if self.m_curPhase == phase_idx and self.m_chapterId == stage_idx then
            return true
        end
    end

    return false
end

function QuestNewMapCellNode:updateQuestIcon()
    --关卡头像
    local levelName = globalData.slotRunData:getLevelName(self.m_cellData.p_gameId)
    if levelName then
        local level_icon = self:showSprite(levelName)
        if level_icon then
            level_icon:setName("level_icon")
            self.m_node_icon:removeChildByName("level_icon")
            self.m_node_icon:addChild(level_icon)
            self.m_sp_cell = level_icon
            self.m_sp_cell:setScale(0.75) -- 设置的固定值 之前是66% 正常的关卡图标放在这里会偏大
        end
    end
end

function QuestNewMapCellNode:showSprite(levelName)
    local p_sprite = nil
    local path = globalData.GameConfig:getLevelIconPath(levelName, LEVEL_ICON_TYPE.UNLOCK)
    if util_IsFileExist(path) then
        p_sprite = util_createSprite(path)
        if self.m_cellData:isWillDoUnlock() or not self.m_cellData:isUnlock() then
            p_sprite:setColor(cc.c3b(140, 140, 140))
        end
    else
        local loading_path = "QuestOther/quest_loading_icon.png"
        p_sprite = util_createSprite(loading_path)
        if self.m_gameInfo and self.m_gameInfo.p_csbName then
            local notifyName = util_getFileName(self.m_gameInfo.p_csbName)
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
            end
        end
    end
    return p_sprite
end

function QuestNewMapCellNode:onEnter()
    self:registerHandler()
end

function QuestNewMapCellNode:isWillDoCompleted()
    return self.m_cellData:isWillDoCompleted()
end

function QuestNewMapCellNode:doCellCompletedAct(callback)
    if self.m_cellData:isWillDoCompleted() then
        self.m_cellData:clearWillDoCompleted()
        self:runCsbAction(
            "daguo",
            false,
            function()
                if callback then
                    callback()
                end
                self.m_panel_click:setVisible(false)
            end
        )
    end
end

function QuestNewMapCellNode:isWillDoUnlock()
    return self.m_cellData:isWillDoUnlock()
end

function QuestNewMapCellNode:doCellUnlockAct(callback)
    if self.m_cellData:isWillDoUnlock() then
        self.m_cellData:clearWillDoUnlock()
        self.m_stepNode:doStepAct(function ()
            gLobalSoundManager:playSound(QUESTNEW_RES_PATH.QuestNew_Sound_StageUnlock)
            self:runCsbAction(
                "open",
                false,
                function()
                    self.m_sp_cell:setColor(cc.c3b(255, 255, 255))
                    self.m_sp_dizuo:setColor(cc.c3b(255, 255, 255))
                    self.m_sp_jdtdi:setColor(cc.c3b(255, 255, 255))
                    self.m_slotstar_39:setColor(cc.c3b(255, 255, 255))
                    self.m_lb_shuzi:setColor(cc.c3b(255, 255, 255))
                    self:runCsbAction(
                        "open2",
                        false,
                        function ()
                            if callback then
                                callback()
                            end
                            self.m_panel_click:setVisible(true)
                        end
                    )
                end
            )
        end)
    else
        if callback then
            callback()
        end
    end
end

function QuestNewMapCellNode:updateView(data)
    if tolua.isnull(self) then
        return
    end

    if data then
        self.m_cellData = data
    end

end

function QuestNewMapCellNode:registerHandler()
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
            self:updateView()
        end,
        ViewEventType.NOTIFY_ACTIVITY_QUEST_UPDATECELL
    )
    gLobalNoticManager:addObserver(
        self,
        function()
            self:updateView()
        end,
        ViewEventType.NOTIFY_QUEST_CLOSEBOX_NEXTSTAGE
    )
end

--进入关卡
function QuestNewMapCellNode:checkGotoLevel()
    local info = self.m_gameInfo
    if not info then
        return
    end

    --根据app版本检测关卡是否可以进入
    if not gLobalViewManager:checkEnterLevelForApp(info.p_id) then
        gLobalViewManager:showUpgradeAppView()
        return
    end

    local notifyName = util_getFileName(info.p_csbName)
    if globalDynamicDLControl:checkDownloading(notifyName) then
        --入口未下载
        return
    end

    local questConfig = G_GetMgr(ACTIVITY_REF.QuestNew):getRunningData()
    if not questConfig then
        return
    end

    --已完成关卡不能进入
    if self.m_cellData:isCompleted() then
        return
    end

    gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
    
    gLobalSendDataManager:getLogSlots():resetEnterLevel()
    local isSucc = gLobalViewManager:gotoSlotsScene(info, "QuestLobby")
    if isSucc then
        --确定从quest活动，进入关卡
        G_GetMgr(ACTIVITY_REF.QuestNew):setEnterGameFromQuest(true)
        G_GetMgr(ACTIVITY_REF.QuestNew):setEnterGameChapterIdAndPointId(self.m_chapterId,self.m_index)
    end
end

function QuestNewMapCellNode:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()
    if G_GetMgr(ACTIVITY_REF.QuestNew):isDoingMapCheckLogic() then
        return
    end
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

function QuestNewMapCellNode:onTouchClick(isClick)
    if self.m_cellData:isUnlock() then
        --进入难度选择
        if not self.m_cellData:isCompleted() then
            --只有手动点击才会进入这里
            if isClick then
                self:checkDownLoadGotoLevel(true)
            end
        end
    else
        self:runCsbAction("suo", false)
    end
end




-----------------------------------------下载相关-----------------------------------------
--检测下载状态并进入游戏
function QuestNewMapCellNode:checkDownLoadGotoLevel(isClickMusic)
    local info = self.m_gameInfo
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
function QuestNewMapCellNode:createDownLoadNode(percent, isClickMusic)
    local info = self.m_gameInfo
    if not info then
        return
    end

    if self.m_dlView then
        return
    end

    self.m_dlView =
        util_createFindView(
        QUEST_CODE_PATH.QuestCellDL,
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

    self.m_node_icon:addChild(self.m_dlView, 1)
    self.m_dlView:updateStartDl(percent)
    if not percent then
        if isClickMusic then
            gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        end
        --下载入口记录
        if gLobalSendDataManager and gLobalSendDataManager.getLogGameLevelDL then
            gLobalSendDataManager:getLogGameLevelDL():setDownloadInfo(info.p_levelName, {type = "Quest", siteType = "RegularArea"})
        end
        gLobaLevelDLControl:checkDownLoadLevel(info)
    end
end

return QuestNewMapCellNode
