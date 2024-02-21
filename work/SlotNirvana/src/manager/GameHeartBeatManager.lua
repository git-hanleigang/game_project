local GameHeartBeatManager = class("GameHeartBeatManager")

GameHeartBeatManager.m_instance = nil

GameHeartBeatManager.pushList = nil
GameHeartBeatManager.schedulerID = nil
function GameHeartBeatManager:getInstance()
    if GameHeartBeatManager.m_instance == nil then
        GameHeartBeatManager.m_instance = GameHeartBeatManager.new()
    end
    return GameHeartBeatManager.m_instance
end

-- 构造函数
function GameHeartBeatManager:ctor()
end

function GameHeartBeatManager:readNotifyConfig()
    --默认值
    local defalueFlag = false
    if globalData.constantData.WINNER_NOTIFICATIONS_FLAG and globalData.constantData.WINNER_NOTIFICATIONS_FLAG == 1 then
        defalueFlag = true
    end
    local isFirstFlag = gLobalDataManager:getBoolByField("FIRST_WINNER_NOTIFICATIONS", false)
    --如果配置默认关闭  并且首次标签没有设置 强制关闭通知
    if not defalueFlag and not isFirstFlag then
        --第一次默认强制关闭
        gLobalDataManager:setBoolByField("FIRST_WINNER_NOTIFICATIONS", true)
        gLobalDataManager:setBoolByField(WINNER_NOTIFICATIONS, false)
        globalData.jackpotPushFlag = false
    else
        globalData.jackpotPushFlag = gLobalDataManager:getBoolByField(WINNER_NOTIFICATIONS, defalueFlag)
    end
end

-- 构造函数
function GameHeartBeatManager:startHeartBeat()
    self:readNotifyConfig()
    self:stopHeartBeat()
    local scheduler = cc.Director:getInstance():getScheduler()
    self.schedulerID =
        scheduler:scheduleScriptFunc(
        function()
            -- 存在重连弹窗或后台不发心跳
            local reconnView = gLobalViewManager:findReconnectView()
            if reconnView then
                return
            end
            gLobalSendDataManager:getNetWorkHeartBeat():sendHeartBeat(
                function(resultData)
                    local extra = resultData.extra
                    local tbExtra = {}
                    if extra and extra ~= "" then
                        tbExtra = cjson.decode(extra)
                    end
                    self:checkForceUpdate(resultData.version, tbExtra.t)
                end,
                function()
                end
            )
        end,
        globalData.constantData.BIG_REWARD_INTERVEL,
        false
    )
end

function GameHeartBeatManager:stopHeartBeat()
    if self.schedulerID then
        local scheduler = cc.Director:getInstance():getScheduler()
        scheduler:unscheduleScriptEntry(self.schedulerID)
        self.schedulerID = nil
    end
end

-- 判断是否强制热更
function GameHeartBeatManager:checkForceUpdate(forceVer, forceTime)
    if device.platform == "mac" then
        return
    end

    local isFroce = false
    -- 热更版本判断
    forceVer = tonumber(forceVer) or 0
    local curVer = util_getUpdateVersionCode()
    isFroce = (forceVer > curVer)

    -- 最近登陆时间判断
    forceTime = tonumber(forceTime or 0)
    local lastLoginTime = globalData.userRunData.m_lastLoginTime
    if lastLoginTime > 0 and forceTime > 0 and lastLoginTime < forceTime then
        isFroce = isFroce or true
    end

    if isFroce then
        local okFunc = function()
            util_restartGame()
        end
        -- 弹出强制更新弹框
        local _view = gLobalViewManager:showDialog("Dialog/Reconnect.csb", okFunc, nil, nil, ViewZorder.ZORDER_NETWORK)
        if _view then
            if _view.setKeyBackEnabled then
                _view:setKeyBackEnabled(false)
            end

            if _view.setAutoCloseUI then
                _view:setAutoCloseUI(10, nil, okFunc)
            end
        end
        if gLobalSendDataManager and gLobalSendDataManager.getLogGameLoad and gLobalSendDataManager:getLogGameLoad().sendNetErrorLog then
            local errorInfo = {
                errorCode = "normal",
                errorMsg = "normal:client force update to restart!!!"
            }
            gLobalSendDataManager:getLogGameLoad():sendNetErrorLog(errorInfo, "ForceUpdate")
        end
        self:stopHeartBeat()
    end
end

function GameHeartBeatManager:commonForeGround()
    if gLobalSendDataManager:isLogin() then
        self:startHeartBeat()
    end
end

function GameHeartBeatManager:commonBackGround()
    self:stopHeartBeat()
end

return GameHeartBeatManager
