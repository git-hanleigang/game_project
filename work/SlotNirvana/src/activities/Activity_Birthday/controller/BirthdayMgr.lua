--[[
    生日 管理层
]]
local BirthdayNet = require("activities.Activity_Birthday.net.BirthdayNet")
local BirthdayMgr = class("BirthdayMgr", BaseActivityControl)

function BirthdayMgr:ctor()
    BirthdayMgr.super.ctor(self)
    self:setRefName(ACTIVITY_REF.Birthday)

    self.m_netModel = BirthdayNet:getInstance() -- 网络模块

    -- 零点刷新消息
    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            self:insertHallAndSlide()
        end,
        ViewEventType.NOTIFY_ACTIVITY_ZERO_REFRESH
    )
end

function BirthdayMgr:parseBirthdayInformation(_data)
    local data = self:getRunningData()
    if data then
        data:parseData(_data)
    end
end

function BirthdayMgr:isCanShowLayer()
    -- 集卡新手期
    local isNovice = CardSysManager:isNovice()
    if isNovice then
        return false
    end
    return BirthdayMgr.super.isCanShowLayer(self)
end

function BirthdayMgr:isCanShowPromotionLayer()
    local data = self:getRunningData()
    if data and data:getSaleExpirAt() <= 0 then
        return false
    end
    return self:isCanShowLayer()
end

-- 是否可显示展示页
function BirthdayMgr:isCanShowHall()
    if not self:isDownloadLobbyRes() then
        return false
    end

    -- 集卡新手期
    local isNovice = CardSysManager:isNovice()
    if isNovice then
        return false
    end

    local data = self:getRunningData()
    if not data then
        return false
    end

    if (data.isSleeping and data:isSleeping()) then
        -- 无数据或在睡眠中
        return false
    end

    local isBirthdaySaleData = data:isBirthdaySaleData()
    if not isBirthdaySaleData then
        return false
    end

    return true
end

function BirthdayMgr:getHallPath(hallName)
    return "views.lobby.LevelBirthdaySaleHallNode"
end

-- 是否可显示轮播页
function BirthdayMgr:isCanShowSlide()
    if not self:isDownloadLobbyRes() then
        return false
    end

    -- 集卡新手期
    local isNovice = CardSysManager:isNovice()
    if isNovice then
        return false
    end

    local data = self:getRunningData()
    if not data then
        return false
    end

    if (data.isSleeping and data:isSleeping()) then
        -- 无数据或在睡眠中
        return false
    end

    local isBirthdaySaleData = data:isBirthdaySaleData()
    if not isBirthdaySaleData then
        return false
    end

    return true
end

function BirthdayMgr:getSlidePath(slideName)
    return "views.lobby.LevelBirthdaySaleSlideNode"
end

-- 插入生日促销轮播图和广告位
function BirthdayMgr:insertHallAndSlide()
    if self:isCanShowHall() then -- isCanShowSlide俩判断都一样，判断一个即可
        local params = {}
        params.hall = {info = {feature = {key = "BirthdaySaleHall"}}, index = 1}
        params.slide = {luaName = "views.lobby.LevelBirthdaySaleSlideNode", order = 4, key = "LevelBirthdaySaleSlide"}
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_LOBBY_INSERT_HALL_AND_SLIDE, params)
    end
end

----------------------------------------------- 华丽分割线 -----------------------------------------------
-- 请求修改生日信息
function BirthdayMgr:requestEditBirthday(_params)
    local successFunc = function(resData)
        self:parseBirthdayInformation(resData)
        self:insertHallAndSlide()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_BIRTHDAY_REQUEST_EDIT, true)
    end

    local failedCallFunc = function()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_BIRTHDAY_REQUEST_EDIT, false)
    end
    self.m_netModel:requestEditBirthday(_params, successFunc, failedCallFunc)
end

-- 生日礼品领取
function BirthdayMgr:requestCollectBirthdayGift(params)
    local successFunc = function(resData)
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_BIRTHDAY_REQUEST_COLLECT_GIFT, resData)
    end

    local failedCallFunc = function()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_BIRTHDAY_REQUEST_COLLECT_GIFT, false)
    end
    self.m_netModel:requestCollectBirthdayGift(params, successFunc, failedCallFunc)
end

-- 请求购买生日促销
function BirthdayMgr:requestBuyBirthdaySale()
    local successFunc = function()
        gLobalViewManager:checkBuyTipList(
            function()
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_BIRTHDAY_REQUEST_BUY, true)
            end
        )
    end

    local failedCallFun = function()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_BIRTHDAY_REQUEST_BUY, false)
    end
    self.m_netModel:requestBuyBirthdaySale(successFunc, failedCallFun)
end

----------------------------------------------- 华丽分割线 -----------------------------------------------
-- 蛋糕界面【1】
function BirthdayMgr:showBirthdayCandieLayer()
    if not self:isCanShowLayer() then
        return nil
    end
    if gLobalViewManager:getViewByExtendData("ActivityBirthdayCandieLayer") then
        return nil
    end
    local view = util_createView("Activity_Birthday/ActivityBirthdayCandieLayer")
    if view then
        self:showLayer(view, ViewZorder.ZORDER_UI)
    end
    return view
end

-- 生日界面【2】
function BirthdayMgr:showBirthdayLayer()
    if not self:isCanShowLayer() then
        return nil
    end
    if gLobalViewManager:getViewByExtendData("ActivityBirthdayLayer") then
        return nil
    end
    local view = util_createView("Activity_Birthday/ActivityBirthdayLayer")
    if view then
        self:showLayer(view, ViewZorder.ZORDER_UI)
    end
    return view
end

-- 礼物界面【3】
function BirthdayMgr:showBirthdayGiftLayer()
    if not self:isCanShowLayer() then
        return nil
    end
    if gLobalViewManager:getViewByExtendData("ActivityBirthdayGiftLayer") then
        return nil
    end
    local view = util_createView("Activity_Birthday/ActivityBirthdayGiftLayer")
    if view then
        self:showLayer(view, ViewZorder.ZORDER_UI)
    end
    return view
end

-- 奖励界面【4】
function BirthdayMgr:showBirthdayRewardLayer()
    if not self:isCanShowLayer() then
        return nil
    end
    if gLobalViewManager:getViewByExtendData("ActivityBirthdayRewardLayer") then
        return nil
    end
    local view = util_createView("Activity_Birthday/ActivityBirthdayRewardLayer")
    -- 检查资源完整性
    if view then
        self:showLayer(view, ViewZorder.ZORDER_UI)
    end
    return view
end

-- 促销界面
function BirthdayMgr:showBirthdayPromotionLayer()
    if not self:isCanShowPromotionLayer() then
        return nil
    end
    if gLobalViewManager:getViewByExtendData("ActivityBirthdayPromotionLayer") then
        return nil
    end
    local view = util_createView("Activity_Birthday/ActivityBirthdayPromotionLayer")
    -- 检查资源完整性
    if view then
        self:showLayer(view, ViewZorder.ZORDER_UI)
    end
    return view
end

return BirthdayMgr
