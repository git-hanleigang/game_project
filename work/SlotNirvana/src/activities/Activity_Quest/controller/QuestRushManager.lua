-- FIX IOS 150 v463

local QuestRushNet = require("activities.Activity_Quest.net.QuestRushNet")
local QuestRushManager = class("QuestRushManager", BaseActivityControl)

function QuestRushManager:ctor()
    QuestRushManager.super.ctor(self)
    self:addPreRef(ACTIVITY_REF.Quest)
    self:setRefName(ACTIVITY_REF.QuestRush)
    self:registerObserver()

    self.m_questRushNet = QuestRushNet:getInstance()
end

function QuestRushManager:getConfig()
    if not self.m_config then
        self.m_config = util_getRequireFile("baseQuestCode/rush/Activity_QuestRushConfig")
    end

    return self.m_config
end

function QuestRushManager:registerObserver()
    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            if params and params[1] == true then
                -- spine 成功了数据
                local spinData = params[2]
                if not spinData or not spinData.extend or not spinData.extend.QuestChallenge then
                    return
                end

                local actData = self:getRunningData()
                if actData then
                    actData:parseData(spinData.extend.QuestChallenge)
                end
            end
        end,
        ViewEventType.NOTIFY_GET_SPINRESULT
    )
end

-- 充值 旧数据
function QuestRushManager:resetOldData()
    local actData = self:getRunningData()
    if actData then
        actData:resetOldData()
    end
end

-- 获取 奖励道具info
function QuestRushManager:getActGearInfo(_idx)
    local actData = self:getRunningData()
    if actData then
        return actData:getRewardDataByIdx(_idx)
    end
end

-- 获取 道具领取状态
function QuestRushManager:getActGearState(_idx, _bNew)
    local Activity_QuestRushConfig = self:getConfig()
    if not Activity_QuestRushConfig then
        return
    end

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
            return Activity_QuestRushConfig.ITEM_STATE.CANNOT
        elseif gearInfo.collected then
            -- 已领取
            return Activity_QuestRushConfig.ITEM_STATE.GAIN
        end

        -- 可以领取
        return Activity_QuestRushConfig.ITEM_STATE.UNGAIN
    end
end

function QuestRushManager:setCurMainView(_curMainView)
    self.m_curMainView = _curMainView
end
function QuestRushManager:getCurMainView(_curMainView)
    return self.m_curMainView
end

function QuestRushManager:setNeedRefreshProcess(bl_refresh)
    self.bl_refresh = bl_refresh
end

function QuestRushManager:getNeedRefreshProcess()
    return self.bl_refresh
end

-- 手动领取档位奖励
function QuestRushManager:sendReceiveGearRewardReq(_gear)
    local Activity_QuestRushConfig = self:getConfig()
    if not Activity_QuestRushConfig then
        return
    end

    local actData = self:getRunningData()
    if not actData then
        return
    end

    local gears = actData:getRushParts()
    if self:getActGearState(gears, true) == Activity_QuestRushConfig.ITEM_STATE.UNGAIN then
        self:resetOldData()
        self:setNeedRefreshProcess(true)
    else
        self:setNeedRefreshProcess(false)
    end

    local function successCallFunc(target, resData)
        gLobalNoticManager:postNotification(Activity_QuestRushConfig.EVENT_NAME.UPDATE_REWARD_ITEM_STATE)
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
        gLobalNoticManager:postNotification(Activity_QuestRushConfig.EVENT_NAME.RESET_ITEM_TOUCH_ENABLE)
    end

    local actId = self:getRunningData():getID()
    self.m_questRushNet:requestReward(actId, _gear, successCallFunc, failedCallFunc)
end

-- 是否 有新的进度
function QuestRushManager:checkGainNewProg()
    local actData = self:getRunningData()
    if not actData then
        return
    end

    local preStarNum = actData:getPreProcess()
    local curStarNum = actData:getCurProcess()

    return curStarNum > preStarNum
end

-- 获取 增加的星星
function QuestRushManager:getAddStarNum()
    local actData = self:getRunningData()
    if not actData then
        return
    end

    local preStarNum = actData:getPreProcess()
    local curStarNum = actData:getCurProcess()

    return curStarNum - preStarNum
end

-- 检测quest主界面是否需要 pop 活动弹板
function QuestRushManager:checkMainViewPopActPanel()
    local Activity_QuestRushConfig = self:getConfig()
    if not Activity_QuestRushConfig then
        return
    end

    local actData = self:getRunningData()
    if not actData then
        return
    end

    local gears = actData:getRushParts()

    for i = 1, gears do
        local gearState = self:getActGearState(i, true)
        if gearState == Activity_QuestRushConfig.ITEM_STATE.UNGAIN then
            return true
        end
    end

    return false
end

function QuestRushManager:getRushType()
    local actData = self:getRunningData()
    if actData and actData:isRunning() then
        release_print("QuestRushManager:getRushType is " .. tostring(actData:getRushType()))
        return actData:getRushType()
    end
end

function QuestRushManager:getDifficulty()
    local actData = self:getRunningData()
    if actData and actData:isRunning() then
        return actData:getDifficulty()
    end
end

-- 显示 主界面
function QuestRushManager:showMainView(callFunc)
    local actData = self:getRunningData()
    if not actData then
        if callFunc then
            callFunc()
        end
        return
    end

    local view = gLobalViewManager:getViewByExtendData("QuestRushMainlayer")
    if view then
        if callFunc then
            callFunc()
        end
        return
    end

    local themeName = actData:getThemeName()
    local view = util_createFindView("Activity/" .. themeName)
    if not view then
        if _cb then
            _cb()
        end
        return
    end
    view:setOverFunc(_cb)
    gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
    return view
end

return QuestRushManager:getInstance()
