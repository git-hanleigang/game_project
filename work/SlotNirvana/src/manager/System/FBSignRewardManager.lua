--[[
    首次链接fb奖励
]]
local NetWorkBase = util_require("network.NetWorkBase")
local FBSignRewardManager = class("FBSignRewardManager")

FBSignRewardManager.OPENTYPE = {
    POPVIEW = "fb_popView"
}

function FBSignRewardManager:ctor()
    self.m_netModel = gLobalNetManager:getNet("Activity") -- 网络模块
    self.m_isOpenA = false
    self.m_isOpenB = false
    self.m_openCount = 0
    self.m_cdTime = 3600
    local times = globalData.FBRewardData:getTimes()
    if times == 1 then
        self.m_isOpenB = true
        self.m_openCount = 3
    elseif times == 2 then
        self.m_isOpenB = true
        self.m_openCount = 2
        self.m_cdTime = 7200
    elseif times == 3 then
        self.m_openCount = 1
        self.m_cdTime = 0
    end
end

function FBSignRewardManager:getInstance()
    if not self._instance then
        self._instance = FBSignRewardManager:create()
    end
    return self._instance
end

function FBSignRewardManager:getRewardCoins()
    return globalData.FBRewardData:getCoins()
end

function FBSignRewardManager:openGroupView()
    if self.m_isOpenA and self:checkNewNovice() then
        local openFlag = self:getTimeAndCountState(self.OPENTYPE.POPVIEW)
        if openFlag then
            local view = util_createView("Activity.Activity_FBGroup")
            if view then
                self:saveData(self.OPENTYPE.POPVIEW)
                gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
            end
        else
            self.m_isOpenA = false
        end
    end
end

function FBSignRewardManager:openFBGuide()
    if self.m_isOpenB and self:checkNewNovice() then
        local openFlag = self:getTimeAndCountState(self.OPENTYPE.POPVIEW)
        if openFlag then
            -- local view = util_createView("views.newbieTask.FBGuideLayer")
            local view = util_createView("views.newbieTask.FBGuideLayerNew")
            if view then
                gLobalSendDataManager:getLogIap():setEnterOpen("PushOpen", LOG_ENUM_TYPE.BindFB_GamePop)
                gLobalSendDataManager:getLogFeature():sendOpenNewLevelLog("Open", {pn = "FaceBookBind"})
                self:saveData(self.OPENTYPE.POPVIEW)
                gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
            end
        end
    end
end

function FBSignRewardManager:setOpenGroupState()
    self.m_isOpenA = true
end

function FBSignRewardManager:getTimeAndCountState(_type)
    local time = os.time()
    local saveTime = gLobalDataManager:getNumberByField(_type, 0, true) -- 保存的上次打开时间
    if time - saveTime <= self.m_cdTime then
        return false
    end

    local openTime = gLobalDataManager:getNumberByField(_type .. "Count", 0, true)
    if openTime >= self.m_openCount then
        return false
    end

    return true
end

function FBSignRewardManager:saveData(_type)
    self.m_isOpenA = false

    local time = os.time()
    gLobalDataManager:setNumberByField(_type, time) -- 保存的上次打开时间

    local openTime = gLobalDataManager:getNumberByField(_type .. "Count", 0, true)
    if openTime < self.m_openCount then
        gLobalDataManager:setNumberByField(_type .. "Count", openTime + 1)
    end
end

function FBSignRewardManager:isOpenReward()
    if globalData.userRunData.fbUdid ~= nil and globalData.userRunData.fbUdid ~= "" then
        if not globalData.FBRewardData:getFBReward() then
            return true
        end
    end

    return false
end

function FBSignRewardManager:openFBReward()
    local view = util_createView("views.sysReward.FBRewardView")
    if view then
        gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
    end
end

function FBSignRewardManager:sendReward(_coins)
    local tbData = {
        data = {
            params = {}
        }
    }

    gLobalViewManager:addLoadingAnima(false, 1)

    local successCallback = function(_result)
        gLobalViewManager:removeLoadingAnima()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_FB_SIGN_REWARD, true)
    end

    local failedCallback = function(errorCode, errorData)
        gLobalViewManager:removeLoadingAnima()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_FB_SIGN_REWARD, false)
    end

    self.m_netModel:sendActionMessage(ActionType.FacebookRewardData, tbData, successCallback, failedCallback)
end

--[[
    @desc: 新版fb 弹板优化
    author:符合 abtest 第三期的 用户分组 需要判断等级是否符合
    time:2021-09-23 13:18:48
]]
function FBSignRewardManager:checkNewNovice()
    if globalData.userRunData.levelNum < globalData.constantData.NOVICE_FACEBOOK_GROUP_OPENLEVEL then
        return false
    end

    return true
end

--[[
    @desc: fb 检测是否有生日礼物
]]
function FBSignRewardManager:checkHasBirthdayReward()
    -- if globalData.userRunData.fbUdid ~= nil and globalData.userRunData.fbUdid ~= "" then
    if globalData.FBBirthdayRewardData and globalData.FBBirthdayRewardData:getCoins() > 0 then
        return true
    end
    -- end
    return false
end

function FBSignRewardManager:showBirthdayRewardLayer()
    if not globalDynamicDLControl:checkDownloaded("FbFansBirthday") then
        return
    end

    local view = util_createView("views.sysReward.FBBirthdayRewardLayer")
    if view then
        gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
    end
end

function FBSignRewardManager:sendCollectBirthdayReward(_successCallFun, _failedCallFun)
    local failedFunc = function()
        if _failedCallFun then
            _failedCallFun()
        end
    end

    local successFunc = function(resJson)
        if _successCallFun then
            _successCallFun(resJson)
        end
    end
    -- 组装数据发送
    local actionData = NetWorkBase:getSendActionData(ActionType.BirthdayRewardData)
    local params = {}
    actionData.data.params = json.encode(params)
    NetWorkBase:sendMessageData(actionData, successFunc, failedFunc)
end
return FBSignRewardManager
