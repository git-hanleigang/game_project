local GuideLevelup5Tip = class("GuideLevelup5Tip", util_require("base.BaseView"))

function GuideLevelup5Tip:initUI(callback)
    self.m_callback = callback
    self:createCsbNode("NoviceGuide/MoreGameAtYourChoice.csb")

    local allLevels = globalData.slotRunData.p_machineDatas
    -- allLevels[i]
    local needCount = 1
    self.m_levelList = {}
    local levelNameList = {}
    for i = 1, #allLevels do
        if allLevels[i].p_firstOrder and not allLevels[i].p_highBetFlag then
            self.m_levelList[needCount] = allLevels[i].p_id
            levelNameList[needCount] = allLevels[i].p_levelName
            needCount = needCount + 1
        end
        if needCount > 6 then
            break
        end
    end

    for i = 1, #self.m_levelList do
        local btn = self:findChild("Panel_" .. i)
        if btn then
            self:addClick(btn)
        end
        local contents = self:findChild("Sprite_" .. i)
        if contents and levelNameList[i] then
            local path = globalData.GameConfig:getLevelIconPath(levelNameList[i], LEVEL_ICON_TYPE.SMALL)
            display.removeImage(path)
            local hasImage = util_changeTexture(contents, path)
            if hasImage == false then
                util_changeTexture(contents, "newIcons/Order/cashlink_Small_loading.png")
            end
        end
    end
    if globalData.slotRunData.isPortrait == true then
        util_csbScale(self.m_csbNode, 0.65)
    else
        util_csbScale(self.m_csbNode, 0.85)
    end

    local root = self:findChild("root")
    if root then
        self:runCsbAction("idle")
        self:commonShow(
            root,
            function()
                if not self.m_click then
                    self:runCsbAction("idle")
                end
            end
        )
    else
        self:runCsbAction(
            "show",
            false,
            function()
                if not self.m_click then
                    self:runCsbAction("idle")
                end
            end
        )
    end

    if globalFireBaseManager.sendFireBaseLogDirect then
        globalFireBaseManager:sendFireBaseLogDirect("guideMoreGamesWindowBigPopup", false)
    end
    -- globalData.slotRunData:checkViewAutoClick(self)
end

function GuideLevelup5Tip:clickFunc(sender)
    if self.m_click then
        return
    end
    self.m_click = true

    local name = sender:getName()
    local tag = sender:getTag()
    if name == "btn_close" then
        if gLobalSendDataManager:getLogGuide():isGuideBegan(6) then
            gLobalSendDataManager:getLogGuide():cleanParams(6)
        end

        if globalFireBaseManager.sendFireBaseLogDirect then
            globalFireBaseManager:sendFireBaseLogDirect("guideMoreGamesWindowBigClickClose", false)
        end

        local root = self:findChild("root")
        if root then
            self:commonHide(
                root,
                function()
                    if self.m_callback then
                        self.m_callback()
                    end
                    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_RESUME_MACHINE_POPUPVIEW)
                    self:removeFromParent()
                end
            )
        else
            self:runCsbAction(
                "over",
                false,
                function()
                    if self.m_callback then
                        self.m_callback()
                    end
                    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_RESUME_MACHINE_POPUPVIEW)
                    self:removeFromParent()
                end
            )
        end
    else
        -- 引导打点：MoreGame引导-2.点击选择关卡
        if gLobalSendDataManager:getLogGuide():isGuideBegan(6) then
            gLobalSendDataManager:getLogGuide():sendGuideLog(6, 2)
        end
        if globalFireBaseManager.sendFireBaseLogDirect then
            globalFireBaseManager:sendFireBaseLogDirect("guideMoreGamesWindowBigClickGame", false)
        end
        for i = 1, #self.m_levelList do
            if name == "Panel_" .. i then
                -- self.m_levelList
                globalData.jump2Lobby2Level = true
                globalData.jump2Lobby2LevelId = self.m_levelList[i]
                globalData.jump2Lobby2LevelOrder = i
                self:gotoLobby()
            end
        end
    end
end

function GuideLevelup5Tip:gotoLobby()
    if self.m_closed == true then
        return
    end
    self.m_closed = true
    -- 进入大厅
    gLobalSendDataManager:getLogFeature():sendUIActionLog("GameGuide", "Click")
    release_print("GuideLevelup5Tip back to lobby!!!")
    gLobalViewManager:gotoSceneByType(SceneType.Scene_Lobby)
end

return GuideLevelup5Tip
