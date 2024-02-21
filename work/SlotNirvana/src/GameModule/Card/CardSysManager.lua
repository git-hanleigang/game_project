--[[
    集卡系统 接口统一管理模块
    其他系统模块调用集卡系统需要通过此模块
    集卡系统内部调用其他模块也尽量通过此管理
--]]
-- FIX IOSx 161
local ResCacheMgr = require("GameInit.ResCacheMgr.ResCacheMgr")
local CardSysManager = class("CardSysManager")

-- 初始化全局 --
require "GameModule.Card.CardSysConfigs"
require "GameModule.Card.CardSysNetWork"
require "GameModule.Card.CardSysRuntimeData"
require "GameModule.Card.baseViews.ResConfig"

-- 初始化局部 --
local CardSysLinkManager = require "GameModule.Card.CardSysLinkManager"
local CardSysRecoverManager = require "GameModule.Card.CardSysRecoverManager"
local CardSysWildExchangeManager = require "GameModule.Card.CardSysWildExchangeManager"
local CardSysDropManager = require "GameModule.Card.CardSysDropManager"
local CardSysPuzzleGameManager = require "GameModule.Card.CardSysPuzzleGameManager"
local StatueManager = require("GameModule.CardMiniGames.Statue.StatueManager")

-- local CardInterimManager = require "GameModule.Card.CardInterimManager"

-- 即将到来的赛季，赛季结束时用的字段
function CardSysManager:getComingAlbumId()
    return "202401"
end

function CardSysManager:getCardIconDLKey(_cardId)
    local year = string.sub(_cardId, 1, 2)
    local season = string.sub(_cardId, 3, 4)
    local group = string.sub(_cardId, 5, 6)
    return string.format("y20%d_s%02d_group%02d", tonumber(year), tonumber(season), tonumber(group))
end

-- ctor
function CardSysManager:ctor()
    self:reset()
end

-- do something reset --
function CardSysManager:reset()
    self.m_LinkMgr = nil
    -- self.m_RecoverMgr = nil
    self.m_WildExcMgr = nil
    self.m_DropMgr = nil
    -- self.m_PuzzleMgr = nil
    self.m_PuzzleGameMgr = nil
    self.m_StatueMgr = nil
    -- self.m_InterimMgr = nil
end

-- get Instance --
function CardSysManager:getInstance()
    if not self._instance then
        self._instance = CardSysManager.new()
        self._instance:initObserver()
        self._instance:initBaseData()
    end
    return self._instance
end

-- init --
function CardSysManager:initObserver()
end

function CardSysManager:initBaseData()
    self.m_LinkMgr = CardSysLinkManager.new()
    -- self.m_RecoverMgr = CardSysRecoverManager.new()
    self.m_WildExcMgr = CardSysWildExchangeManager.new()
    self.m_DropMgr = CardSysDropManager.new()
    -- self.m_InterimMgr = CardInterimManager.new()
    self.m_PuzzleGameMgr = CardSysPuzzleGameManager.new()
    self.m_StatueMgr = StatueManager:getInstance()

    CardSysNetWorkMgr:initBaseData()
    CardSysRuntimeMgr:initBaseData()

    -- 开始倒计时 --
    self:initCountTime()
end

-- get managers --
function CardSysManager:getLinkMgr()
    return self.m_LinkMgr
end
-- function CardSysManager:getRecoverMgr()
--     return self.m_RecoverMgr
-- end
function CardSysManager:getWildExcMgr()
    return self.m_WildExcMgr
end
function CardSysManager:getDropMgr()
    return self.m_DropMgr
end
-- function CardSysManager:getPuzzleMgr()
--     return self.m_PuzzleMgr
-- end
function CardSysManager:getPuzzleGameMgr()
    return self.m_PuzzleGameMgr
end
function CardSysManager:getStatueMgr()
    return self.m_StatueMgr
end
-- function CardSysManager:getInterimMgr()
--     return self.m_InterimMgr
-- end

--集卡系统资源是否已下载
function CardSysManager:isDownLoadCardRes()
    -- 添加预下载key判断
    if self:isNovice() == false then
        if not globalDynamicDLControl:checkDownloaded("CardsBase201902") then
            return false
        end
        if not globalDynamicDLControl:checkDownloaded("CardsMusic") then
            return false
        end
    end

    local _key = self:getDyNotifyName()
    if not globalDynamicDLControl:checkDownloaded(_key) then
        return false
    end

    return true
end

--下载通知名称
function CardSysManager:getDyNotifyName()
    -- 下载的时候还没有数据，只能写死
    local curSeasonId = "202401"
    if globalData.cardAlbumId ~= nil then
        curSeasonId = globalData.cardAlbumId
    end
    local serverSeasonId = CardSysRuntimeMgr:getCurAlbumID()
    if serverSeasonId and #serverSeasonId == #curSeasonId then
        curSeasonId = serverSeasonId
    end
    return CardResConfig.CardResDynamicKey[tostring(curSeasonId)] or ""
end

--手动下载通知名称
function CardSysManager:getManualDLNotifyNames()
    local _result = {}
    local curSeasonId = CardSysRuntimeMgr:getCurAlbumID()
    for key, value in pairs(CardResConfig.CardResDynamicKey) do
        if key ~= tostring(curSeasonId) then
            table.insert(_result, value)
        end
    end
    -- 黑耀卡
    -- 下载的时候还没有数据，只能写死 每个赛季改这个值
    local curObsidianSeasonId = 5
    for key, value in pairs(ObsidianCardCfg.CardObsidianDynamicKey) do
        if key ~= curObsidianSeasonId then
            table.insert(_result, value)
        end
    end
    return _result
end

--下载当前赛季
function CardSysManager:checkDownLoadSeason()
    release_print("=== startDownload:cardCardSysManager:checkDownLoadSeason")
    -- 新手期集卡icon、logo
    globalCardsDLControl:startDownload("3023", "01")
    -- 普通赛季集卡icon、logo
    globalCardsDLControl:startDownload("2024", "01")
    globalCardsDLControl:startDownload("2023", "04")
    globalCardsDLControl:startDownload("2023", "03")
    globalCardsDLControl:startDownload("2023", "02")
    globalCardsDLControl:startDownload("2023", "01")
    -- globalCardsDLControl:startDownload("2022", "04")
    -- globalCardsDLControl:startDownload("2022", "03")
    -- globalCardsDLControl:startDownload("2022", "02")
    -- globalCardsDLControl:startDownload("2022", "01")
    -- globalCardsDLControl:startDownload("2021", "04")
    -- globalCardsDLControl:startDownload("2021", "03")
    -- globalCardsDLControl:startDownload("2021", "02")
    -- globalCardsDLControl:startDownload("2021", "01")
    -- globalCardsDLControl:startDownload("2019", "04")
    -- globalCardsDLControl:startDownload("2019", "03")
    -- globalCardsDLControl:startDownload("2019", "02")
    -- globalCardsDLControl:startDownload("2019", "01")
end

--商店是否根据购买金额赠送卡片
function CardSysManager:canShopGiftCard()
    if self:canEnterCardCollectionSys() then
        return true
    end
    return false
end

----------------------------- 流程函数 -------------------------
-- 集卡引导 start ------------------------------------
-- 是否是引导状态
function CardSysManager:isInGuide()
    return CardSysRuntimeMgr:isInGuide()
end
function CardSysManager:setInGuide(isGuide)
    CardSysRuntimeMgr:setInGuide(isGuide)
end
-- 集卡引导 end --------------------------------------

-- 是否从大厅自动进入集卡系统
function CardSysManager:getAutoEnterCard()
    return CardSysRuntimeMgr:getAutoEnterCard()
end
function CardSysManager:setAutoEnterCard(autoEnter)
    CardSysRuntimeMgr:setAutoEnterCard(autoEnter)
end

-- 自动进入集卡时自动进入卡册界面
function CardSysManager:getEnterClanId()
    return CardSysRuntimeMgr:getEnterClanId()
end
function CardSysManager:setEnterClanId(clanId)
    CardSysRuntimeMgr:setEnterClanId(clanId)
end

-- 自动进入集卡时只进入赛季首页
function CardSysManager:getEnterCardFroceSeason()
    return CardSysRuntimeMgr:getEnterCardFroceSeason()
end
function CardSysManager:setEnterCardFroceSeason(clanId)
    CardSysRuntimeMgr:setEnterCardFroceSeason(clanId)
end

-- 进入集卡时是如何进入的
function CardSysManager:getEnterCardType()
    return CardSysRuntimeMgr:getEnterCardType()
end
function CardSysManager:setEnterCardType(enterType)
    CardSysRuntimeMgr:setEnterCardType(enterType)
end

-- 进入集卡系统标记
function CardSysManager:enterCard()
    CardSysRuntimeMgr:enterCard()
    -- 背景音效
    -- if not globalData.inCardSmallGame then
    self:playBgMusic()
    -- end
    -- 自动进入的
    if self:getAutoEnterCard() == true then
        self:setAutoEnterCard(false)
    end
    -- 本次进入集卡系统后是否点击linkcardlayer的关闭按钮
    self:setLinkCardClickX(nil)
    -- 发送进入集卡事件
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_CARD_SYS_ENTER)
end

--回复老虎机暂停状态
-- function CardSysManager:notifyResume()
--     if not CardSysRuntimeMgr:isInCard() then
--         if gLobalViewManager:isPauseAndResumeMachine(self) then
--             -- if gLobalActivityManager.isShowActivity and  gLobalActivityManager:isShowActivity() then
--             --     --有开启的活动展示不回复暂停
--             -- else
--             --     gLobalNoticManager:postNotification(ViewEventType.NOTIFY_RESUME_SLOTSMACHINE)
--             -- end
--             gLobalNoticManager:postNotification(ViewEventType.NOTIFY_RESUME_SLOTSMACHINE)
--         end
--     end
-- end

-- 退出卡册
function CardSysManager:exitCardAlbum()
    if CardSysRuntimeMgr:getSelAlbumID() == CardSysRuntimeMgr:getCurAlbumID() then
        self:exitCard()
    else
        -- 回到当前赛季
        CardSysRuntimeMgr:setSelAlbumID(CardSysRuntimeMgr:getCurAlbumID())
    end
end

-- 退出集卡系统标记
function CardSysManager:exitCard()
    -- 背景音效
    if CardSysRuntimeMgr:isInCard() then
        self:stopBgMusic()
    end

    self:closeCardClanView()
    self:closeCardAlbumView()
    self:closeCardSeasonView()

    -- 退出集卡系统到大厅界面
    CardSysRuntimeMgr:exitCard()
    -- 重置数据 --
    -- 每次重新进入集卡都显示默认，在集卡内部依然用进来后选中的index
    CardSysRuntimeMgr:setSelAlbumID(nil)
    CardSysRuntimeMgr:setIgnoreWild(nil)
    -- 本次进入集卡系统后是否点击linkcardlayer的关闭按钮
    self:setLinkCardClickX(nil)

    -- 判断结束引导逻辑
    if self:isInGuide() then
        self:setInGuide(false)
    end

    self:popExitCallList()

    ResCacheMgr:getInstance():removeUnusedResCache()

    -- 发送退出集卡事件
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_CARD_SYS_EXIT)

    -- 新手期集卡宣传图 进入集卡 是否 点击了第一个卡册 打点
    self:checkLogNovicePopup()
end

-- 新手期集卡宣传图 进入集卡 是否 点击了第一个卡册
function CardSysManager:checkLogNovicePopup()
    local bNovice = CardSysManager:isNovice()
    if not bNovice then
        return
    end

    local logNovice = gLobalSendDataManager:getLogNovice()
    if not logNovice then
        return
    end
    local cardPubEnterInfo = logNovice:getNewUserGoCardSysSign()
    if not cardPubEnterInfo or not cardPubEnterInfo.bPubEnter then
        return
    end
    logNovice:sendPopupLayerLog("Play", "CP", cardPubEnterInfo.entrySite, nil, false)
    logNovice:resetNewUserGoCardSysSign()
end


-- 退出集卡后的逻辑 start -----------------------------------
-- 退出集卡后的逻辑 end -------------------------------------

-- 背景音效处理 start ---------------------------------------
function CardSysManager:playBgMusic()
    -- self.m_preMusicName = gLobalSoundManager:getCurrBgMusicName()
    local musicName = string.format(CardResConfig.CARD_SEASON_MUSIC.BackGround, "music" .. CardSysRuntimeMgr:getCurAlbumID())
    -- gLobalSoundManager:playBgMusic(musicName)
    gLobalSoundManager:playSubmodBgm(musicName, self.__cname, ViewZorder.ZORDER_UI)
end

function CardSysManager:stopBgMusic()
    -- if gLobalViewManager:isLobbyView() then
    --     if self:isQuestLobby() then
    --         gLobalSoundManager:playBgMusic("Activity/QuestSounds/Quest_bg.mp3")
    --     else
    --         --上线兼容使用方式
    --         local lobbyBgmPath = "Sounds/bkg_lobby_new.mp3"
    --         if gLobalActivityManager.getLobbyMusicPath then
    --             lobbyBgmPath = gLobalActivityManager:getLobbyMusicPath()
    --         end
    --         gLobalSoundManager:playBgMusic(lobbyBgmPath)
    --     end
    -- else
    --     --关卡中
    --     if self.m_preMusicName then
    --         gLobalSoundManager:playBgMusic(self.m_preMusicName)
    --         self.m_preMusicName = nil
    --     end
    -- end
    gLobalSoundManager:removeSubmodBgm(self.__cname)
end
function CardSysManager:isQuestLobby()
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
-- 背景音效处理 end ---------------------------------------

-- 是否可以进入集卡系统 -- ignoreLevel是否忽略等级、单纯的判断集卡开没开器
function CardSysManager:canEnterCardCollectionSys(ignoreLevel, ignoreSeasonOpen)
    if not CC_CAN_ENTER_CARD_COLLECTION then
        return false
    end

    -- 根据赛季数据判断 --
    local bHasLogin = self:hasLoginCardSys()
    if not bHasLogin then
        return false
    end

    -- 不忽略赛季开启判断
    if not ignoreSeasonOpen then
        -- 根据赛季的开启状态判断--
        local hasSeasonOpening = self:hasSeasonOpening()
        if not hasSeasonOpening then
            return false
        end
    end

    --不忽略等级
    if not ignoreLevel then
        if not self:isCardOpenLv() then
            return false
        end
    end

    return true
end

-- 根据赛季数据判断 --
function CardSysManager:hasLoginCardSys()
    local bHasLogin = CardSysRuntimeMgr:hasLoginCardSys()
    if not bHasLogin then
        return false
    end
    return true
end

function CardSysManager:hasSeasonOpening()
    local hasSeasonOpening = CardSysRuntimeMgr:hasSeasonOpening()
    if not hasSeasonOpening then
        return false
    end
    return true
end

function CardSysManager:checkShowBetChip()
    local hasSeasonOpening = CardSysRuntimeMgr:hasSeasonOpening()
    if not hasSeasonOpening then
        return false
    end

    if not self:isCardOpenLv() then
        return false
    end
    return true
end

function CardSysManager:isCardOpenLv()
    -- 根据等级判断 --
    local curLevel = globalData.userRunData.levelNum
    local openLevel = globalData.constantData.CARD_OPEN_LEVEL
    -- 新手期5级就解锁集卡
    if CardSysManager:isNovice() then
        openLevel = globalData.constantData.NEW_CARD_OPEN_LEVEL or 5
    end
    if curLevel < openLevel then
        return false
    end
    return true
end

function CardSysManager:getSeasonExpireAt()
    return CardSysRuntimeMgr:getSeasonExpireAt()
end

function CardSysManager:updateCardTimeStr(expireAt, DayNum)
    return CardSysRuntimeMgr:updateCardTimeStr(expireAt, DayNum)
end

-- 用户玩link小游戏的次数是否小于5
function CardSysManager:isInPlayLinks()
    local linkNum = globalData.constantData.LINK_SHOWTIME_LIMIT or 5
    if CardSysRuntimeMgr:getSeasonData():getPlayLinks() < linkNum then
        return true
    end
    return false
end

-- 集卡内部进入卡册
-- 用来判断返回章节再进入含link章节时，如果有link游戏次数，是否弹出link界面
-- 在卡册界面左右切换时，如果有link游戏次数，是否弹出link界面
function CardSysManager:isShowLinkCardLayer(isInit, enterFromAlbum)
    local enterType = self:getEnterCardType()
    if isInit then
        if not enterFromAlbum then
            -- 初始进入
            if enterType == CardSysConfigs.CardSysEnterType.Lobby then
                if self:isInPlayLinks() then
                    return true
                else
                    return false
                end
            elseif enterType == CardSysConfigs.CardSysEnterType.Link then
                return true
            end
        else
            -- elseif enterType == CardSysConfigs.CardSysEnterType.Link then
            --     if self:isInPlayLinks() then
            --         if self:getLinkCardClickX() then
            --             return false
            --         else
            --             return true
            --         end
            --     else
            --         return false
            --     end
            -- end
            -- 从album界面进入clan
            -- if enterType == CardSysConfigs.CardSysEnterType.Lobby then
            if self:isInPlayLinks() then
                if self:getLinkCardClickX() then
                    return false
                else
                    return true
                end
            else
                return false
            end
        end
    else
        -- 左右切换逻辑
        if enterType == CardSysConfigs.CardSysEnterType.Lobby then
            -- 如果从大厅进入
            if self:isInPlayLinks() then
                if self:getLinkCardClickX() then
                    return false
                else
                    return true
                end
            else
                return false
            end
        elseif enterType == CardSysConfigs.CardSysEnterType.Link then
            return false
        end
    end
end

-- 本次进入集卡系统后是否点击了link小游戏进入UI的关闭按钮
function CardSysManager:getLinkCardClickX()
    return CardSysRuntimeMgr:getLinkCardClickX()
end
function CardSysManager:setLinkCardClickX(isClickX)
    CardSysRuntimeMgr:setLinkCardClickX(isClickX)
end

-- 登陆后 进入大厅 第一次获取集卡系统数据 或者在购买出 link wild 卡后 ，或者在使用 link wild 卡后 --
function CardSysManager:requestCardCollectionSysInfo(callFun)
    local getCardAlbumSuccess = function(responseData)
        if callFun then
            callFun(responseData)
        end
    end
    local getCardAlbumFaild = function(errorCode, errorData)
        if callFun then
            callFun(errorCode)
        end
    end

    -- 理论上需要向服务器申请卡册数据 --
    CardSysNetWorkMgr:sendCardsInfoRequest(getCardAlbumSuccess, getCardAlbumFaild)
end

function CardSysManager:pushExitCallList(_exitCall)
    if not self.m_exitCallList then
        self.m_exitCallList = {}
    end
    table.insert(self.m_exitCallList, _exitCall)
end

function CardSysManager:popExitCallList()
    if self.m_exitCallList and #self.m_exitCallList > 0 then
        local exitCall = table.remove(self.m_exitCallList, #self.m_exitCallList)
        if exitCall then
            exitCall()
        end
    end
end

-- 大厅点击进入按钮后  进入集卡系统 --
function CardSysManager:enterCardCollectionSys(callback,fileFunc)
    -- 添加消息等待面板 --
    gLobalViewManager:addLoadingAnima()
    local getCardAlbumSuccess = function(responseData)
        -- 切换横竖屏
        -- 如果是竖屏切换到横屏
        if globalData.slotRunData.isPortrait then
            CardSysRuntimeMgr:changePortraitFlag(true)
        end

        -- if self:isNovice() then
        --     -- 新手期集卡进入写死路径
        --     local luaName = "season" .. CardNoviceCfg.ALBUMID
        --     local filePath = "GameModule/Card/" .. luaName .. "/CardSeason"
        --     if util_IsFileExist(filePath .. ".lua") or util_IsFileExist(filePath .. ".luac") then
        --         local _logic = util_require("GameModule.Card." .. luaName .. ".CardSeason"):create()
        --         _logic:enterCardSys(callback,fileFunc)
        --     else
        --         -- 有数据没有代码，说明没有走热更
        --         gLobalViewManager:removeLoadingAnima()
        --         if fileFunc then
        --             fileFunc()
        --         end
        --     end
        -- else
        -- end
        -- 不同的赛季进入的规则不同
        local albumId = CardSysRuntimeMgr:getCurAlbumID()
        local _logic = CardSysRuntimeMgr:getSeasonLogic(albumId)
        if _logic then
            _logic:enterCardSys(callback,fileFunc)
        else
            -- 服务器更了客户端没更，会走这里
            -- 移除消息等待面板 --
            gLobalViewManager:removeLoadingAnima()
            if fileFunc then
                fileFunc()
            end
        end        

    end
    local getCardAlbumFaild = function(errorCode, errorData)
        -- 移除消息等待面板 --
        gLobalViewManager:removeLoadingAnima()
        if fileFunc then
            fileFunc()
        end
    end

    -- 理论上需要向服务器申请卡册数据 --
    CardSysNetWorkMgr:sendCardsInfoRequest(getCardAlbumSuccess, getCardAlbumFaild)
end

-- 展示赛季选择面板 --
function CardSysManager:showCardSeasonView()
    if not tolua.isnull(self.m_cardSeasonView) then
        if not self.m_cardSeasonView:isVisibleEx() then
            self.m_cardSeasonView:setVisible(true)
        end
        return
    end
    local albumId = CardSysRuntimeMgr:getSelAlbumID()
    if albumId == nil then
        albumId = CardSysRuntimeMgr:getCurAlbumID()
    end
    local _logic = CardSysRuntimeMgr:getSeasonLogic(albumId)
    if _logic then
        self.m_cardSeasonView = _logic:showCardSeasonView()
    end

    if gLobalSendDataManager.getLogPopub and self.sourceName then
        gLobalSendDataManager:getLogPopub():addNodeDot(self.m_cardSeasonView, CardSysManager.sourceName, DotUrlType.UrlName, true, DotEntrySite.DownView, DotEntryType.Lobby)
        CardSysManager.sourceName = nil
    end

    gLobalViewManager:showUI(self.m_cardSeasonView, ViewZorder.ZORDER_UI)
    -- self:checkShowFirstEnterTips()
end

function CardSysManager:closeCardSeasonView(exitFunc)
    if not tolua.isnull(self.m_cardSeasonView) then
        self.m_cardSeasonView:closeUI(exitFunc)
        self.m_cardSeasonView = nil
    end
end

function CardSysManager:hideCardSeasonView()
    if not tolua.isnull(self.m_cardSeasonView) then
        self.m_cardSeasonView:setVisible(false)
    end
end

-- 展示隐藏的选中卡册面板
function CardSysManager:redisplayCardAlbumView()
    self.m_cardAlbumViews = self.m_cardAlbumViews or {}
    local albumId = CardSysRuntimeMgr:getSelAlbumID()
    if albumId == nil then
        albumId = CardSysRuntimeMgr:getCurAlbumID()
    end    
    local _view = self.m_cardAlbumViews[tostring(albumId)]
    if not tolua.isnull(_view) then
        if not _view:isVisibleEx() then
            CardSysRuntimeMgr:setClickOtherInAlbum(false)
            _view:setVisible(true)
        end
    end
end

-- 展示卡册面板 --
function CardSysManager:showCardAlbumView(isPlayStart, callback)
    if not self.m_cardAlbumViews then
        self.m_cardAlbumViews = {}
    end
    local albumId = CardSysRuntimeMgr:getSelAlbumID()
    if albumId == nil then
        albumId = CardSysRuntimeMgr:getCurAlbumID()
    end    
    local view = self.m_cardAlbumViews[tostring(albumId)]
    if tolua.isnull(view) then
        local seasonCfg = CardSysConfigs.SEASON_LIST[tostring(albumId)]
        if seasonCfg then
            CardSysRuntimeMgr:setClickOtherInAlbum(false)
            view = util_createView(seasonCfg.albumPath, isPlayStart)
            gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
            self.m_cardAlbumViews[tostring(albumId)] = view
            if callback then
                callback()
            end
        else
            release_print("!!! CardSysConfigs.SEASON_LIST not have config, albumId="..tostring(albumId))
        end
    else
        if not view:isVisibleEx() then
            CardSysRuntimeMgr:setClickOtherInAlbum(false)
            view:setVisible(true)
        end
    end
    -- if not self.m_cardAlbumViews[tostring(albumId)] and CardSysConfigs.SEASON_LIST[tostring(albumId)] then
    --     CardSysRuntimeMgr:setClickOtherInAlbum(false)
    --     self.m_cardAlbumViews[tostring(albumId)] = util_createView(CardSysConfigs.SEASON_LIST[tostring(albumId)].albumPath, isPlayStart)
    --     gLobalViewManager:showUI(self.m_cardAlbumViews[tostring(albumId)], ViewZorder.ZORDER_UI)
    --     if callback then
    --         callback()
    --     end
    -- end
    -- if self.m_cardAlbumViews[tostring(albumId)] and not self.m_cardAlbumViews[tostring(albumId)]:isVisibleEx() then
    --     CardSysRuntimeMgr:setClickOtherInAlbum(false)
    --     self.m_cardAlbumViews[tostring(albumId)]:setVisible(true)
    -- end
end

function CardSysManager:closeCardAlbumView(exitFunc)
    if not self.m_cardAlbumViews then
        return
    end

    local selAlbumId = CardSysRuntimeMgr:getSelAlbumID()
    if selAlbumId == nil then
        selAlbumId = CardSysRuntimeMgr:getCurAlbumID()
    end    
    local view = self.m_cardAlbumViews[tostring(selAlbumId)]
    if view and view.closeUI then
        local callback = function()
            self.m_cardAlbumViews[tostring(selAlbumId)] = nil
            if exitFunc then
                exitFunc()
            end
        end
        view:closeUI(callback)
    end
end
function CardSysManager:hideCardAlbumView()
    if not self.m_cardAlbumViews then
        return
    end
    local albumId = CardSysRuntimeMgr:getSelAlbumID()
    if albumId == nil then
        albumId = CardSysRuntimeMgr:getCurAlbumID()
    end  
    if self.m_cardAlbumViews[tostring(albumId)] then
        self.m_cardAlbumViews[tostring(albumId)]:setVisible(false)
    end
end

-- 展示卡组面板 --
function CardSysManager:showCardClanView(index, enterFromAlbum)
    if self.m_cardClanView then
        return
    end

    local albumId = CardSysRuntimeMgr:getSelAlbumID()
    if albumId == nil then
        albumId = CardSysRuntimeMgr:getCurAlbumID()
    end
    local _logic = CardSysRuntimeMgr:getSeasonLogic(albumId)
    if _logic then
        self.m_cardClanView = _logic:showCardClanView(index, enterFromAlbum)
    end

    if gLobalSendDataManager.getLogPopub and self.sourceName then
        gLobalSendDataManager:getLogPopub():addNodeDot(self.m_cardClanView, self.sourceName, DotUrlType.UrlName, true, DotEntrySite.DownView, DotEntryType.Lobby)
        CardSysManager.sourceName = nil
    end
    gLobalViewManager:showUI(self.m_cardClanView, ViewZorder.ZORDER_UI)
end

function CardSysManager:closeCardClanView(exitFunc)
    if not tolua.isnull(self.m_cardClanView) then
        self.m_cardClanView:closeUI(exitFunc)
        self.m_cardClanView = nil
    end
end

function CardSysManager:getCardClanView()
    return self.m_cardClanView
end

-- 展示大卡面板 --
function CardSysManager:showBigCardView(clanIndex, index, isNewCard)
    self:closeBigCardView()
    local albumId = CardSysRuntimeMgr:getSelAlbumID()
    if not albumId then
        albumId = CardSysRuntimeMgr:getCurAlbumID()
    end
    local _logic = CardSysRuntimeMgr:getSeasonLogic(albumId)
    if _logic then
        self.m_bigCardLayer = _logic:showBigCardView(clanIndex, index, isNewCard)
    end

    if self.m_bigCardLayer then
        gLobalViewManager:showUI(self.m_bigCardLayer, ViewZorder.ZORDER_UI)
    end
end

function CardSysManager:closeBigCardView()
    if not tolua.isnull(self.m_bigCardLayer) then
        self.m_bigCardLayer:closeUI()
        self.m_bigCardLayer = nil
    end
end

-- 展示link卡面板 --
function CardSysManager:showLinkCardView(cardData)
    self:closeLinkCardView(1)
    self.m_linkCardLayer = util_createView("GameModule.Card.views.LinkCardLayer", cardData)
    gLobalViewManager:showUI(self.m_linkCardLayer, ViewZorder.ZORDER_UI)
end

function CardSysManager:closeLinkCardView(closeType, callFunc)
    if not tolua.isnull(self.m_linkCardLayer) then
        self.m_linkCardLayer:closeUI(closeType, callFunc)
        self.m_linkCardLayer = nil
    end
end

-- 展示wild兑换界面
function CardSysManager:showWildExchangeView(wildType, callFunc, enterType, fileFunc)
    -- wild卡可兑换的年度所有卡片数据接口 --
    gLobalViewManager:addLoadingAnima()
    self:getWildExcMgr():sendExchangeRequest(
        wildType,
        function()
            -- 移除消息等待面板 --
            gLobalViewManager:removeLoadingAnima()
            -- 重新判断一下服务器下发的新数据中是否有wild卡，解决一些极限问题
            if self:getWildExcMgr():canExchangeWildCard() and gLobalViewManager:getViewByName("CardWildExcView") == nil then
                self:getWildExcMgr():showWildExcUI(callFunc, enterType, fileFunc)
            else
                if callFunc then
                    callFunc()
                end
            end

        end,
        function()
            -- 移除消息等待面板 --
            gLobalViewManager:removeLoadingAnima()
            if fileFunc then
                fileFunc()
            end
        end
    )
end

-- wild兑换界面关闭时选择了卡牌，需要弹出掉落的情况
-- 要在这次掉落之后重新判断一下有没有本次wild卡的掉落（比如商店中买了一个wild卡，luckyspin又买了一次，需要弹两次）
-- 还有一种情况是点击游戏大厅中的集卡入口弹出wild兑换界面
function CardSysManager:doWildExchange()
    local cardInfo = self:getWildExcMgr():getRunData():getCardExchangeInfo()
    if not cardInfo then
        return
    end
    -- --赛季奖励
    -- if cardInfo.albumReward and cardInfo.albumReward.coins then
    --     CardSysRuntimeMgr:addCoinToUserRunData("albumReward", cardInfo.albumReward.coins)
    -- end
    -- --章节奖励
    -- if cardInfo.clanReward and #cardInfo.clanReward > 0 then
    --     for i = 1, #cardInfo.clanReward do
    --         if cardInfo.clanReward[i].coins then
    --             CardSysRuntimeMgr:addCoinToUserRunData("clanReward", cardInfo.clanReward[i].coins)
    --         end
    --     end
    -- end
    -- wild兑换的卡牌掉落
    -- 挂起wild掉落队列
    local function nextWildDrop()
        self:getDropMgr():setCurDropHangUp(false)
        self:getDropMgr():doNextDropView()
    end
    self:getDropMgr():setCurDropHangUp(true)
    self:dropCardOnce(cardInfo, nextWildDrop)
end

function CardSysManager:setAlbumCompleteUI(uiView)
    self.m_AlbumComplete = uiView
end

function CardSysManager:setClanCompleteUI(uiView)
    self.m_clanComplete = uiView
end

function CardSysManager:setLinkProgressUI(uiView)
    self.m_linkProgressComplete = uiView
end

function CardSysManager:setLinkOverCompleteUI(uiView)
    self.m_linkOverComplete = uiView
end

function CardSysManager:closeCardCollectComplete()
    if not tolua.isnull(self.m_clanComplete) then
        -- 章节奖励界面多个弹出处理
        -- 关闭章节奖励界面
        self.m_clanComplete:closeUI()
        self.m_clanComplete = nil
    elseif not tolua.isnull(self.m_linkProgressComplete) then
        -- 这个界面不处理掉落下一步
        -- 放在了 self.m_linkProgressComplete:setOverFunc
        self.m_linkProgressComplete:closeUI()
        self.m_linkProgressComplete = nil
    else
        if not tolua.isnull(self.m_AlbumComplete) then
            self.m_AlbumComplete:closeUI()
            self.m_AlbumComplete = nil
        end

        if not tolua.isnull(self.m_linkOverComplete) then
            self.m_linkOverComplete:closeUI()
            self.m_linkOverComplete = nil
        end

        -- 关闭完收集面板 继续掉落面板的下一步弹版 --
        self:getDropMgr():doNextDropView()
    end
end

function CardSysManager:showLinkCard(index)
    self:closeLinkCardView(1)
    local cardData = CardSysRuntimeMgr:getLinkGameCardData(index)
    if cardData then
        self:showLinkCardView(cardData)
    end
end

-- 展示历史界面 --
function CardSysManager:showCardHistoryView(success)
    if gLobalViewManager:getViewByName("CardHistoryView") ~= nil then
        return
    end
    gLobalViewManager:addLoadingAnima()
    local function outPutNetInfo()
        gLobalViewManager:removeLoadingAnima()
        local curLogic = CardSysRuntimeMgr:getCurSeasonLogic()
        if curLogic then
            local view = curLogic:createCardHistoryMain(success)
            view:setName("CardHistoryView")
            gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
        end
    end
    CardSysNetWorkMgr:sendCardDropHistoryRequest(outPutNetInfo)
end

-- 回收机规则介绍界面 --
function CardSysManager:showCardRecoverRule()
    local curLogic = CardSysRuntimeMgr:getCurSeasonLogic()
    if curLogic then
        self.m_cardRecoverRule = curLogic:createCardRevoverRule()
        gLobalViewManager:showUI(self.m_cardRecoverRule, ViewZorder.ZORDER_UI)
    end
end

function CardSysManager:closeCardRecoverRule()
    if not tolua.isnull(self.m_cardRecoverRule) then
        self.m_cardRecoverRule:closeUI()
        self.m_cardRecoverRule = nil
    end
end

-- 以往赛季入口界面 --
function CardSysManager:showCardCollectionUI()
    if gLobalViewManager:getViewByName("CardCollectionUI") ~= nil then
        return
    end
    local albumId = CardSysRuntimeMgr:getCurAlbumID()
    local _logic = CardSysRuntimeMgr:getSeasonLogic(albumId)
    if _logic then
        local view = _logic:showCardCollectionUI()
        gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
    end
end

-- 打开回收机打开时的原界面 --
function CardSysManager:showRecoverSourceUI()
    local source = CardSysRuntimeMgr:getRecoverSourceUI()
    if source then
        if source == CardSysRuntimeMgr.RecoverSourceUI.SeasonUI then
            -- 201903赛季屏蔽了
            -- self:showCardSeasonView()
        elseif source == CardSysRuntimeMgr.RecoverSourceUI.AlbumUI then
            self:showCardAlbumView()
        end
    end
end
-- 关闭回收机打开时的原界面 --
function CardSysManager:hideRecoverSourceUI()
    local source = CardSysRuntimeMgr:getRecoverSourceUI()
    if source then
        if source == CardSysRuntimeMgr.RecoverSourceUI.SeasonUI then
            self:hideCardSeasonView()
        elseif source == CardSysRuntimeMgr.RecoverSourceUI.AlbumUI then
            self:hideCardAlbumView()
        end
    end
end
-- 关闭回收机打开时的原界面 --
function CardSysManager:closeRecoverSourceUI()
    local source = CardSysRuntimeMgr:getRecoverSourceUI()
    if source then
        if source == CardSysRuntimeMgr.RecoverSourceUI.SeasonUI then
            self:closeCardSeasonView()
        elseif source == CardSysRuntimeMgr.RecoverSourceUI.AlbumUI then
            self:closeCardAlbumView()
        end
    end
end

-- 第一次进入特殊提示 --
-------------------------------------------- 卡片掉落相关 start ------------------------------------
-- 卡片单次掉落数据  及时处理 --
function CardSysManager:dropCardOnce(tCardInfo, callBack)
    self.m_DropMgr:parseDropDatas({tCardInfo})
    self.m_DropMgr:dropCards(tCardInfo.source, callBack)
    -- self.m_DropMgr:setCallFunAfterDrop( callBack )
end

-- 卡片多次掉落数据 可以不需要及时处理 需要手动调取 --
function CardSysManager:doDropCardsData(tTableList, bStartDrop)
    -- for i = 1, #tTableList do
    --     self.m_DropMgr:parseDropData(tTableList[i])
    -- end
    self.m_DropMgr:parseDropDatas(tTableList)

    -- 如果指定掉落 --
    if bStartDrop then
        self.m_DropMgr:dropCards()
    end
end
-- 手动调取掉落操作 --
function CardSysManager:doDropCards(dropSource, dropOverCallFunc)
    if not CC_CAN_ENTER_CARD_COLLECTION then
        return
    end
    self:getDropMgr():dropCards(dropSource, dropOverCallFunc)
    -- self:getDropMgr():setCallFunAfterDrop( dropOverCallFunc)
end

-- 是否有掉落数据需要弹出框 --
function CardSysManager:needDropCards(dropSource)
    if not CC_CAN_ENTER_CARD_COLLECTION then
        return false
    end
    return self:getDropMgr():hasDropData(dropSource)
end

-- 清理掉卡信息
function CardSysManager:clearDropCards(dropSource)
    if not CC_CAN_ENTER_CARD_COLLECTION then
        return false
    end
    return self:getDropMgr():clearDropCards(dropSource)
end
--大型活动掉卡不显示link跳转
function CardSysManager:checkShowCheckIt(dropSource)
    if dropSource then
        --来源是大型活动
        if
            string.find(dropSource, "Bingo") ~= nil or string.find(dropSource, "Find") ~= nil or string.find(dropSource, "Quest") ~= nil or string.find(dropSource, "Coin Pusher Play") ~= nil or
                string.find(dropSource, "Level Rush") ~= nil or
                string.find(dropSource, "GLORY PASS") ~= nil or
                string.find(dropSource, "Pass") ~= nil or
                string.find(dropSource, "Pinball Go") ~= nil
         then
            return false
        end
    end
    return true
end
--新手quest活动掉卡不显示link跳转
function CardSysManager:checkIsInNewQuest()
    local questConfig = G_GetMgr(ACTIVITY_REF.Quest):getRunningData()
    if questConfig and questConfig.m_IsQuestLogin and questConfig:isNewUserQuest() then
        return false
    end
    if G_GetMgr(ACTIVITY_REF.QuestNew):isEnterGameFromQuest() then
        return false
    end
    return true
end
--每日任务活动中掉卡不显示link跳转
function CardSysManager:checkIsInPassMission()
    if gLobalViewManager:getViewLayer():getChildByName("DailyMissionPassMainLayer") then
        return false
    end
    return true
end

--不显示集卡小猪的来源
function CardSysManager:checkIsCanShowChipPiggy(dropSource)
    if dropSource then
        if string.find(dropSource, "Pig Chip") then
            return false
        end
    end
    return true
end
-------------------------------------------- 卡片掉落相关 end ------------------------------------

-- 集卡掉落引导 start ------------------------------
-- overFunc: 关闭引导界面回调
function CardSysManager:showDropCardGuide(overFunc1, overFunc2)
    self.m_cardDropGuideUI = util_createView("GameModule.Card.commonViews.CardDrop.CardDropGuide", overFunc1, overFunc2)
    gLobalViewManager:showUI(self.m_cardDropGuideUI, ViewZorder.ZORDER_UI)
end
function CardSysManager:closeDropCardGuide(closeType)
    if not tolua.isnull(self.m_cardDropGuideUI) then
        self.m_cardDropGuideUI:closeUI(closeType)
        self.m_cardDropGuideUI = nil
    end
end
-- 集卡掉落引导 end --------------------------------

-- 退出集卡系统 释放资源 --
function CardSysManager:releaseCachedRes()
    -- 主要是 FNT字体和纹理缓存 --
    cc.Director:getInstance():purgeCachedData()
end

function CardSysManager:createFullScreenTouchLayer(name, swallow)
    local touch = ccui.Layout:create()
    touch:setName(name)
    touch:setTag(10)
    touch:setTouchEnabled(true)
    touch:setSwallowTouches(swallow)
    touch:setAnchorPoint(cc.p(0.5000, 0.5000))
    touch:setContentSize(cc.size(display.width, display.height))
    touch:setPosition(cc.p(0, 0))
    touch:setClippingEnabled(false)
    touch:setBackGroundColorType(ccui.LayoutBackGroundColorType.solid)
    touch:setBackGroundColor(cc.c4b(255, 255, 255))
    touch:setBackGroundColorOpacity(0)
    return touch
end

-- 倒计时 --
function CardSysManager:initCountTime()
    self:stopCountTime()
    self.m_loaclLastTime = socket.gettime()
    self.m_cardTimer =
        scheduler.scheduleGlobal(
        function()
            --获取真实倒计时
            local delayTime = 1
            if self.m_loaclLastTime then
                local spanTime = socket.gettime() - self.m_loaclLastTime
                self.m_loaclLastTime = socket.gettime()
                if spanTime > 0 then
                    delayTime = spanTime
                end
            end

            -- self.m_InterimMgr:onUpdateTimer(delayTime)

            self.m_WildExcMgr:onUpdateTimer(delayTime)
            -- self.m_RecoverMgr:onUpdateTimer(delayTime)
            self.m_StatueMgr:onUpdateTimer(delayTime)

            gLobalNoticManager:postNotification(CardSysConfigs.ViewEventType.CARD_COUNTDOWN_UPDATE)
        end,
        1
    )
end
function CardSysManager:stopCountTime()
    if self.m_cardTimer then
        scheduler.unscheduleGlobal(self.m_cardTimer)
        self.m_cardTimer = nil
    end
end

function CardSysManager:cardRecoverWheelReady()
    if self.m_cardSeasonView ~= nil then
        self.m_cardSeasonView:initWheelTip()
    end
end

-- -- 显示小游戏界面 --传入albumId
-- function CardSysManager:showSpecialGameView(albumId, callback)
--     local gameView = util_createView("GameModule.Card.views.CardSmallGameStartView", albumId, callback)
--     if gLobalSendDataManager.getLogPopub and self.sourceName then
--         gLobalSendDataManager:getLogPopub():addNodeDot(gameView, CardSysManager.sourceName, DotUrlType.UrlName, true, DotEntrySite.DownView, DotEntryType.Lobby)
--         CardSysManager.sourceName = nil
--     end
--     gLobalViewManager:showUI(gameView, ViewZorder.ZORDER_UI)
-- end

-- 获取关卡内入口图标
function CardSysManager:getSpecialEntryNode()
    return nil
end

function CardSysManager:getCardGameLeftTime(time)
    local curTime = os.time()
    if globalData.userRunData ~= nil and globalData.userRunData.p_serverTime ~= nil then
        curTime = globalData.userRunData.p_serverTime / 1000
    end
    local leftTime = time / 1000 - curTime
    return leftTime
end

-- 是否可以玩小游戏
-- 新赛季先屏蔽
function CardSysManager:isCanSpecialGame(seasonId)
    return false
end

--返回大厅是否自动进入小游戏
function CardSysManager:setAutoSpecialGame(flag)
    self.m_isAutoSpecialGame = flag
end
--是否自动进入了小游戏
function CardSysManager:checkAutoEnterSpecialGame()
    return false
end

--rewardCoins奖励金币,startPos开始坐标,flyFunc结束回调,onlyCoins不显示遮罩和旋涡只有飞金币
function CardSysManager:cardflyCoins(rewardCoins, startPos, flyFunc, onlyCoins, _isIgnoreSyncServerCoins)
    local endPos = globalData.flyCoinsEndPos
    local baseCoins = globalData.topUICoinCount
    if _isIgnoreSyncServerCoins then
        local view = gLobalViewManager:getFlyCoinsView()
        view:pubShowSelfCoins(true)
    end
    if onlyCoins then
        --不显示遮罩和旋涡只有飞金币
        gLobalViewManager:pubPlayFlyCoin(
            startPos,
            endPos,
            baseCoins,
            rewardCoins,
            function()
                if _isIgnoreSyncServerCoins then
                    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TOP_UPDATE_COIN, {coins = baseCoins + rewardCoins, isPlayEffect = false})
                end
                if flyFunc then
                    flyFunc()
                end
            end,
            false,
            nil,
            nil,
            nil,
            nil,
            true
        )
    else
        --正常飞金币
        gLobalViewManager:pubPlayFlyCoin(
            startPos,
            endPos,
            baseCoins,
            rewardCoins,
            function()
                if _isIgnoreSyncServerCoins then
                    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TOP_UPDATE_COIN, {coins = baseCoins + rewardCoins, isPlayEffect = false})
                end
                if flyFunc then
                    flyFunc()
                end
            end
        )
    end
end

-- 外部调用展示nado机
function CardSysManager:setNadoMachineOverCall(callBack)
    self:getLinkMgr():setNadoMachineOverCall(callBack)
end

function CardSysManager:showNadoMachine(source)
    -- 挂起当前的掉卡队列
    self:getDropMgr():setCurDropHangUp(true)
    self:getLinkMgr():showAceView("drop")
end

function CardSysManager:closeNadoMachine(overFunc)
    -- 挂起当前的掉卡队列
    self:getDropMgr():setCurDropHangUp(false)
    self:getLinkMgr():closeAceView(overFunc)
end

function CardSysManager:enterCardPuzzlePage(forceReq)
    if forceReq then
        self:requestCardCollectionSysInfo(
            function()
                -- 打开集卡小游戏
                self:getPuzzleGameMgr():enterPuzzlePage()
            end
        )
    else
        if not self:hasLoginCardSys() then
            self:requestCardCollectionSysInfo(
                function()
                    -- 打开集卡小游戏
                    self:getPuzzleGameMgr():enterPuzzlePage()
                end
            )
        else
            -- 打开集卡小游戏
            self:getPuzzleGameMgr():enterPuzzlePage()
        end
    end
end
function CardSysManager:enterCardPuzzleGame(forceReq, params)
    if forceReq then
        self:requestCardCollectionSysInfo(
            function()
                -- 打开集卡小游戏
                self:getPuzzleGameMgr():enterPuzzleGame(params)
            end
        )
    else
        if not self:hasLoginCardSys() then
            self:requestCardCollectionSysInfo(
                function()
                    -- 打开集卡小游戏
                    self:getPuzzleGameMgr():enterPuzzleGame(params)
                end
            )
        else
            -- 打开集卡小游戏
            self:getPuzzleGameMgr():enterPuzzleGame(params)
        end
    end
end

-- 获取集卡神像特殊章节提供的buff
function CardSysManager:getBuffDataByType(_buffType)
    local nMuti = 0
    local buffInfo = globalData.buffConfigData:getBuffDataByType(_buffType)
    if buffInfo and buffInfo.buffMultiple and CardSysManager:hasSeasonOpening() then
        nMuti = tonumber(buffInfo.buffMultiple)
    end
    return nMuti
    -- return 270
end

function CardSysManager:isUnlockStatue()
    local unlockTimeStamp = util_getymd_time(globalData.constantData.CARD_STATUE_UNLOCK_TIME)
    local curTimeStamp = util_getCurrnetTime()
    if unlockTimeStamp - curTimeStamp > 0 then
        return false
    end
    return true
end

-- 从公会中要卡
function CardSysManager:requestCardFromClan(_cardData)
    local ClanManager = util_require("manager.System.ClanManager")
    if ClanManager then
        if self.m_requestFromClaning then
            return
        end
        self.m_requestFromClaning = true
        ClanManager:getInstance():requestCardNeeded(
            _cardData.albumId,
            _cardData.cardId,
            function()
                self.m_requestFromClaning = false
            end,
            function()
                self.m_requestFromClaning = false
            end
        )
    end
end

-- 从公会要卡 板子
function CardSysManager:popRequestCardFormClanPanel(_cardData,_friendlist)
    local ClanManager = util_require("manager.System.ClanManager")
    if not ClanManager then
        return
    end

    ClanManager = ClanManager:getInstance()

    -- 还没解锁
    if not ClanManager:isUnlock() then
        local view = gLobalViewManager:showDialog("Dialog/ClanUnlockLevelTips.csb", nil, nil, nil, nil)
        if view then
            local info = ProtoConfig.ErrorTipEnum.CLAN_NO_UNLOCK
            info.content = string.format(info.content, globalData.constantData.CLAN_OPEN_LEVEL)
            view:updateContentTipUI("lb_text", info.content)
        end

        return
    end

    local clanData = ClanManager:getClanData()
    if not clanData then
        return
    end

    if clanData:isClanMember() then
        -- 点击以后会自动关闭
        local view =
            gLobalViewManager:showDialog(
            "Dialog/ClanAskChip.csb",
            function()
                CardSysManager:requestCardFromClan(_cardData)
                if _friendlist and #_friendlist > 0 then
                    G_GetMgr(G_REF.Friend):requestApplyFriendCard(_cardData.cardId)
                end
            end,
            nil,
            nil,
            nil
        )
        if not view then
            CardSysManager:requestCardFromClan(_cardData)
            if _friendlist and #_friendlist > 0 then
                G_GetMgr(G_REF.Friend):requestApplyFriendCard(_cardData.cardId)
            end
        end

        return
    end

    ClanManager:popCommonTipPanel(ProtoConfig.ErrorTipEnum.CLAN_NO_JOIN_TEAM)
end

-- -- cardnewuser todo 登陆时获取的是否在新手期内字段
-- function CardSysManager:setLoginNovice(_isNovice)
--     self.m_isNovice = _isNovice
-- end
-- function CardSysManager:isLoginNovice()
--     return self.m_isNovice
--     -- return true
-- end

-- cardnewuser todo
function CardSysManager:isNovice()
    local curAlbumId = CardSysRuntimeMgr:getCurAlbumID()
    if tonumber(curAlbumId) == tonumber(CardNoviceCfg.ALBUMID) then
        return true
    end
    return false
end

-- 普通集卡 18级解锁宣传弹板
function CardSysManager:checkPopNormalOpenNoticeLayer(_bSync)
    local bCanPop = gLobalDataManager:getBoolByField("PopNormalCardOpenNoticeEnabled", false)
    if not bCanPop then
        if _bSync then
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_RESUME_MACHINE_POPUPVIEW)        
        end
        return false
    end

    local curAlbumId = CardSysRuntimeMgr:getCurAlbumID()
    local resPath = string.format(CardResConfig.seasonRes.CardOpenNoticeLayerRes, curAlbumId)
    if not util_IsFileExist(resPath) then
        if _bSync then
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_RESUME_MACHINE_POPUPVIEW)        
        end
        return false
    end

    local albumData = CardSysRuntimeMgr:getCardAlbumInfo()
    if not albumData then
        if _bSync then
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_RESUME_MACHINE_POPUPVIEW)        
        end
        return false
    end

    local spinePath = string.format(CardResConfig.seasonRes.CardOpenNoticeLayerSpinRes, curAlbumId)
    local luaPath = string.format("GameModule/Card/season%s/CardOpenNoticeLayer", curAlbumId)
    if not util_getRequireFile(luaPath) then
        luaPath = "GameModule.Card.views.NormalCardOpenNoticeLayer"
    end
    local view = util_createView(luaPath, resPath, albumData, spinePath)
    gLobalDataManager:setBoolByField("PopNormalCardOpenNoticeEnabled", false)
    gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
    return view
end

-- 存本地
function CardSysManager:saveCGTime()
    local albumId = CardSysRuntimeMgr:getCurAlbumID()
    local lastTime = math.floor(util_getCurrnetTime())
    gLobalDataManager:setNumberByField("CardSysCG_" .. albumId , lastTime)
end

-- 是否显示CG
function CardSysManager:isShowCG()
    local albumId = CardSysRuntimeMgr:getCurAlbumID()
    local oldSecs = math.floor(tonumber(gLobalDataManager:getNumberByField("CardSysCG_" .. albumId, 0)))

    if oldSecs == 0 then
        return true
    end

    local newSecs = util_getCurrnetTime()
    -- 服务器时间戳转本地时间
    local oldTM = util_UTC2TZ(oldSecs, -8)
    local newTM = util_UTC2TZ(newSecs, -8)
    if oldTM.day ~= newTM.day then
        return true
    end
    return false
end

function CardSysManager:setResponseOffset(_offset)
    self.m_offset = _offset
end

function CardSysManager:getResponseOffset()
    return self.m_offset
end

-- Global Var --
GD.CardSysManager = CardSysManager:getInstance()
