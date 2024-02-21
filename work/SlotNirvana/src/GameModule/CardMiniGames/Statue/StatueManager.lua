local statuePickCtr = require("GameModule.CardMiniGames.Statue.StatuePick.StatuePickControl")
if statuePickCtr then
    GD.StatuePickControl = statuePickCtr:getInstance()
end
local StatueRunData = require "GameModule.Card.StatueRunData"
local StatueManager = class("StatueManager", BaseSingleton)

function StatueManager:ctor()
    -- 配置表，每次新赛季开启都要维护
    self.m_openSeasons = {
        ["202102"] = true,
        ["202103"] = true,
        ["202104"] = true,
        ["202201"] = true,
        ["202202"] = true
    }
end

function StatueManager:getInstance()
    if not self._instance then
        self._instance = self.__index:create()
        self._instance:initObserver()
        self._instance:initBaseData()
    end
    return self._instance
end

function StatueManager:initBaseData()
    self.m_statueRunData = StatueRunData:getInstance()
end

function StatueManager:initObserver()
end

function StatueManager:getRunData()
    return self.m_statueRunData
end

function StatueManager:onUpdateTimer(_dt)
    gLobalNoticManager:postNotification(CardSysConfigs.ViewEventType.CARD_STATUE_UPDATE_TIME)
end

function StatueManager:setClanSource(_source)
    self.m_statueClanOpenSource = _source
end

function StatueManager:getClanSource()
    return self.m_statueClanOpenSource
end

function StatueManager:isSeasonOpenMiniGame()
    local albumId = CardSysRuntimeMgr:getCurAlbumID()
    if albumId and self.m_openSeasons[tostring(albumId)] then
        return true
    end
    return false
end

function StatueManager:showStatueClanUI(openSource)
    self:setClanSource(openSource) -- 神像界面的打开来源

    local albumId = CardSysRuntimeMgr:getCurAlbumID()
    if albumId then
        local _logic = CardSysRuntimeMgr:getSeasonLogic(albumId)
        if _logic and _logic.showStatueClanUI then
            _logic:showStatueClanUI(openSource)
        end
    end
end

-- 外部接口
function StatueManager:pubShowStatueClanUI(openSource)
    -- 等级，赛季开启状态
    if not CardSysManager:canEnterCardCollectionSys() then
        return false
    end
    -- 判断资源是否下载
    if not CardSysManager:isDownLoadCardRes() then
        return false
    end
    -- 判断数据是否存在
    if not CardSysManager:hasLoginCardSys() then
        return false
    end
    -- 时间没到
    if not CardSysManager:isUnlockStatue() then
        return false
    end

    -- 处理背景音效
    -- 外部系统直接打开的神像界面。需要播放当前赛季的集卡的背景音效
    CardSysManager:playBgMusic()

    -- 请求小游戏产生的卡牌数据，更新章节数据
    local yearID = CardSysRuntimeMgr:getCurrentYear()
    local albumId = CardSysRuntimeMgr:getCurAlbumID()
    local tExtraInfo = {["year"] = yearID, ["albumId"] = albumId}
    -- 添加loading遮罩，如果不添加，在请求的过程中玩家退出关卡会在其他地方打开界面
    gLobalViewManager:addLoadingAnimaDelay()
    -- TODO：确认为什么是卡册数据，不是赛季数据
    CardSysNetWorkMgr:sendCardsAlbumRequest(
        tExtraInfo,
        function()
            gLobalViewManager:removeLoadingAnima()
            CardSysRuntimeMgr:setSelAlbumID(CardSysRuntimeMgr:getCurAlbumID())
            self:showStatueClanUI(openSource)
        end,
        function()
            gLobalViewManager:removeLoadingAnima()
        end
    )
    return true
end

-- 退出神像章节界面
function StatueManager:exitStatueClanUI()
    -- 处理背景音效
    -- 外部系统直接打开的神像界面，需要关闭集卡的背景音效
    local _clanSource = self:getClanSource()
    if _clanSource and _clanSource ~= "CardAlbumView" then
        CardSysManager:stopBgMusic()
    end

    self:setClanSource(nil)
end

function StatueManager:getPickBoxKey()
    return "StatuePickBoxClick_" .. globalData.userRunData.uid
end

function StatueManager:isEnterPickBox()
    local enterTimes = gLobalDataManager:getNumberByField(self:getPickBoxKey(), 0)
    if enterTimes > 0 then
        return true
    end
    return false
end

function StatueManager:saveEnterPickBox()
    gLobalDataManager:setNumberByField(self:getPickBoxKey(), 1)
end

function StatueManager:getFirstEnterClanKey()
    return "StatuePickFirstEnter_" .. globalData.userRunData.uid
end

function StatueManager:isFirstEnterStatueClan()
    local enterTimes = gLobalDataManager:getNumberByField(self:getFirstEnterClanKey(), 0)
    if enterTimes > 0 then
        return true
    end
    return false
end

function StatueManager:saveFirstEnterStatueClan()
    gLobalDataManager:setNumberByField(self:getFirstEnterClanKey(), 1)
end

function StatueManager:setLevelUping(uping)
    self.m_isLevelUping = uping
end

function StatueManager:getLevelUping()
    return self.m_isLevelUping
end

function StatueManager:checkEntryNode()
    -- 检测等级是否到了
    local curLevel = globalData.userRunData.levelNum
    local limitLevel = globalData.constantData.NOVICE_CARD_LEFT_FRAME_SHOW_LEVEL or 0
    if curLevel < limitLevel then
        return false
    end
    -- 等级，赛季开启状态
    if not CardSysManager:canEnterCardCollectionSys() then
        return false
    end
    -- 判断资源是否下载
    if not CardSysManager:isDownLoadCardRes() then
        return false
    end
    -- 判断数据是否存在
    if not CardSysManager:hasLoginCardSys() then
        return false
    end
    -- 时间没到
    if not CardSysManager:isUnlockStatue() then
        return false
    end
    -- 小游戏资源单独判断一下
    if not util_IsFileExist("CardRes/season202102/Statue/StatueEntryNode.csb") then
        return false
    end
    if not self:isSeasonOpenMiniGame() then
        return false
    end
    -- 直接使用，添加判断条件
    if not StatuePickGameData then
        return false
    end
    -- 如果在线跨天，客户端数据没有刷新，需要通过倒计时的数据来判断
    if StatuePickGameData:getCooldownTime() > 0 then
        return false
    end
    -- 小游戏的状态判断当前游戏是否可玩
    local status = StatuePickGameData:getGameStatus()
    if status and status == StatuePickStatus.FINISH then
        return false
    end
    return true
end

function StatueManager:getStatueEntryNode()
    local albumId = CardSysRuntimeMgr:getCurAlbumID()
    if albumId then
        local _logic = CardSysRuntimeMgr:getSeasonLogic(albumId)
        if _logic and _logic.getStatueEntryNode then
            return _logic:getStatueEntryNode()
        end
    end
    return nil
end

return StatueManager
