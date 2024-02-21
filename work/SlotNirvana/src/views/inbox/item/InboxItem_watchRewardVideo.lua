

local InboxItem_base = util_require("views.inbox.item.InboxItem_baseNoReward")
local InboxItem_watchRewardVideo = class("InboxItem_watchRewardVideo",InboxItem_base)


function InboxItem_watchRewardVideo:initView()
    InboxItem_watchRewardVideo.super.initView(self)
    --每次打开如有过 inbox reward 要展示的话 ，一定要发一次trigger 
    --[[
        author:cxc
        time: 2022-03-03 12:17:46 
        打点部门表示不用管的问题
            1. 有广告邮件 玩家频繁打开关闭邮件 报送， (数据量应该不是很大不用管)
            2. 有多条广告邮件，每条邮件都创建seesionId, 如果玩家点击广告又报送可能seesionId跟踪不对 （不用管照常打点）
    ]]
    gLobalSendDataManager:getLogAds():createPaySessionId()
    gLobalSendDataManager:getLogAds():setOpenSite(PushViewPosType.InboxReward)
    gLobalSendDataManager:getLogAds():setOpenType("PushOpen")
    gLobalSendDataManager:getLogAdvertisement():setOpenSite(PushViewPosType.InboxReward)
    gLobalSendDataManager:getLogAdvertisement():setOpenType("PushOpen")
    gLobalSendDataManager:getLogAdvertisement():setType("Incentive")
    gLobalSendDataManager:getLogAdvertisement():setadType("Push")
    gLobalSendDataManager:getLogAdvertisement():sendAdsLog()
    globalFireBaseManager:checkSendFireBaseLog({taskOpenSite = PushViewPosType.InboxReward})
end

function InboxItem_watchRewardVideo:getCsbName()
    return "InBox/InboxItem_adRewards_new.csb"
end
-- 描述说明
function InboxItem_watchRewardVideo:getDescStr()
    local adsInfo = globalData.adsRunData:getAdsInfoForPos(PushViewPosType.InboxReward)
    local coin = adsInfo.p_coins
    if globalData.adsRunData:isGuidePlayAds() then
        if globalData.adsRunData.p_firstCoins then
            --第一次引导
            coin = globalData.adsRunData.p_firstCoins
        end
    end
    return "Free Bonus Awaits ! Watch a\nVideo to Get " .. util_formatCoins(tonumber(coin),7) .. " Coins."
end

function InboxItem_watchRewardVideo:clickFunc(sender)
    if G_GetMgr(G_REF.Inbox):getInboxCollectStatus() then
        return
    end
    
    local name = sender:getName()
    if name == "btn_inbox" then
        G_GetMgr(G_REF.Inbox):setInboxCollectStatus(true)
        -- 播放激励视频
        if globalData.adsRunData:isPlayRewardForPos(PushViewPosType.InboxReward) then
            gLobalViewManager:addLoadingAnima()

            globalFireBaseManager:checkSendFireBaseLog({taskOpenSite = PushViewPosType.InboxReward},nil,"click")
            --设置标识符
            G_GetMgr(G_REF.Inbox):setWatchRewardVideoFalg(true)
            
            gLobalAdsControl:playRewardVideo(PushViewPosType.InboxReward)
        end
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_INBOX_CLOSE)
    end
end

function InboxItem_watchRewardVideo:onEnter()
    gLobalNoticManager:addObserver(
        self,
        function(target, params)           
            if self.removeSelfItem then
                self:removeSelfItem()
            end
        end,
        ViewEventType.NOTIFY_PLAY_REWARD_VIDEO_COMPLETE
    )
end

function InboxItem_watchRewardVideo:onExit()
    gLobalNoticManager:removeAllObservers(self)
end

return InboxItem_watchRewardVideo