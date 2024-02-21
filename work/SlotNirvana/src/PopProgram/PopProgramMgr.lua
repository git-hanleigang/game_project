--[[
    弹出模块名管理
    author:{author}
    time:2019-09-10 12:21:31
]]
-- 功能模块名
-- GD.ProgramCfg = {
--     -- 升级
--     LevelUp = {name = "LevelUp", type = "Sys"}
-- }

-- 弹板类型
GD.PopUpType = {
    Sys = "Sys",
    Activity = "Activity",
    Pos = "Pos",
    OnlyLogic = "OnlyLogic"
}

-- 弹框步骤信息
GD.PopStep = {
    Promotion_MultiSpan = {popKey = ""},
    BasicSaleLayer = {popKey = ""},
    -- 升级弹框
    NormalLevelUp = {name = "NormalLevelUp", program = "LevelUp", popKey = "LevelUp_Pop"},
    -- 升级下拉
    NumberLevelUp = {name = "NumberLevelUp", program = "LevelUp", popKey = "LevelUp_Normal"},
    -- 升级膨胀提示
    LevelUpExpendTip = {name = "LevelUpExpendTip", program = "LevelUp", popKey = "LevelUp_ExpandTip"},
    -- 升级解锁关卡
    NewLevelUnlock = {name = "NewLevelUnlock", program = "Levels", popKey = ""},
    -- 点位弹板，跳转到对应点位
    levelUp = {name = "levelUp", type = "Pos", popKey = "PopPos_LevelUp"}
}

-- 关卡挂件 活动的挂件在各自模块加入表
-- GD.LevelPendantProgram = {
--     "CashBack",
--     "SpinToWin",
--     "SuperMegaWinner",
--     "WinBoost"
-- }

-- 大厅挂件 活动的挂件在各自模块加入表
-- GD.HallPendantProgram = {
--     "Quest"
-- }

local PopProgramMgr = class("PopProgramMgr")

function PopProgramMgr:getInstance()
    if not self._instance then
        self._instance = PopProgramMgr.new()
    end
    return self._instance
end

function PopProgramMgr:ctor()
end

--[[
    @desc: 是否是活动模块
    author:{author}
    time:2019-10-10 11:37:49
    --@programName: 功能模块名
    @return:
]]
function PopProgramMgr:isActivityProgram(popUpInfo)
    if popUpInfo and popUpInfo.type == PopUpType.Activity then
        return true
    end
    return false
end

-- 系统模块主页面
function PopProgramMgr:getSysModule(popStepName, popUpInfo)
    local popStep = PopStep[popStepName]
    if not popStep then
        return nil
    end

    local _info = popUpInfo
    if not _info then
        return nil
    end

    if _info.type ~= PopUpType.Sys then
        return nil
    end

    local _modulePath = UIDefine.UI_KEY[popStep.popKey]
    if not _modulePath or _modulePath == "" then
        return nil
    end
    return _modulePath
end

-- 弹板显示层级
function PopProgramMgr:getPopZOrder(popStepName)
    local defZOder = UIDefine.ViewZorder.ZORDER_POP
    local popStep = PopStep[popStepName]
    if popStep and popStep.zOrder then
        local popZOrder = UIDefine.ViewZorder[popStep.zOrder]
        if popZOrder then
            return defZOder
        end
    end
    return defZOder
end

--[[
    @desc: 显示模块弹板
    author:{author}
    time:2019-10-14 15:33:59
    --@programName: 
    @return:
]]
function PopProgramMgr:showPopView(popUpInfo)
    local popStep = PopStep[popUpInfo:getPopupName()]
    if not popStep then
        return false
    end

    local programName = popUpInfo:getRefName()
    if self:isActivityProgram(popUpInfo) then
        local activityObj = G_GetActivityDataByRef(programName)
        if activityObj and activityObj.onShowPopView then
            local showFunc = function()
                local _view = activityObj:onShowPopView(popUpInfo:getPopId(), popStep)
                if _view then
                    -- _view:setAutoCloseDelay(tonumber(popUpInfo:getAutoCloseDelay()))
                end
            end
            -- 异常处理方式执行func
            local status, result = xpcall(showFunc, debug.traceback)
            if status then
                return true
            else
                printInfo(result)
                return false
            end
        end
    elseif popUpInfo:getType() == PopUpType.Pos then
        return self:jumpToPopPos(popStep.popKey)
    elseif popStep.type == PopUpType.OnlyLogic then
        return self:jumpToPopLogic(popStep, popUpInfo)
    else
        -- 获取对应的UI模块，
        local _uiModule = self:getSysModule(popStep.name, popUpInfo)
        if _uiModule and _uiModule ~= "" then
            local _view = SceneUIManager:createView(_uiModule, self:getPopZOrder(popStep.name))
            if _view then
                -- _view:setAutoCloseDelay(tonumber(popUpInfo:getAutoCloseDelay()))
                -- EventManager:dispatchInnerEvent(EventProtocol.Event_PopView, popUpInfo)
                return true
            else
                return false
            end
        end
    end

    return false
end

-- 跳转到弹框队列点位
function PopProgramMgr:jumpToPopPos(posType)
    local pos = PopViewPos[posType]
    if not pos then
        return false
    end

    PushViewManager:showView(
        pos,
        function()
        end
    )

    return true
end

-- 无弹板的队列逻辑
function PopProgramMgr:jumpToPopLogic(popStep, popUpInfo)
    if popStep.name == "NoviceGuideTask" or popStep.name == "NoviceGuideBet" then
        EventManager:dispatchInnerEvent(EventProtocol.NOVICE_POP_TIPS)
        return true
    end
    return false
end

-- 获取轮播页模块路径
-- function PopProgramMgr:getCarouseModule(programName)
--     local _info = ProgramCfg[programName]
--     if not _info then
--         return nil
--     end
--     if _info.type == "Sys" then
--         local _modulePath = UIDefine.UI_KEY[_info.carouseKey]
--         if not _modulePath or _modulePath == "" then
--             return nil
--         end
--         return _modulePath
--     elseif _info.type == "Activity" then
--         -- 获得活动轮播页路径
--         local activity = G_GetActivityDataByRef(programName)
--         if activity and activity.getCarouseUI then
--             return activity:getCarouseUI()
--         else
--             return nil
--         end
--     else
--         return nil
--     end
-- end

--[[
    @desc: 获得关卡右下挂件
    author:{author}
    time:2019-10-09 20:30:13
    @programName: 功能模块名
    @return:
]]
-- function PopProgramMgr:getLevelPendantModule(programName)
--     local _info = ProgramCfg[programName]
--     if not _info then
--         return nil
--     end
--     if _info.type == "Sys" then
--         local _modulePath = UIDefine.UI_KEY[_info.pendantKey]
--         if not _modulePath or _modulePath == "" then
--             return nil
--         end
--         return _modulePath
--     elseif _info.type == "Activity" then
--         -- 获得活动轮播页路径
--         local activity = G_GetActivityDataByRef(programName)
--         if activity and activity.getLevelPendantUI then
--             return activity:getLevelPendantUI()
--         else
--             return nil
--         end
--     else
--         return nil
--     end
-- end

--[[
    @desc: 获得大厅挂件
    author:{author}
    time:2019-10-09 20:30:13
    @programName: 功能模块名
    @return:
]]
-- function PopProgramMgr:getHallPendantModule(programName)
--     local _info = ProgramCfg[programName]
--     if not _info then
--         return nil
--     end
--     if _info.type == "Sys" then
--         local _modulePath = nil --UIDefine.UI_KEY[_info.pendantKey]
--         if not _modulePath or _modulePath == "" then
--             return nil
--         end
--         return _modulePath
--     elseif _info.type == "Activity" then
--         -- 获得活动轮播页路径
--         local activity = G_GetActivityDataByRef(programName)
--         if activity and activity.getHallPendantUI then
--             return activity:getHallPendantUI()
--         else
--             return nil
--         end
--     else
--         return nil
--     end
-- end

--[[
    @desc: 功能模块是否激活
    author:{author}
    time:2019-10-10 13:58:40
    --@programName: 
    @return:
]]
-- function PopProgramMgr:checkProgramIsAlive(programName)
--     if self:isActivityProgram(programName) then
--         local activity = G_GetActivityDataByRef(programName)
--         if not activity then
--             return false
--         end

--         if activity:isEnd() then
--             return false
--         end

--         if not self:checkProgramOpenLevel(programName) then
--             return false
--         end

--         return true
--     elseif programName == PopStep.CashBack.program then
--         local _level = globalData.userRunData.levelNum
--         local _cashBack = BuffManager:getBuff("cashBack")
--         if math.fmod(_level, 10) == 4 or _cashBack then
--             return true
--         else
--             return false
--         end
--     elseif programName == PopStep.LevelUpExpendTip.program then
--         return true
--     else
--         return false
--     end
-- end

-- 检查模块开启等级
-- function PopProgramMgr:checkProgramOpenLevel(programName)
--     if self:isActivityProgram(programName) then
--         return true
--     else
--         local curLevel = globalData.userRunData.levelNum

--         -- 判断开启等级,等级不达标，则活动不激活
--         local _openLv = UserData.m_Constants[programName .. "OpenLevel"]
--         if _openLv and tonumber(_openLv) > curLevel then
--             return false
--         end

--         return true
--     end
-- end

GD.PopProgramMgr = PopProgramMgr:getInstance()
