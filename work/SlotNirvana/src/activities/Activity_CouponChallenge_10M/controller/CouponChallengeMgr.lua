--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{hl}
    time:2022-04-14 14:44:52
    describe:10M每日任务送优惠券管理模块
]]
local CouponChallengeNet = require("activities.Activity_CouponChallenge_10M.net.CouponChallengeNet")
local CouponChallengeMgr = class("CouponChallengeMgr", BaseActivityControl)

function CouponChallengeMgr:ctor()
    CouponChallengeMgr.super.ctor(self)
    self:setRefName(ACTIVITY_REF.CouponChallenge)
    self.m_netModel = CouponChallengeNet:getInstance() -- 网络模块
end

-- 请求砸锤子
function CouponChallengeMgr:requestBreak()
    -- 解析道具数据
    local parseItemsData = function(_data)
        local itemsData = {}
        if _data and #_data > 0 then
            for i, v in ipairs(_data) do
                local ShopItem = require "data.baseDatas.ShopItem"
                local tempData = ShopItem:create()
                tempData:parseData(v)
                table.insert(itemsData, tempData)
            end
        end
        return itemsData
    end
    local successCallback = function(_result)
        local result = parseItemsData(_result.coupon)
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_COUPONCHALLENGE_SMASH, result)
    end
    local failCallback = function()
        gLobalViewManager:showReConnect()
    end
    self.m_netModel:requestBreak(successCallback, failCallback, {})
end

-- 积分商店兑换
function CouponChallengeMgr:requestExchange(_itemId, _itemNum)
    local successCallback = function(_result)
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_COUPONCHALLENGE_EXCHANGE, _result)
    end
    local failCallback = function()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_COUPONCHALLENGE_EXCHANGE, false)
    end
    local params = {itemId = _itemId, num = _itemNum}
    self.m_netModel:requestExchange(successCallback, failCallback, params)
end

-- 积分商店刷新
function CouponChallengeMgr:requestShopRefresh()
    local successCallback = function(_result)
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_COUPONCHALLENGE_UPDATESHOP)
    end
    local failCallback = function()
        gLobalViewManager:showReConnect()
    end
    self.m_netModel:requestShopRefresh(successCallback, failCallback, {})
end

function CouponChallengeMgr:showMainLayer()
    local uiView = self:showPopLayer()
    return uiView
end

function CouponChallengeMgr:isCanShowPop()
    local isExist = gLobalViewManager:getViewByExtendData("Activity_CouponChallenge_10M")
    return not isExist
end

-- 打开每日任务&赛季任务界面
function CouponChallengeMgr:showMission()
    gLobalDailyTaskManager:createDailyMissionPassMainLayer()
end

-- 打开积分商城
function CouponChallengeMgr:showShopLayer()
    local view = util_createView("Activity.CouponChallenge.CouponChallengeShopLayer")
    gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
    return view
end

function CouponChallengeMgr:playBgMusic()
    gLobalSoundManager:playBgMusic("Activity/10M/sound/couponChallengeBgm.mp3")
    self.m_preMusicName = gLobalSoundManager.m_preMusicName
end

-- 切换背景音乐
function CouponChallengeMgr:stopBgMusic()
    if gLobalViewManager:isLobbyView() then
        if self:isQuestLobby() then
            gLobalSoundManager:playBgMusic("Activity/QuestSounds/Quest_bg.mp3")
        elseif self:isInDailyMission() then
            gLobalSoundManager:playBgMusic(DAILYPASS_RES_PATH.PASS_MISSION_BGM_MP3)
        else
            --上线兼容使用方式
            local lobbyBgmPath = "Sounds/bkg_lobby_new.mp3"
            if gLobalActivityManager.getLobbyMusicPath then
                lobbyBgmPath = gLobalActivityManager:getLobbyMusicPath()
            end
            gLobalSoundManager:playBgMusic(lobbyBgmPath)
        end
    else
        --关卡中
        if self.m_preMusicName then
            gLobalSoundManager:playBgMusic(self.m_preMusicName)
            self.m_preMusicName = nil
        end
    end
end

function CouponChallengeMgr:isQuestLobby()
    local questConfig = G_GetMgr(ACTIVITY_REF.Quest):getRunningData()
    --串一行
    if questConfig and questConfig.m_isQuestLobby then
        return true
    end
    if G_GetMgr(ACTIVITY_REF.QuestNew):isEnterQuestLayer() then
        return true
    end

    return false
end

function CouponChallengeMgr:isInDailyMission()
    if gLobalViewManager:getViewByName("DailyMissionPassMainLayer") ~= nil then
        return true
    end
    return false
end

return CouponChallengeMgr
