-- FIX IOS 150 v463

local QuestNewRushNet = require("activities.Activity_QuestNew.net.QuestNewRushNet")
local QuestNewRushManager = class("QuestNewRushManager", BaseActivityControl)

function QuestNewRushManager:ctor()
    QuestNewRushManager.super.ctor(self)
    self:addPreRef(ACTIVITY_REF.QuestNew)
    self:setRefName(ACTIVITY_REF.QuestNewRush)
    self:registerObserver()

    self.m_questRushNet = QuestNewRushNet:getInstance()
end

function QuestNewRushManager:registerObserver()
    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            if params and params[1] == true then
                -- spine 成功了数据
                local spinData = params[2]
                if not spinData or not spinData.extend or not spinData.extend.QuestNewChallenge then
                    return
                end

                local actData = self:getRunningData()
                if actData then
                    actData:parseData(spinData.extend.QuestNewChallenge)
                end
            end
        end,
        ViewEventType.NOTIFY_GET_SPINRESULT
    )
end

-- 充值 旧数据
function QuestNewRushManager:resetOldData()
    local actData = self:getRunningData()
    if actData then
        actData:resetOldData()
    end
end

-- 获取 奖励道具info
function QuestNewRushManager:getActGearInfo(_idx)
    local actData = self:getRunningData()
    if actData then
        return actData:getRewardDataByIdx(_idx)
    end
end

-- 获取 道具领取状态
function QuestNewRushManager:getActGearState(_idx, _bNew)
    
    local actData = self:getRunningData()
    if not actData then
        return
    end

    local curStarNum = actData:getPreProcess()
    if _bNew then
        curStarNum = actData:getCurProcess()
    end
    local gearInfo = actData:getRewardDataByIdx(_idx)
    if gearInfo then
        local gearStarNum = actData:getConditionByIdx(_idx)
        if tonumber(curStarNum) < tonumber(gearStarNum) then
            -- 不可领取
            return 1  -- 不能领取 CANNOT = 1
        elseif gearInfo.collected then
            -- 已领取
            return 3   -- 已领取 GAIN = 3 
        end
        -- 可以领取
        return 2  -- 可以领取但是未领取   UNGAIN = 2
    end
end

function QuestNewRushManager:setCurMainView(_curMainView)
    self.m_curMainView = _curMainView
end
function QuestNewRushManager:getCurMainView(_curMainView)
    return self.m_curMainView
end

function QuestNewRushManager:setNeedRefreshProcess(bl_refresh)
    self.bl_refresh = bl_refresh
end

function QuestNewRushManager:getNeedRefreshProcess()
    return self.bl_refresh
end

-- 手动领取档位奖励
function QuestNewRushManager:sendReceiveGearRewardReq(_gear)

    local actData = self:getRunningData()
    if not actData then
        return
    end

    local gears = actData:getRushParts()
    if self:getActGearState(gears, true) == 2 then  -- 可以领取但是未领取 UNGAIN = 2
        self:resetOldData()
        self:setNeedRefreshProcess(true)
    else
        self:setNeedRefreshProcess(false)
    end

    local function successCallFunc(target, resData)
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_NEWQUESTRUSH_UPDATE_REWARD_ITEM_STATE)
        self:resetOldData()
        if CardSysManager:needDropCards("Quest Rush") == true then
            gLobalNoticManager:addObserver(
                self,
                function(sender, func)
                    gLobalNoticManager:removeObserver(self, ViewEventType.NOTIFY_CARD_SYS_OVER)
                    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_DROP_DELUXE_CARD_ITEM)
                end,
                ViewEventType.NOTIFY_CARD_SYS_OVER
            )
            CardSysManager:doDropCards("Quest Rush")
        else
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_DROP_DELUXE_CARD_ITEM)
        end
    end

    local function failedCallFunc(target, code, errorMsg)
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_NEWQUESTRUSH_RESET_ITEM_TOUCH_ENABLE)
    end

    local actId = self:getRunningData():getID()
    self.m_questRushNet:requestReward(actId, _gear, successCallFunc, failedCallFunc)
end

-- 是否 有新的进度
function QuestNewRushManager:checkGainNewProg()
    local actData = self:getRunningData()
    if not actData then
        return
    end

    local preStarNum = actData:getPreProcess()
    local curStarNum = actData:getCurProcess()

    return curStarNum > preStarNum
end

-- 获取 增加的星星
function QuestNewRushManager:getAddStarNum()
    local actData = self:getRunningData()
    if not actData then
        return
    end

    local preStarNum = actData:getPreProcess()
    local curStarNum = actData:getCurProcess()

    return curStarNum - preStarNum
end

-- 检测quest主界面是否需要 pop 活动弹板
function QuestNewRushManager:checkMainViewPopActPanel()
    local actData = self:getRunningData()
    if not actData then
        return
    end

    local gears = actData:getRushParts()

    for i = 1, gears do
        local gearState = self:getActGearState(i, true)
        if gearState == 2 then -- 可以领取但是未领取 UNGAIN = 2
            return true
        end
    end

    return false
end

function QuestNewRushManager:getRushType()
    local actData = self:getRunningData()
    if actData and actData:isRunning() then
        release_print("QuestNewRushManager:getRushType is " .. tostring(actData:getRushType()))
        return actData:getRushType()
    end
end

function QuestNewRushManager:getDifficulty()
    local actData = self:getRunningData()
    if actData and actData:isRunning() then
        return actData:getDifficulty()
    end
end

-- 显示 主界面
function QuestNewRushManager:showMainView(callFunc)
    local actData = self:getRunningData()
    if not actData then
        if callFunc then
            callFunc()
        end
        return
    end

    local view = gLobalViewManager:getViewByExtendData("QuestNewRushMainlayer")
    if view then
        if callFunc then
            callFunc()
        end
        return
    end

    local themeName = actData:getThemeName()
    local view = util_createFindView("Activity/" .. themeName)
    if not view then
        if callFunc then
            callFunc()
        end
        return
    end
    view:setOverFunc(callFunc)
    gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
    return view
end

return QuestNewRushManager:getInstance()
