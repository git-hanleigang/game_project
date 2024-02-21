local UserInfoCashItemCell = class("UserInfoCashItemCell", BaseView)

function UserInfoCashItemCell:initUI()
    self:createCsbNode("Activity/csd/Information_CashDice/Information_CashItem.csb")
    self.ManGer = G_GetMgr(G_REF.UserInfo)
    self.config = G_GetMgr(G_REF.UserInfo):getConfig()
    self:initView()
end

function UserInfoCashItemCell:initView()
    local btn_cell = self:findChild("btn_cell")
    btn_cell:setSwallowTouches(false)
    self.node_reward = self:findChild("node_reward")
    self:registerListener()
end

function UserInfoCashItemCell:updataCell(_data)
    self.solt_id = _data
   local icon = G_GetMgr(G_REF.AvatarFrame):createSlotTaskIconUI(_data)
   icon:setScale(0.8)
   self.node_reward:addChild(icon)
end

function UserInfoCashItemCell:clickCell()
    if not self.solt_id then
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

-- 大厅打开 关卡选择页面
function UserInfoCashItemCell:showChooseLevelLayer()
    --关闭个人信息页
    -- gLobalNoticManager:postNotification(self.config.ViewEventType.MAIN_CLOSE)  
    local _slotId = self.solt_id
    local _callback = function()
        if globalData.GameConfig:checkChooseBetOpen() then
            -- 打开 选择level界面
            local view = util_createView("views.ChooseLevel.ChooseLevelLayer", _slotId)
            gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
        else
            gLobalViewManager:lobbyGotoGameScene(_slotId)
        end
    end
    G_GetMgr(G_REF.UserInfo):exitGame(_callback)
end

-- 关卡跳转关卡
function UserInfoCashItemCell:gotoOtherGameScene()
    local curMachineData = globalData.slotRunData.machineData
    if not curMachineData then
        return
    end

    if tostring(curMachineData.p_id) == tostring(self.solt_id) then
        -- 同一个关卡 关闭个人信息页
        -- gLobalNoticManager:postNotification(self.config.ViewEventType.MAIN_CLOSE)
        G_GetMgr(G_REF.UserInfo):exitGame()
        return
    end

    local gotoGameId = self.solt_id
    if curMachineData:isHightMachine() then
        gotoGameId = "2" .. string.sub(tostring(gotoGameId) or "", 2)
    end

    -- gLobalNoticManager:postNotification(self.config.ViewEventType.MAIN_CLOSE)
    local _callback = function()
        gLobalNoticManager:postNotification(ViewEventType.CLOSE_USER_INFO_SCENE_GOTO_SCENE)
    -- performWithDelay(display:getRunningScene(), function()
        gLobalViewManager:gotoSceneByLevelId(gotoGameId)
    -- end, 0.3)
    end
    G_GetMgr(G_REF.UserInfo):exitGame(_callback)
end

-- 检查关卡是否开启
function UserInfoCashItemCell:checkGameLevelOpen()
    local machineData = globalData.slotRunData:getLevelInfoById(self.solt_id)
    local curLv = globalData.userRunData.levelNum
    local levelOpenLv = tonumber(machineData.p_openLevel) or 1
    local bOpen = false
    if machineData and curLv >= levelOpenLv then
        bOpen = true
    end

    return bOpen
end

function UserInfoCashItemCell:clickFunc(sender)
    local name = sender:getName()
    if name == "btn_cell" then
        self:clickCell()
    end
end

function UserInfoCashItemCell:registerListener()
end

function UserInfoCashItemCell:clickStartFunc(sender)
end

return UserInfoCashItemCell