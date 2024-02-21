--[[
    --新版每日任务pass主界面 保险箱
    csc 2021-06-25
]]
local DailyMissionThreeLinePassSafeBoxCell = class("DailyMissionThreeLinePassSafeBoxCell", util_require("base.BaseView"))

function DailyMissionThreeLinePassSafeBoxCell:initDatas(isPortrait)
    self.m_isPortrait = isPortrait
end

function DailyMissionThreeLinePassSafeBoxCell:initUI()
    self:createCsbNode(self:getCsbName())

    self:initCsbNodes()
end

function DailyMissionThreeLinePassSafeBoxCell:initCsbNodes()
    -- 读取csb 节点
    self.m_nodeUnCompletedPass = self:findChild("node_unComplted_1") -- 为完成pass进度
    self.m_nodeUnLock = self:findChild("node_unUnlock") -- 未购买 pass ticket
    self.m_nodeUnLockedNoPass = self:findChild("node_unComplted_2") -- 购买了pass ticket 但是未完成进度
    self.m_nodeNormalShow = self:findChild("node_normal") -- 正常显示领奖

    self.m_barProgress = self:findChild("bar_progress")
    self.m_labNum = self:findChild("lb_num")
    self.m_btnTouch = self:findChild("btn_touch")
    self.m_btnBuy = self:findChild("btn_buy")
    self.m_nodeEffect = self:findChild("sp_node_guang")
    self.m_labTotalNum = self:findChild("lb_desc")

    self.m_particle = self:findChild("ef_lizidingduan")
    self.m_particle:stopSystem()
end

function DailyMissionThreeLinePassSafeBoxCell:getCsbName()
    if self.m_isPortrait then
        return DAILYPASS_RES_PATH.DailyMissionPass_PassSafeBoxCell_ThreeLine_Vertical
    else
        return DAILYPASS_RES_PATH.DailyMissionPass_PassSafeBoxCell_ThreeLine
    end 
end

-- 刷新数据
function DailyMissionThreeLinePassSafeBoxCell:updateData(_pointsInfo, _index)
    -- if self.m_csbAct == nil or tolua.isnull(self.m_csbAct) then
    --     self.m_csbAct = util_actCreate( self:getCsbName() )
    --     self.m_csbNode:runAction( self.m_csbAct )
    -- end
    self.m_pointsInfo = _pointsInfo
    self.m_index = _index
    self:updateView()
end

function DailyMissionThreeLinePassSafeBoxCell:updateView()
    self.m_nodeUnCompletedPass:setVisible(false)
    self.m_nodeUnLock:setVisible(false)
    self.m_nodeUnLockedNoPass:setVisible(false)
    self.m_nodeNormalShow:setVisible(false)

    -- 移除动效节点
    -- self.m_nodeEffect:removeAllChildren()
    local efNode = self.m_nodeEffect:getChildByName("NodeBoxCellEf")
    if not efNode then
        local effectPath = DAILYPASS_RES_PATH.DailyMissionPass_SafeBoxCell_Effect
        local effect = util_createAnimation(effectPath)
        effect:setName("NodeBoxCellEf")
        self.m_nodeEffect:addChild(effect)
        efNode = effect
    end
    efNode:playAction("idle", true, nil, 60)

    -- 刷新状态
    self:updateStatus()
end

function DailyMissionThreeLinePassSafeBoxCell:updateStatus()
    local actData = G_GetMgr(ACTIVITY_REF.NewPass):getRunningData()
    if actData then
        local actionName = "idle"
        -- 优先级判断当前是否 通关pass
        if G_GetMgr(ACTIVITY_REF.NewPass):getIsMaxPoints() then
            -- 判断是否购买过pass ticket
            if actData:isUnlocked() or actData:getCurrIsPayHigh() then -- 解锁
                self.m_nodeNormalShow:setVisible(true) -- 展示正常有进度条的节点
                self:updateProgress()
                actionName = "idle_open"
            else
                self.m_nodeUnLock:setVisible(true)
                actionName = "animationidle"
            end
        else
            -- 判断是否购买过pass ticket
            if actData:isUnlocked() or actData:getCurrIsPayHigh() then -- 解锁
                self.m_nodeUnLockedNoPass:setVisible(true)
                actionName = "idle_open"
            else
                self.m_nodeUnCompletedPass:setVisible(true)
            end
        end
        self:runCsbActCheck(actionName, true, nil, 60)
    end
end

function DailyMissionThreeLinePassSafeBoxCell:updateProgress()
    -- 更新进度条状态
    local curExp = self.m_pointsInfo:getCurPickNum()
    local totelExp = self.m_pointsInfo:getTotalNum()
    if self.m_bShowMax then
        curExp = totelExp
    end
    local strPer = curExp .. "/" .. totelExp
    self.m_labNum:setString(strPer)

    local per = math.floor(tonumber(curExp) / tonumber(totelExp) * 100)
    self.m_barProgress:setPercent(per)

    self.m_labTotalNum:setString(totelExp)
end

function DailyMissionThreeLinePassSafeBoxCell:runCsbActCheck(_actName, _repeat, _func, _frame)
    self:reloadCsb()
    self:runCsbAction(_actName, _repeat, _func, _frame)
end

function DailyMissionThreeLinePassSafeBoxCell:reloadCsb()
    if self.m_csbAct == nil or tolua.isnull(self.m_csbAct) then
        self.m_csbAct = util_actCreate(self:getCsbName())
        self.m_csbNode:runAction(self.m_csbAct)
    end
end

------------------------------- 外部调用方法 ------------------------
function DailyMissionThreeLinePassSafeBoxCell:getTouchNode(_nodeType)
    if _nodeType == "qipao" then
        -- end
        -- if self.m_nodeNormalShow:isVisible() then
        return self.m_btnTouch
    elseif _nodeType == "buy" then
        if self.m_nodeUnLock:isVisible() then
            return self.m_btnBuy
        end
    end
end

function DailyMissionThreeLinePassSafeBoxCell:onClick(_nodeType)
    gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
    if _nodeType == "buy" then
        print("------ DailyMissionThreeLinePassSafeBoxCell buy")
        gLobalDailyTaskManager:createBuyPassTicketLayer()
    elseif _nodeType == "qipao" then
        -- 展示气泡
        print("------ DailyMissionThreeLinePassSafeBoxCell qipao")
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_DAILYPASS_SHOW_REWARD_INFO, {boxType = "safeBox", level = self.m_index})
    end
end

function DailyMissionThreeLinePassSafeBoxCell:isCellByLevel(_level)
    if _level == self.m_index then
        return true
    end
    return false
end

function DailyMissionThreeLinePassSafeBoxCell:showUnlockAction()
    -- 这里需要播放一条解锁时间线 --
    self:runCsbActCheck(
        "open",
        false,
        function()
            self:updateStatus()
        end,
        60
    )
end

function DailyMissionThreeLinePassSafeBoxCell:updateBoxStatus(_max)
    if G_GetMgr(ACTIVITY_REF.NewPass):getInSafeBoxStatus() then
        self.m_bShowMax = _max
        local newPassCellData = G_GetMgr(ACTIVITY_REF.NewPass):getRunningData():getPassPointsInfo()
        local pointData = newPassCellData[#newPassCellData]
        local data = pointData.safeBoxInfo
        self:updateData(data, self.m_index)
    end
end

function DailyMissionThreeLinePassSafeBoxCell:beforeClose()
    self:stopAllActions()
end

return DailyMissionThreeLinePassSafeBoxCell
