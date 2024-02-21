--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-11-30 10:23:53
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-11-30 11:59:56
FilePath: /SlotNirvana/src/GameModule/OperateGuidePopup/controller/OperateGuidePopupMgr.lua
Description: 运营弹板 引导
--]]
local OperateGuidePopupMgr = class("OperateGuidePopupMgr", BaseGameControl)
local PopupSiteArchiveData = util_require("GameModule.OperateGuidePopup.model.PopupSiteArchiveData")

-- 系统引导 rateUs, 绑定fb, 绑定邮箱，打开推送
function OperateGuidePopupMgr:ctor()
    OperateGuidePopupMgr.super.ctor(self)

    self:setRefName(G_REF.OperateGuidePopup)
    self._archiveData = PopupSiteArchiveData:create()
    self:setDataModule("GameModule.OperateGuidePopup.model.OperateGuidePopupData")
    gLobalNoticManager:addObserver(self, "saveGuideArchiveData", ViewEventType.NOTIFY_RESTART_GAME_CLEAR)
end

function OperateGuidePopupMgr:getArchiveData()
    return self._archiveData
end
function OperateGuidePopupMgr:initServerExtraSaveData(_data)
    self:getArchiveData():initServerExtraSaveData(_data)
end
function OperateGuidePopupMgr:initServerExtraSaveData_CD(_siteCdInfo, _popupCDInfo)
    self:getArchiveData():initServerExtraSaveData_CD(_siteCdInfo, _popupCDInfo)
end
-- 获取网络 obj
function OperateGuidePopupMgr:getNetObj()
    if self.m_net then
        return self.m_net
    end
    self.m_net = util_require("GameModule.OperateGuidePopup.net.OperateGuidePopupNet")
    return self.m_net
end

-- cxc 2023年12月11日14:45:12 点击不同星 延长 评分弹板 被动弹出CD
function OperateGuidePopupMgr:clickRateUsStarCount(_starCount)
    -- 评分5星以下每低1星，评分弹板 CD增加 24小时 
    local cd = (5 - _starCount) * globalData.constantData.RATE_US_LAYER_ONE_STAR_ADD_CD
    gLobalDataManager:setNumberByField("RateUsPopupAddCD", cd)
end
function OperateGuidePopupMgr:getRateUsPopupAddCD()
    local cd = gLobalDataManager:getNumberByField("RateUsPopupAddCD", 0)
    return cd
end

-- cxc 2023年12月12日16:23:02 获取spinWin触发了几次弹板
function OperateGuidePopupMgr:getSpinWinTriggerCount()
    return self._archiveData:getSiteCount("SpinWin")
end

-- 监测 引导弹板
function OperateGuidePopupMgr:checkPopGuideLayer(_site, _subSite)
    -- cxc 2023年12月01日12:03:45 有插屏广告 不支持此功能
    if globalData.adsRunData:hasInterstitialAdsInfo() then
        return
    end

    if not _site then
        return
    end

    local data = self:getData()
    if not data then
        return
    end

    local config
    local bUseSpecialSpinWin
    local bUseLegendaryWinV2
    if _site == "SpinWin" then
        local bigWinType = tonumber(string.match(_subSite or "", "SpinWin_(%d+)")) or 1
        -- 新加 Legendary Win 点位 评论过 弹平台应用内评价弹板（native)
        if _subSite and bigWinType == 4 and globalData.rateUsData:checkIsRateUs() then
            config = data:getPopupLayerInfo("LegendaryWinV2", _subSite)
            bUseLegendaryWinV2 = config ~= nil
        end

        -- 大赢 优先检测下 Legendary Win
        if not config and _subSite and bigWinType == 4 then
            config = data:getPopupLayerInfo("SpecialSpinWin", _subSite)
            bUseSpecialSpinWin = config ~= nil
        end
    end
    if not config then
        -- 获取 可使用的 弹板配置
        config = data:getPopupLayerInfo(_site, _subSite)
    end
    if not config then
        return
    end

    if bUseSpecialSpinWin then
        _site = "SpecialSpinWin"
    end
    if bUseLegendaryWinV2 then
        _site = "LegendaryWinV2"
    end
    local view = self:createPopupLayer(config, _site, _subSite)
    if view  then
        if _site == "SpinWin" or _site == "SpecialSpinWin" or _site == "LegendaryWinV2" then
            -- 大赢 弹过弹板后 需要 清空 点位  spin次数 计数
            globalData.rateUsData:resetSpinCount()

            if _site == "SpecialSpinWin" or _site == "LegendaryWinV2" then
                -- 特殊 大赢 记录下自己的，并清空普通SpinWin的
               self._archiveData:setSiteCount("SpinWin")
               self._archiveData:recordSiteTime("SpinWin")
           end

           local bigWinType = tonumber(string.match(_subSite or "", "SpinWin_(%d+)")) or 1
           data:resetSpinWinTypeCount(bigWinType)
        elseif _site == "GrandWin" then
            -- 大赢 弹过弹板后 需要 清空 点位  spin次数 计数
            globalData.rateUsData:resetSpinCount()
            
            -- 20级以上，在关卡中Grand的档次Spin结算之后弹出，触发优先级高于SpinWin、SpecailWin和SpecailWinV2，触发的时候不会触发前面几个点。单独弹板，弹板CD为0，点位CD24小时。触发的时候重置SpinWin和SpecailWin的点位CD。另外，没有Grand分享或没有Grand的关卡不弹。
            self._archiveData:recordSiteTime("SpecialSpinWin")
            self._archiveData:recordSiteTime("SpinWin")
        end
        -- 记录 本次 点位触发的 次数  时间
        self._archiveData:setSiteCount(_site)
        self._archiveData:recordSiteTime(_site)
        -- 记录 本次 弹板触发的 时间
        self._archiveData:recordPopupTime(config:getPopupType())

        -- 保存服务器 存档 信息
        local siteCountInfo = self._archiveData:getSiteCountInfo()
        local siteCDInfo = self._archiveData:getSiteCDInfo()
        local popupCDInfo = self._archiveData:getPopupCDInfo()
        self:getNetObj():sendSaveSiteCountInfoReq(siteCountInfo, siteCDInfo, popupCDInfo)
    end
    return view
end

-- 创建引导的 弹板
function OperateGuidePopupMgr:createPopupLayer(_popupLayerCfgData, _site, _subSite)
    if not _popupLayerCfgData then
        return
    end

    local popupType = _popupLayerCfgData:getPopupType()
    local view
    if popupType == "NativeScore" and _site == "LegendaryWinV2" then
        -- 该点位要 弹 应用内 评分弹板 （能弹弹 不能 弹拉倒）
        view = BaseView:create()
        gLobalViewManager:showUI(view)
        performWithDelay(view, function()
            view:removeFromParent()
        end,0.5)

        -- 能弹弹 不能弹拉倒 不用特意判断 平台限额规则， 也不用跳转到应用商店
        globalPlatformManager:openRateUSDialog()
    elseif popupType == "Score" then
        -- rateUs评分
        view = self:showRateUsLayer(_site)
    elseif popupType == "FB" then
        -- 绑定fb界面
        view = self:showBindFbLayer(_site)
    elseif popupType == "Mail" then
        -- 绑定邮箱界面
        view = self:showBindEmailLayer(_site)
    elseif popupType == "OpenPush" then
        -- 打开推送界面
        view = self:showNotificationDialog()
    end

    return view
end

-- 显示rateUs评分 界面
function OperateGuidePopupMgr:showRateUsLayer(_site)
    if gLobalViewManager:getViewByName("RateusLayer") then
        return
    end

    local view = util_createView("views.rateUs.RateusLayer", _site, false)
    -- 重置 评分弹板 弹板CD
    gLobalDataManager:setNumberByField("RateUsPopupAddCD", 0)
    self:showLayer(view, ViewZorder.ZORDER_UI)
    return view
end

-- 显示 绑定fb界面
function OperateGuidePopupMgr:showBindFbLayer(_site)
    if gLobalViewManager:getViewByName("FBGuideLayerNew") then
        return
    end

    local view = util_createView("views.newbieTask.FBGuideLayerNew")
    if view then
        gLobalSendDataManager:getLogIap():setEnterOpen("PushOpen", _site)
        gLobalSendDataManager:getLogFeature():sendOpenNewLevelLog("Open", {pn = "FaceBookBind"})
    end
    self:showLayer(view, ViewZorder.ZORDER_UI)
    return view
end

-- 显示 绑定邮箱界面
function OperateGuidePopupMgr:showBindEmailLayer(_site)
    if gLobalViewManager:getViewByName("UserInfoBindEmail") then
        return
    end

    local view = util_createView("views.UserInfo.view.UserInfoBindEmail")
    if view then
        gLobalSendDataManager:getLogIap():setEnterOpen("PushOpen", _site)
        gLobalSendDataManager:getLogFeature():sendOpenNewLevelLog("Open", {pn = "SinboxBind"})
    end
    self:showLayer(view, ViewZorder.ZORDER_UI)
    return view
end

-- 打开推送界面
function OperateGuidePopupMgr:showNotificationDialog(_site)
    local okFunc = function()
        globalPlatformManager:sendPlatformMsg(globalPlatformManager.OPEN_NOTIFY_ENABLED)
    end
    local view = util_createView("views.dialogs.DialogLayer", "Dialog/OpenNotification.csb", okFunc)
    if view then
        view:setButtonLabelContent("btn_ok", "YES")
        gLobalSendDataManager:getLogIap():setEnterOpen("PushOpen", _site)
        gLobalSendDataManager:getLogFeature():sendOpenNewLevelLog("Open", {pn = "PushOpenDialog"})
    end
    self:showLayer(view, ViewZorder.ZORDER_UI)
    return view
end

-- 引导点位，cd等 归档
function OperateGuidePopupMgr:saveGuideArchiveData()
    self._archiveData:saveArchiveData() 
end

return OperateGuidePopupMgr