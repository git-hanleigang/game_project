local BaseLobbyNodeUI = util_require("baseActivity.BaseLobbyNodeUI")
local LobbyBottom_CardNode = class("LobbyBottom_CardNode", BaseLobbyNodeUI)

-- 节点特殊ui 配置相关 --
function LobbyBottom_CardNode:initUI(data)
    LobbyBottom_CardNode.super.initUI(self, data)
    self:setLogFuncClickInfo(
        {
            siteType = "Lobby",
            clickName = "Card",
            site = 0
        }
    )
end

function LobbyBottom_CardNode:initView()
    self:updateView()
end


function LobbyBottom_CardNode:initCsbNodes()
    LobbyBottom_CardNode.super.initCsbNodes(self)

    self.m_timeBg = self:findChild("timebg")
    self.m_djsLabel = self:findChild("timeValue")

    self.m_lockIocn = self:findChild("lockIcon") -- 锁定icon
    if self.m_lockIocn then
        self.m_lockIocn:setVisible(false)
    end

    self.btnFunc = self:findChild("Button_1")

    self.m_sp_new = self:findChild("sp_new")
    if self.m_sp_new then
        self.m_sp_new:setVisible(false)
    end

    self.m_nodeSizePanel = self:findChild("node_sizePanel")

    self.m_spRedPoint = self:findChild("sp_red_point")
    self.m_lbRedPointNum = self:findChild("lb_mission_num")
    -- 锁
    self.m_cardLock = self:findChild("lock")
    -- 解锁提示气泡
    self.m_cardMsg = self:findChild("tipsNode")
    self.m_cardUnLock = self:findChild("unlockValue")
    -- 下载气泡
    self.m_cardMsgLoad = self:findChild("tipsNode_downloading")
    -- 赛季未开启气泡
    self.m_cardMsgUnopen = self:findChild("tipsNode_comingsoon")
    --下载节点
    self.m_nodeCardLoad = self:findChild("downLoadNode")
    -- wild link 提示
    self.m_cardSpecail = self:findChild("card_special")
    self.m_cardWild = self:findChild("card_wild")
    self.m_cardLink = self:findChild("card_link")

    self.m_card_text = self:findChild("name")    
end

function LobbyBottom_CardNode:updateView()
    self:updateUnlockLevel()
    self:updateBtnIcon()
end

-- 解锁等级
function LobbyBottom_CardNode:updateUnlockLevel()
    local unLockLevel = globalData.constantData.CARD_OPEN_LEVEL or 18
    -- 新手期1级就解锁集卡
    if CardSysManager:isNovice() then
        unLockLevel = globalData.constantData.NEW_CARD_OPEN_LEVEL or 5
    end
    if self.m_cardUnLock then
        self.m_cardUnLock:setString(unLockLevel)
    end
end

function LobbyBottom_CardNode:updateBtnIcon()
    local btnPath = "Activity_LobbyIconRes/other/card/season202203"
    if CardSysManager:isNovice() then
        btnPath = "Activity_LobbyIconRes/other/card/season302301"
    end
    self.btnFunc:loadTextureNormal(btnPath .. ".png", UI_TEX_TYPE_LOCAL)
    self.btnFunc:loadTexturePressed(btnPath .. "_an.png", UI_TEX_TYPE_LOCAL)
    self.btnFunc:loadTextureDisabled(btnPath .. "_an.png", UI_TEX_TYPE_LOCAL)
end

-- 判断集卡入口是否显示
function LobbyBottom_CardNode:isUnlockCard()
    return CardSysManager:isCardOpenLv()
end

--集卡系统是否开启忽略等级
function LobbyBottom_CardNode:isOpenCardSys()
    return CardSysManager:hasSeasonOpening()
end

function LobbyBottom_CardNode:updateCardCollectBtn()
    self.m_card_text:setString("CHIPS")
    self.m_cardMsg:setVisible(false)
    self.m_cardMsgLoad:setVisible(false)
    self.m_cardMsgUnopen:setVisible(false)
    if not CC_CAN_ENTER_CARD_COLLECTION and self.m_card_text then
        self.m_card_text:setString("COMING SOON")
    end

    self:updateBtnIcon()

    if not self:isOpenCardSys() then
        self:updateSpecialFlag()
        -- self.m_cardSpecail:setVisible(false)
        self.m_cardLock:setVisible(false)
        self:showTimeNode(false)
        self:updateCardResStatus()
        self:updateDownLoad(true)
    else
        local isUnlock = self:isUnlockCard()
        if isUnlock then
            -- 已解锁
            self.m_cardLock:setVisible(false)

            self:updateSpecialFlag()

            self:updateCardTimer()

            self:updateCardResStatus()
            self:updateDownLoad(true)
        else
            -- 未解锁
            self.m_cardSpecail:setVisible(false)
            self.m_cardLock:setVisible(true)
            self:showTimeNode(false)
            self:updateDownLoad(false)
        end
    end
end

function LobbyBottom_CardNode:showTimeNode(isShow)
    self.m_timeBg:setVisible(isShow)
end

-- 刷新wild link卡 提示
function LobbyBottom_CardNode:updateSpecialFlag()
    self.m_cardSpecail:setVisible(true)
    if CardSysRuntimeMgr:hasWildCardData() or G_GetMgr(G_REF.ObsidianCard):hadWildCardData() then
        self.m_cardWild:setVisible(true)
        self.m_cardLink:setVisible(false)
    elseif (CardSysRuntimeMgr:getNadoGameLeftCount() or 0) > 0 then
        self.m_cardWild:setVisible(false)
        self.m_cardLink:setVisible(true)
    else
        self.m_cardWild:setVisible(false)
        self.m_cardLink:setVisible(false)
    end
end

-- 集卡倒计时逻辑
function LobbyBottom_CardNode:updateCardTimer()
    -- 赛季结束时间戳
    if not CardSysManager.getSeasonExpireAt then
        self:showTimeNode(false)
        return
    end
    local isEnd = self:showTimeText()
    if not isEnd then
        --倒计时
        if self.m_cardTimer ~= nil then
            self:stopAction(self.m_cardTimer)
        end
        self.m_cardTimer =
            util_schedule(
            self,
            function()
                local isEnd = self:showTimeText()
                if isEnd then
                    if self.m_cardTimer ~= nil then
                        self:stopAction(self.m_cardTimer)
                    end
                end
            end,
            1
        )
    end
end

-- 集卡倒计时逻辑
function LobbyBottom_CardNode:showTimeText()
    local expireAt = CardSysManager:getSeasonExpireAt()
    local isEnd, isShow, textStr, isTextPostfix = CardSysManager:updateCardTimeStr(expireAt)
    self:showTimeNode(isShow)
    if isTextPostfix then
        if tonumber(textStr) == 1 then
            textStr = textStr .. " DAY"
        elseif tonumber(textStr) > 1 then
            textStr = textStr .. " DAYS"
        end
    end
    self.m_djsLabel:setString(textStr)

    return isEnd
end

--刷新集卡按钮状态
function LobbyBottom_CardNode:updateCardResStatus()
    --刷新成功检测是否自动进入集卡系统
    if self.m_isAutoClickCard then
        self.m_isAutoClickCard = nil
        self:enterCardSys()
    end
end

function LobbyBottom_CardNode:enterCardSys()
    if CardSysManager.setEnterCardType then
        CardSysManager:setEnterCardType(1)
    end
    CardSysManager:enterCardCollectionSys(
        function()
            self.m_click = false
            if not tolua.isnull(self) then
                self:openLayerSuccess()
            end
        end,
        function()
           self.m_click = false
        end
    )
end

--等级到达 未下载成功时的提示
function LobbyBottom_CardNode:checkCardDownload(func)
    self.m_cardMsgLoad:setVisible(true)
    gLobalViewManager:addAutoCloseTips(
        self.m_cardMsgLoad,
        function()
            self.m_cardMsgLoad:setVisible(false)
            if func then
                func()
            end
        end,
        true
    )
end

-- 赛季未开启的气泡
function LobbyBottom_CardNode:checkCardOpen(func)
    self.m_cardMsgUnopen:setVisible(true)
    gLobalViewManager:addAutoCloseTips(
        self.m_cardMsgUnopen,
        function()
            self.m_cardMsgUnopen:setVisible(false)
            if func then
                func()
            end
        end,
        true
    )
end

--集卡预热活动是否开启了
function LobbyBottom_CardNode:isOpenPreCard()
    return G_GetActivityDataByRef(ACTIVITY_REF.PreCard)
end

--尝试打开预热界面
function LobbyBottom_CardNode:checkOpenPreView()
    gLobalSendDataManager:getLogIap():setEnterOpen("tapOpen", "lobbyPreCardIcon")
    local uiView = util_createFindView("Activity_LobbyIconRes/Activity_PreCard")
    if uiView then
        gLobalViewManager:showUI(uiView, ViewZorder.ZORDER_UI)
    end
end

function LobbyBottom_CardNode:clickLobbyNode()
    local isUnlock = self:isUnlockCard()
    if not isUnlock or not CC_CAN_ENTER_CARD_COLLECTION then
        if not isUnlock then
            gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
            self:touchLockCard()
        end
        return
    end
    if CardSysManager:isDownLoadCardRes() then
        if self.m_click then
            return
        end
        self.m_click = true
        self:enterCardSys()
    else
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        --下载中气泡
        self:showTips(self.m_cardMsgLoad)
    end
end

function LobbyBottom_CardNode:touchLockCard()
    --如果存在预热请求预热
    if self:isOpenPreCard() then
        self:checkOpenPreView()
        return
    end
    --没有开启屏蔽
    if not CC_CAN_ENTER_CARD_COLLECTION then
        return
    end
    --赛季没有数据请求一下进入集卡系统
    if not CardSysManager.hasLoginCardSys or not CardSysManager:hasLoginCardSys() then
        self.m_isAutoClickCard = true
        CardSysManager:requestCardCollectionSysInfo()
        return
    end
    self:showTips(self.m_cardMsg)
end

function LobbyBottom_CardNode:getGameData()
    -- 这是不需要活动数据的关卡 直接返回nil
    return nil
end

-- 下载 相关回调 ---
function LobbyBottom_CardNode:getProgressPath()
    -- local season = globalData.cardAlbumId
    -- local round = (globalData.cardRound or 0) + 1
    -- return string.format("Activity_LobbyIconRes/other/card/season%s_round_%s.png", tostring(season), tostring(round))
    if CardSysManager:isNovice() then
        return "Activity_LobbyIconRes/other/card/season302301.png"
    end
    return "Activity_LobbyIconRes/other/card/season202203.png"
end

function LobbyBottom_CardNode:getDownLoadingNode()
    return self.m_nodeCardLoad
end

function LobbyBottom_CardNode:getCsbName()
    return "Activity_LobbyIconRes/LobbyBottomCardNode.csb"
end

function LobbyBottom_CardNode:getDownLoadKey()
    return CardSysManager:getDyNotifyName()
end

function LobbyBottom_CardNode:endProcessFunc()
    self:updateCardResStatus()
end

-- onEnter
function LobbyBottom_CardNode:onEnter()
    BaseLobbyNodeUI.onEnter(self)

    -- 更新集卡入口信息
    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            self:updateCardCollectBtn()
            self:updateView()
        end,
        ViewEventType.NOTIFY_UPDATE_LOBBY_CARD_INFO
    )

    -- 检测相关
    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            self:checkCardDownload(params)
        end,
        ViewEventType.NOTIFY_LOBBY_BOTTOM_CARD_CHECKDOWNLOAD
    )

    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            self:checkCardOpen(params)
        end,
        ViewEventType.NOTIFY_LOBBY_BOTTOM_CARD_OPEN
    )

    -- gLobalNoticManager:addObserver(
    --     self,
    --     function(self, params)
    --         release_print("----- CARD_NEW_SEASON_OPEN -----")
    --         self:updateCardCollectBtn()
    --         self:updateView()
    --     end,
    --     CardSysConfigs.ViewEventType.CARD_NEW_SEASON_OPEN
    -- )

    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            release_print("----- CARD_ONLINE_ALBUM_OVER -----")
            self:updateCardCollectBtn()
            self:updateView()
        end,
        ViewEventType.CARD_ONLINE_ALBUM_OVER
    )

    self:updateCardCollectBtn()

    self:updateRedPoint()
    --
    schedule(
        self,
        function()
            self:updateRedPoint()
        end,
        1
    )
end

function LobbyBottom_CardNode:onExit()
    BaseLobbyNodeUI.onExit(self)
end

function LobbyBottom_CardNode:updateRedPoint()
    if not self:isUnlockCard() then
        self.m_spRedPoint:setVisible(false)
        self.m_lbRedPointNum:setVisible(false)
        return
    end

    local nCount = 0
    -- -- 小游戏数量
    -- local _curAlbumID = CardSysRuntimeMgr:getCurAlbumID()
    -- local _logic = CardSysRuntimeMgr:getSeasonLogic(_curAlbumID)
    -- if _logic and _logic.getPuzzlePageLuaName and _logic:getPuzzleGameLuaName() ~= nil then
    --     local data = CardSysRuntimeMgr:getPuzzleGameData()
    --     local pickLeft = data and data.pickLeft or 0
    --     if pickLeft > 0 then
    --         nCount = nCount + pickLeft
    --     end
    -- end

    -- -- letto次数
    -- local yearData = CardSysRuntimeMgr:getCurrentYearData()
    -- if yearData then
    --     local _wheelCfg = yearData:getWheelConfig()
    --     if _wheelCfg then
    --         local finalTime = math.floor(tonumber(_wheelCfg:getCooldown() or 0))
    --         local remainTime = math.max(util_getLeftTime(finalTime), 0)
    --         if remainTime == 0 then
    --             local lettosData = _wheelCfg:getLettos()
    --             local showRedPoint = false
    --             if lettosData then
    --                 local starNum = _wheelCfg:getStarNum()
    --                 local minNeedStarNum = lettosData[1].needStars
    --                 local maxNeedStarNum = lettosData[3].needStars
    --                 if starNum and starNum >= minNeedStarNum and starNum < maxNeedStarNum then
    --                     if gLobalDataManager:getNumberByField("CardRecover", 0) == 0 then
    --                         showRedPoint = true
    --                     end
    --                 elseif _wheelCfg:getStarNum() >= maxNeedStarNum then
    --                     showRedPoint = true
    --                 end
    --             end
    --             if showRedPoint == true then
    --                 nCount = nCount + 1
    --             end
    --         end
    --     end
    -- end

    -- if CardSysManager:isUnlockStatue() then
    --     if StatuePickGameData and StatuePickStatus then
    --         if StatuePickGameData:isParseData() then
    --             local coolTime = StatuePickGameData:getCooldownTime()
    --             if coolTime == 0 then
    --                 nCount = nCount + 1
    --             else
    --                 local status = StatuePickGameData:getGameStatus()
    --                 if status and status ~= StatuePickStatus.FINISH then
    --                     nCount = nCount + 1
    --                 end
    --             end
    --         end
    --     end
    -- end

    -- 集卡鲨鱼小游戏
    local miniGameData = G_GetMgr(G_REF.CardSeeker):getData()
    if miniGameData and miniGameData:getLeftTime() > 0 and not miniGameData:isFinished() then
        nCount = nCount + 1
    end
    if not CardSysManager:isNovice() then
        -- 集卡商店
        local store_data = G_GetMgr(G_REF.CardStore):getRunningData()
        if store_data then
            if store_data:getCanGiftCollect() == true then
                nCount = nCount + 1
            end
        end
    end

    if nCount > 0 then
        self.m_spRedPoint:setVisible(true)
        self.m_lbRedPointNum:setVisible(true)
        nCount = math.min(999, nCount)
        self.m_lbRedPointNum:setString(tostring(nCount))
        self:updateLabelSize({label = self.m_lbRedPointNum, sx = 1, sy = 1}, 35)
    else
        self.m_spRedPoint:setVisible(false)
        self.m_lbRedPointNum:setVisible(false)
    end
end

return LobbyBottom_CardNode
