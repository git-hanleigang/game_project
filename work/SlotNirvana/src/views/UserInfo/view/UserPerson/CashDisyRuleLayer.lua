--规则界面
local CashDisyRuleLayer = class("CashDisyRuleLayer", BaseLayer)
function CashDisyRuleLayer:ctor(param)
    CashDisyRuleLayer.super.ctor(self)
    self:setExtendData("CashDisyRuleLayer")
    local path = "Activity/csd/Information_FramePartII/FramePartII_MainUI/FramePartII_MainUI_Rule.csb"
    self:setLandscapeCsbName(path)
    self.ManGer = G_GetMgr(G_REF.UserInfo)
    self.config = G_GetMgr(G_REF.UserInfo):getConfig()
    self:setShowActionEnabled(false)
    self.type = param.type
    self.data = param.data
    gLobalSoundManager:playSound(self.config.SoundPath.FRESH)
end

function CashDisyRuleLayer:initCsbNodes()
    self.node_frame = self:findChild("node_frame")
    self.lb_progress = self:findChild("lb_progress")
    self.sp_title = self:findChild("sp_title")
    self.node_btn = self:findChild("node_btn")
    self.lb_desc1 = self:findChild("lb_desc1")
    self.lb_desc2 = self:findChild("lb_desc2")
    local ScrollView = self:findChild("ScrollView_1")
    ScrollView:setScrollBarEnabled(false)
    self.lb_desc2:setVisible(false)
end

function CashDisyRuleLayer:initView()
    if self.type ~= 2 then
        local head_spr = G_GetMgr(G_REF.AvatarFrame):createAvatarFrameNode(self.data)
        if not head_spr then
            return
        end
        head_spr:setScale(0.7)
        self.node_frame:addChild(head_spr)
        self.node_btn:setVisible(false)
        self.lb_progress:setVisible(false)
        local item_data = self.ManGer:getAvrDataById(self.data)
        self.lb_desc1:setString(item_data.propFrame_desc)
        if self.type then
            self.sp_title:setVisible(false)
        end
        self:updateAvrTimeUI()
        self.m_avrTimeScheduler = schedule(self.lb_desc2, handler(self, self.updateAvrTimeUI), 1)
    else
        local frameId = self.data:getFrameId()
        local view = G_GetMgr(G_REF.AvatarFrame):createAvatarFrameNode(frameId)
        if not view then
            return
        end
        view:setScale(0.75)
        self.node_frame:addChild(view)
        local status = self.data:getStatus()
        local str = ""
        if status == 2 then
            self.sp_title:setVisible(false)
            self.node_btn:setVisible(false)
            self.lb_progress:setVisible(false)
            local time = self.data:getCompleteTime()
            local time_str = ""
            if time then
                local t = os.date("*t", time)
                time_str = string.format("%s %02d, %d", FormatMonth[t.month], t.day, t.year)
            end

            str = self.data.m_desc .. " in " .. self.data.m_slotGameName .. " on " .. time_str
        else
            local check_open = self:checkGameLevelOpen()
            if not check_open then
                self.node_btn:setVisible(false)
            end
            local curNum = self.data:getProgress()
            local limitNum = self.data:getLimitNum()
            local percent = 0
            if limitNum > 0 then
                percent = math.floor(curNum / limitNum * 100)
            end
            if percent ~= 0 then
                self.lb_progress:setString(percent .. "%")
            end
            local desc = self.data:getFrameLevelDesc()
            local name = string.upper(self.data.m_slotGameName)
            str = "Complete the " .. desc .. " challenge in " .. name
        end
        self.lb_desc1:setString(str)
        self.lb_desc2:setVisible(false)
    end
end

function CashDisyRuleLayer:updateAvrTimeUI()
    local timeStr = self.ManGer:getAvrPropTimeEndDes(self.data)
    self.lb_desc2:setString(timeStr or "")
    self.lb_desc2:setVisible(timeStr ~= nil)
    if not timeStr then
        self:clearScheduler()
    end
end

function CashDisyRuleLayer:onShowedCallFunc()
    self:runCsbAction(
        "start",
        false,
        function()
            self:runCsbAction("idle", true)
        end,
        60
    )
end

-- 大厅打开 关卡选择页面
function CashDisyRuleLayer:showChooseLevelLayer()
    --关闭个人信息页
    local _slotGameId = self.data.m_slotGameId
    self:closeUI(
        function()
            -- gLobalNoticManager:postNotification(self.config.ViewEventType.MAIN_CLOSE)
            local _callback = function()
                if globalData.GameConfig:checkChooseBetOpen() then
                    -- 打开 选择level界面
                    local view = util_createView("views.ChooseLevel.ChooseLevelLayer", _slotGameId)
                    gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
                else
                    gLobalViewManager:lobbyGotoGameScene(_slotGameId)
                end
            end
            G_GetMgr(G_REF.UserInfo):exitGame(_callback)
        end
    )
end

-- 关卡跳转关卡
function CashDisyRuleLayer:gotoOtherGameScene()
    local curMachineData = globalData.slotRunData.machineData
    if not curMachineData then
        return
    end
    if tostring(curMachineData.p_id) == tostring(self.data.m_slotGameId) then
        -- 同一个关卡 关闭个人信息页
        self:closeUI(
            function()
                -- gLobalNoticManager:postNotification(self.config.ViewEventType.MAIN_CLOSE)
                G_GetMgr(G_REF.UserInfo):exitGame()
            end
        )
        return
    end

    local gotoGameId = self.data.m_slotGameId
    if curMachineData:isHightMachine() then
        gotoGameId = "2" .. string.sub(tostring(gotoGameId) or "", 2)
    end

    -- self:removeFromParent()
    self:closeUI(
        function()
            -- gLobalNoticManager:postNotification(self.config.ViewEventType.MAIN_CLOSE)
            local _callback = function()
                gLobalNoticManager:postNotification(ViewEventType.CLOSE_USER_INFO_SCENE_GOTO_SCENE)
                gLobalViewManager:gotoSceneByLevelId(gotoGameId)
            end

            G_GetMgr(G_REF.UserInfo):exitGame(_callback)
        end
    )
    -- performWithDelay(display:getRunningScene(), function()
    --     gLobalViewManager:gotoSceneByLevelId(gotoGameId)
    -- end, 0.3)
end

-- 检查关卡是否开启
function CashDisyRuleLayer:checkGameLevelOpen()
    local curLv = globalData.userRunData.levelNum
    if curLv < 2 then
        -- 2023年04月04日15:21:05 玩家小于2级 不让显示进入关卡按钮
        return false
    end

    local machineData = globalData.slotRunData:getLevelInfoById(self.data.m_slotGameId)
    local levelOpenLv = tonumber(machineData.p_openLevel) or 1
    local bOpen = false
    if machineData and curLv >= levelOpenLv then
        bOpen = true
    else
        local cam = self.ManGer:getRecmd(machineData.p_name)
        if cam then
            bOpen = true
        end
    end

    return bOpen
end

function CashDisyRuleLayer:clickStartFunc(sender)
end

-- function CashDisyRuleLayer:closeUI()
--     CashDisyRuleLayer.super.closeUI(self)
-- end

function CashDisyRuleLayer:clickFunc(sender)
    local name = sender:getName()
    if name == "btn_close" then
        self:closeUI()
    elseif name == "btn_play" then
        if not self.data.m_slotGameId then
            return
        end

        local bOpen = self:checkGameLevelOpen()
        if not bOpen then
            return
        end

        if gLobalViewManager:isLobbyView() then
            self:showChooseLevelLayer()
        elseif gLobalViewManager:isLevelView() then
            self:gotoOtherGameScene()
        end
    end
end

function CashDisyRuleLayer:clearScheduler()
    if self.m_avrTimeScheduler then
        self:stopAction(self.m_avrTimeScheduler)
        self.m_avrTimeScheduler = nil
    end
end

return CashDisyRuleLayer
