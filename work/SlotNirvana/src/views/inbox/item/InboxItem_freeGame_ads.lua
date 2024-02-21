-- free spin 免费次数奖励邮件

local InboxItem_freeGame_ads = class("InboxItem_freeGame_ads", util_require("views.inbox.item.InboxItem_base"))

function InboxItem_freeGame_ads:getCsbName()
    -- 默认皮肤
    local res_path = "InBox/FreeSpin_Common.csb"

    local freeSpinData = globalData.iapRunData:getFreeGameData()
    local ticketData = freeSpinData:getRewardsById( self.m_mailData.ticketId )
    if ticketData then
         -- 设置图片
        local levelName = ticketData:getLevelName()
        local levelId = ticketData:getLevelId()
        local levelData = globalData.slotRunData:getLevelInfoById(levelId)  -- 数据结构：MachineData
        if levelName and levelData then
            --特殊关卡皮肤
            res_path = "InBox/FreeSpin_" .. levelName .. ".csb"
        end
    end
    return res_path
end

function InboxItem_freeGame_ads:initView()
    self:readNodes()
    self:updateUI()
    self:updateTime()
    -- 做一个自动进入的功能
    performWithDelay(
        self,
        function()
            self:checkAutoActive()
        end,
        0.5
    )

    --每次打开如有过 inbox reward 要展示的话 ，一定要发一次trigger
    --[[
        author:cxc
        time: 2022-03-03 12:17:46 
        打点部门表示不用管的问题
            1. 有广告邮件 玩家频繁打开关闭邮件 报送， (数据量应该不是很大不用管)
            2. 有多条广告邮件，每条邮件都创建seesionId, 如果玩家点击广告又报送可能seesionId跟踪不对 （不用管照常打点）
    ]]
    gLobalSendDataManager:getLogAds():createPaySessionId()
    gLobalSendDataManager:getLogAds():setOpenSite(PushViewPosType.InboxFreeSpin)
    gLobalSendDataManager:getLogAds():setOpenType("PushOpen")
    gLobalSendDataManager:getLogAdvertisement():setOpenSite(PushViewPosType.InboxFreeSpin)
    gLobalSendDataManager:getLogAdvertisement():setOpenType("PushOpen")
    gLobalSendDataManager:getLogAdvertisement():setType("Incentive")
    gLobalSendDataManager:getLogAdvertisement():setadType("Push")
    gLobalSendDataManager:getLogAdvertisement():sendAdsLog()
    globalFireBaseManager:checkSendFireBaseLog({taskOpenSite = PushViewPosType.InboxFreeSpin})
end

function InboxItem_freeGame_ads:readNodes()
    self.m_lb_time = self:findChild("txt_time")
    self.m_lb_desc = self:findChild("txt_desc")
    self.m_btn_collect = self:findChild("btn_collect")
    self.m_btn_continue = self:findChild("btn_continue")
    self.m_btn_watch = self:findChild("btn_watch")
    if self.m_btn_collect then
        self.m_btn_collect:setSwallowTouches(false)
    end
    if self.m_btn_continue then
        self.m_btn_continue:setSwallowTouches(false)
    end
    if self.m_btn_watch then
        self.m_btn_watch:setSwallowTouches(false)
    end
end

function InboxItem_freeGame_ads:updateUI()
    if self.m_mailData.ticketId == -1 then
        -- 当前是需要看视频广告的id,不用刷新数据，只需要设置按钮状态
        self.m_btn_watch:setVisible(true)

        self.m_btn_collect:setVisible(false)
        self:setButtonLabelDisEnabled("btn_collect", false)
        
        self.m_btn_continue:setVisible(false)
        self:setButtonLabelDisEnabled("btn_continue", false)

        local str = "FREE SPIN GIFT\nUP TO 30 FREE GAMES!"
        self.m_lb_desc:setString(str)
        return
    else
        self.m_btn_watch:setVisible(false)
        self:setButtonLabelDisEnabled("btn_watch", false)
        
        -- 数据无效 移除
        local freeSpinData = globalData.iapRunData:getFreeGameData()
        local ticketData = freeSpinData:getRewardsById(self.m_mailData.ticketId)
        if not ticketData or ticketData:isOverdue() then
            self:hideTicket()
            return
        end
        
        local levelId = ticketData:getLevelId()
        local levelData = globalData.slotRunData:getLevelInfoById(levelId) -- 数据结构：MachineData
        if not levelData then
            self:hideTicket()
            return
        end
        
        local counts = ticketData:getCounts()
        if counts <= 0 then
            self:hideTicket()
            return
        end

        local str = "FREE SPIN GIFT\n"
        if counts > 1 then
            str = str .. counts .. " FREE GAMES FOR YOU!"
        elseif counts == 1 then
            str = str .. counts .. " FREE GAME FOR YOU!"
        end
        self.m_lb_desc:setString(str)
        self:setButtonEnabled()
    end
end

function InboxItem_freeGame_ads:setButtonEnabled()
    local freeSpinData = globalData.iapRunData:getFreeGameData()
    local ticketData = freeSpinData:getRewardsById(self.m_mailData.ticketId)
    if not ticketData then
        return
    end
    local enabled = self:checkLevelEnable()
    if self.m_btn_collect then
        self.m_btn_collect:setVisible(not ticketData:isActive())
        self:setButtonLabelDisEnabled("btn_collect", enabled)
    end
    if self.m_btn_continue then
        self.m_btn_continue:setVisible(ticketData:isActive())
        self:setButtonLabelDisEnabled("btn_continue", enabled)
    end
end

function InboxItem_freeGame_ads:updateTime()
    if self.m_mailData.ticketId == -1 then
        -- 当前是需要看视频广告的id,不用刷新数据，只需要设置按钮状态
        return
    end
    --无数据或者过期了
    local freeSpinData = globalData.iapRunData:getFreeGameData()
    local ticketData = freeSpinData:getRewardsById(self.m_mailData.ticketId)
    if not ticketData or ticketData:isOverdue() then
        if self.m_schedule then
            self:stopAction(self.m_schedule)
            self.m_schedule = nil
        end

        self:hideTicket()
        return
    end

    if ticketData:isActive() then
        self.m_lb_time:setString("ONGOING")
    else
        local expireTime = ticketData.expireAt - util_getCurrnetTime()
        local timeStr = util_daysdemaining1(expireTime)
        self.m_lb_time:setString(timeStr)

        if expireTime > 1 then
            if not self.m_schedule then
                self.m_schedule =
                    schedule(
                    self,
                    function()
                        self:updateTime()
                    end,
                    1
                )
            end
        end
    end
end

function InboxItem_freeGame_ads:clickFunc(sender)
    -- 如果不是在大厅场景内 不响应
    if not gLobalViewManager:isLobbyView() then
        return
    end

    local name = sender:getName()
    if name == "btn_collect" then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        self:sendCollectMail()
    elseif name == "btn_continue" then
        local freeSpinData = globalData.iapRunData:getFreeGameData()
        local ticketData = freeSpinData:getRewardsById(self.m_mailData.ticketId)
        if ticketData and ticketData:isActive() then
            if not self:checkLevelEnable() then
                return
            end
            self:enterLevel()
        else
            gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
            self:sendCollectMail()
        end
    elseif name == "btn_watch" then
        -- 播放激励视频
        if globalData.adsRunData:isPlayRewardForPos(PushViewPosType.InboxFreeSpin) then
            gLobalViewManager:addLoadingAnima()

            globalFireBaseManager:checkSendFireBaseLog({taskOpenSite = PushViewPosType.InboxFreeSpin}, nil, "click")
            gLobalAdsControl:playRewardVideo(PushViewPosType.InboxFreeSpin)
        end
    end
end

function InboxItem_freeGame_ads:sendCollectMail()
    if not self:checkLevelEnable() then
        return
    end

    gLobalViewManager:addLoadingAnimaDelay()
    local freeSpinData = globalData.iapRunData:getFreeGameData()
    local ticketData = freeSpinData:getRewardsById(self.m_mailData.ticketId)
    if not ticketData then
        return
    end
    local ticketId = ticketData:getOrder()
    gLobalSendDataManager:getNetWorkFeature():sendFreeGameActive(
        ticketId,
        function(target, resData)
            gLobalViewManager:removeLoadingAnima()
            if not tolua.isnull(self) then
                if self.enterLevel then
                    self:enterLevel()
                end
            end
        end,
        function(target, errorCode)
            gLobalViewManager:removeLoadingAnima()
            if errorCode and errorCode == 10 then
                return
            end
            gLobalViewManager:showReConnect()
        end
    )
end

function InboxItem_freeGame_ads:checkLevelEnable()
    if not gLobalViewManager:isLobbyView() then
        return
    end

    local freeSpinData = globalData.iapRunData:getFreeGameData()
    local ticketData = freeSpinData:getRewardsById(self.m_mailData.ticketId)
    if not ticketData then
        return
    end
    -- 数据无效
    if not ticketData or ticketData:isOverdue() then
        return false
    end

    local levelId = ticketData:getLevelId()
    local levelData = globalData.slotRunData:getLevelInfoById(levelId) -- 数据结构：MachineData
    if not levelData then
        return false
    end

    --敬请期待
    if levelData.p_levelName == "CommingSoon" then
        return false
    end

    --维护中
    if levelData.p_maintain then
        return false
    end

    --根据app版本检测关卡是否可以进入
    if not gLobalViewManager:checkEnterLevelForApp(levelId) then
        return false
    end

    --未解锁
    local curLevel = globalData.userRunData.levelNum
    local openLevel = levelData.p_openLevel
    if tonumber(curLevel) < tonumber(openLevel) then
        return false
    end

    local notifyName = util_getFileName(levelData.p_csbName)
    if globalDynamicDLControl:checkDownloading(notifyName) then
        --入口未下载
        return false
    end

    if levelData.p_fastLevel then
        return true
    end

    if levelData.p_freeOpen and gLobaLevelDLControl:isUpdateFreeOpenLevel(levelData.p_levelName, levelData.p_levelName.p_md5) == false then
        return true
    end

    --0未下载 1已下载未更新 2已下载已更新
    return (gLobaLevelDLControl:isDownLoadLevel(levelData) == 2)
end

function InboxItem_freeGame_ads:checkAutoActive()
    if self.m_mailData.ticketId == -1 then
        return
    end
    local freeSpinData = globalData.iapRunData:getFreeGameData()
    local ticketData = freeSpinData:getRewardsById(self.m_mailData.ticketId)
    if ticketData and not ticketData:isActive() then
        -- 直接进入关卡
        self:sendCollectMail()
    end
end

--进入关卡
function InboxItem_freeGame_ads:enterLevel()
    if not self:checkLevelEnable() then
        return
    end

    local freeSpinData = globalData.iapRunData:getFreeGameData()
    local ticketData = freeSpinData:getRewardsById(self.m_mailData.ticketId)
    if not ticketData then
        return
    end

    local levelId = ticketData:getLevelId()
    local levelData = globalData.slotRunData:getLevelInfoById(levelId) -- 数据结构：MachineData
    if not levelData then
        return
    end
    
    gLobalAdChallengeManager:setAdsFreeSpin(true)
    
    gLobalViewManager:gotoSlotsScene(levelData)
end

function InboxItem_freeGame_ads:collectMailFail()
end

function InboxItem_freeGame_ads:hideTicket()
    if self.isHide then
        return
    end
    self.isHide = true
    G_GetMgr(G_REF.Inbox):getDataMessage(
        function()
            if self.removeSelfItem ~= nil then
                self:removeSelfItem()
            end
        end,
        function()
            self.isHide = false
        end
    )
end

function InboxItem_freeGame_ads:removeSelfItem()
    if self.m_isRemoveSelf then
        return
    end
    self.m_isRemoveSelf = true

    self:setButtonLabelDisEnabled("btn_collect", false)
    self:setButtonLabelDisEnabled("btn_continue", false)
    self:setButtonLabelDisEnabled("btn_watch", false)
    --刷新界面
    self.m_removeMySelf(self)
end

function InboxItem_freeGame_ads:onEnter()
    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            gLobalViewManager:removeLoadingAnima()

            if self.removeSelfItem then
                self:removeSelfItem()
            end
        end,
        ViewEventType.NOTIFY_PLAY_REWARD_VIDEO_COMPLETE
    )
end

function InboxItem_freeGame_ads:onExit()
    gLobalNoticManager:removeAllObservers(self)
    if self.m_schedule then
        self:stopAction(self.m_schedule)
        self.m_schedule = nil
    end
end

-- function InboxItem_freeGame_ads:getExpireTime()
--     --无数据或者过期了
--     local freeSpinData = globalData.iapRunData:getFreeGameData()
--     local ticketData = freeSpinData:getRewardsById( self.m_mailData.ticketId )
--     if not ticketData or ticketData:isOverdue() then
--         return
--     end

--     if ticketData:isActive() then
--         return -100
--     else
--         return ticketData.expireAt
--     end
-- end

return  InboxItem_freeGame_ads
