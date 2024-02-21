--[[
    集卡系统运行时数据
    系统数据初始化 网络数据获取级存储 状态数据设定及获取
--]]
-- local SeasonLogic = {
--     ["201901"] = "GameModule.Card.season201901.CardSeason",
--     ["201902"] = "GameModule.Card.season201902.CardSeason",
--     ["201903"] = "GameModule.Card.season201903.CardSeason",
--     ["201904"] = "GameModule.Card.season201904.CardSeason",
--     ["202101"] = "GameModule.Card.season202101.CardSeason",
--     ["202102"] = "GameModule.Card.season202102.CardSeason",
--     ["202103"] = "GameModule.Card.season202103.CardSeason"
-- }

local ParseLogonSimpleData = require("src.GameModule.Card.data.ParseLogonSimpleData")
local ParseSeasonsData = require("GameModule.Card.data.ParseSeasonsData")
local ParseCardAlbumData = require("GameModule.Card.data.ParseCardAlbumData")
local ParseCardDropHistoryData = require("GameModule.Card.data.ParseCardDropHistoryData")
local ParseCardWheelSpinData = require("GameModule.Card.data.ParseCardWheelSpinData")
local ParseCardViewData = require("GameModule.Card.data.ParseCardViewData")
local ParseLinkGameData = require("GameModule.Card.data.ParseLinkGameData")
-- local ParsePuzzleGameData = require("GameModule.Card.data.ParsePuzzleGameData")

local ONE_DAY_TIME = 60 * 60 * 24

local CardSysRuntimeData = class("CardSysRuntimeData")
CardSysRuntimeData.m_showDayDefaultNum = 7 -- 赛季结束前多少天显示倒计时

CardSysRuntimeData.m_bHasLoginCardSys = false -- 是否已经成功登陆集卡系统 --
CardSysRuntimeData.m_bHasPrizeData = nil -- 是否有赛季章节数据
CardSysRuntimeData.m_CardSeasonsInfo = nil -- 赛季基本信息 --
CardSysRuntimeData.m_CardSeasonObj = nil -- 赛季对象
CardSysRuntimeData.m_CardAlbumInfo = nil -- 卡册基本信息 --

CardSysRuntimeData.m_CardDropHistoryInfo = nil -- 卡片历史掉落信息 --
CardSysRuntimeData.m_CardWheelAllCardsInfo = nil -- 回收机可回收年度的所有卡片数据 --
CardSysRuntimeData.m_CardWheelSpinInfo = nil -- 回收机回收卡片spin请求 --
CardSysRuntimeData.m_CardLinkPlayInfo = nil -- Link卡请求link游戏数据 --
CardSysRuntimeData.m_CardExchangeYearCardsInfo = nil -- wild卡可兑换的年度所有卡片数据 --
CardSysRuntimeData.m_CardViewInfo = nil -- 浏览卡片请求数据 --

CardSysRuntimeData.m_recoverSourceUIs = nil -- 回收机界面打开时的界面 --
CardSysRuntimeData.m_autoEnter = nil -- 回到大厅时是否要自动进入集卡系统
CardSysRuntimeData.m_enterClanId = nil -- 进入集卡系统时指定进入的卡册
CardSysRuntimeData.m_enterForceSeason = nil -- 进入集卡系统时只进入集卡首页
CardSysRuntimeData.m_enterType = nil -- 进入集卡系统时是如何方式进入的
CardSysRuntimeData.m_isLinkCardLayerClickX = nil -- 是否手动点击了link小游戏的进入界面关闭按钮，只记录本次进入集卡系统，需要每次进入退出集卡的时候清空

CardSysRuntimeData.m_isInGuide = nil -- 集卡系统是否是引导状态
CardSysRuntimeData.m_isInCard = nil -- 是否在集卡系统内

CardSysRuntimeData.m_currentWildExchangeType = nil -- wild兑换界面选择的wild卡类型

CardSysRuntimeData.m_selAlbumId = nil -- 赛季界面当前选中的赛季id

CardSysRuntimeData.m_isClickOtherInAblum = nil -- 赛季选择界面是否点击了在其他lua文件上的按钮

CardSysRuntimeData.RecoverSourceUI = {
    SeasonUI = 1,
    AlbumUI = 2
}

-- ctor
function CardSysRuntimeData:ctor()
end

-- get Instance --
function CardSysRuntimeData:getInstance()
    if not self._instance then
        self._instance = CardSysRuntimeData.new()
        self:initBaseData()
    end
    return self._instance
end

-- init --
function CardSysRuntimeData:initBaseData()
    self.m_CardSeasonsInfo = nil
    self.m_CardAlbumInfo = {}
    self.m_CardDropHistoryInfo = {}
    self.m_CardSeasonObj = {}
    -- 历史章节
    self.m_CardCollectionSeasonIDs = {}
end

function CardSysRuntimeData:getSeasonData()
    return self.m_CardSeasonsInfo
end

-- 登陆是否忽略wild的判断
function CardSysRuntimeData:setIgnoreWild(_ignoreWild)
    self.m_ignoreWild = _ignoreWild
end
function CardSysRuntimeData:getIgnoreWild()
    return self.m_ignoreWild
end

-- 是否已经成功登陆集卡系统 --
function CardSysRuntimeData:setHasLoginCardSys(bLogined)
    self.m_bHasLoginCardSys = bLogined
end
function CardSysRuntimeData:hasLoginCardSys()
    return self.m_bHasLoginCardSys
end

function CardSysRuntimeData:setNetPrize(isNetPrize)
    self.m_isNetPrizeData = isNetPrize
end
function CardSysRuntimeData:getNetPrize()
    return self.m_isNetPrizeData
end

--[[--
    客户端维护nado机剩余次数
]]
function CardSysRuntimeData:setNadoGameLeftCount(_leftCount)
    self.m_nadoGameLeftCount = _leftCount
end

function CardSysRuntimeData:getNadoGameLeftCount()
    return self.m_nadoGameLeftCount
end

--[[--
    客户端维护nado卡收集进度
]]
function CardSysRuntimeData:setNadoCollectCount(_cur, _albumId, _round)
    if not _albumId then
        _albumId = self:getCurAlbumID()
    end
    if not _round then
        local albumInfo = self:getCardAlbumInfo()
        if albumInfo then
            _round = (albumInfo:getRound() or 0) + 1
        else
            _round = (globalData.cardAlbumRound or 0) + 1
        end
    end
    if not self.m_nadoCollects then
        self.m_nadoCollects = {}
    end
    if not self.m_nadoCollects[tostring(_albumId)] then
        self.m_nadoCollects[tostring(_albumId)] = {}
    end
    self.m_nadoCollects[tostring(_albumId)][tostring(_round)] = _cur
end

function CardSysRuntimeData:getNadoCollectCount(_albumId, _round)
    if not _albumId then
        _albumId = self:getCurAlbumID()
    end
    if not _round then
        local albumInfo = self:getCardAlbumInfo()
        if albumInfo then
            _round = (albumInfo:getRound() or 0) + 1
        else
            _round = 1
        end
    end
    if self.m_nadoCollects then
        local albumNados = self.m_nadoCollects[tostring(_albumId)]
        if albumNados then
            return albumNados[tostring(_round)] or 0
        end
    end
    return 0
end

--[[--
    客户端维护章节进度数据
    todo 轮次处理是否合理有待于考究
]]
function CardSysRuntimeData:setClanCollects(_clanId, _cur, _max, _round)
    if not _clanId then
        return
    end
    if not _round then
        local albumInfo = self:getCardAlbumInfo()
        if albumInfo then
            _round = (albumInfo:getRound() or 0) + 1
        else
            _round = (globalData.cardAlbumRound or 0) + 1
        end
    end
    if not self.m_clanCollects then
        self.m_clanCollects = {}
    end
    local clanCollectData = self:getClanCollectByClanId(_clanId)
    if not clanCollectData then
        local tbCollect = {
            clanId = _clanId,
            round = _round,
            cur = _cur,
            max = _max or 10
        }
        table.insert(self.m_clanCollects, tbCollect)
    else
        clanCollectData.round = _round
        clanCollectData.cur = _cur
        clanCollectData.max = _max or 10
    end
    print("setClanCollects ", _clanId, _cur, _max, _round)
end

-- 2024.01改 过轮次的时候，兑换单张wild卡，在开卡包，导致显示 11/10,12/10 等的问题
function CardSysRuntimeData:clearClanCollectsCur()
    local curAlbumID = self:getCurAlbumID()
    for i = 1, #self.m_clanCollects do
        if string.sub(self.m_clanCollects[i].clanId, 1 , 6) == curAlbumID then
            self.m_clanCollects[i].cur = 0
        end
    end
end

function CardSysRuntimeData:getClanCollects(_isCache)
    if _isCache == true then
        return self.m_cacheClanCollects
    end
    return self.m_clanCollects
end

function CardSysRuntimeData:getClanCollectByClanId(_clanId, _isCache)
    if not _clanId then
        return
    end
    local collectDatas = _isCache == true and self.m_cacheClanCollects or self.m_clanCollects
    if collectDatas and #collectDatas > 0 then
        for i = 1, #collectDatas do
            local data = collectDatas[i]
            if data.clanId == _clanId then
                return data 
            end
        end
    end
    return
end

function CardSysRuntimeData:cacheClanCollects()
    self.m_cacheClanCollects = clone(self.m_clanCollects)
end

function CardSysRuntimeData:parseLoginSimpleData(_netData)
    local simpleInfo = ParseLogonSimpleData:create ()
    simpleInfo:parseData(_netData)

    -- 初始化，只做赋值，无加减逻辑
    if self:getNadoGameLeftCount() == nil then
        local nadoGames = simpleInfo:getNadoGames()
        self:setNadoGameLeftCount(nadoGames)
    end

    -- 初始化
    local current = 0
    local collectNado = simpleInfo:getCollectNado()
    if collectNado then
        current = collectNado:getCurrentCards() or 0
    end
    self:setNadoCollectCount(current)
end

-- 设置当前所处赛季基本信息 --
function CardSysRuntimeData:setCardSeasonsInfo(tInfo)
    -- 解析数据 --
    -- release_print("---- nadomachine buff, CardSysRuntimeData:setCardSeasonsInfo 000----")
    self.m_CardSeasonsInfo = ParseSeasonsData:create()
    self.m_CardSeasonsInfo:parseData(tInfo)
    -- release_print("---- nadomachine buff, CardSysRuntimeData:setCardSeasonsInfo 111----")
    -- self.m_CardSeasonsInfo.vegasTornado.box = self:sortPuzzleGameBox(self.m_CardSeasonsInfo.vegasTornado.box)

    self.m_CardCollectionSeasonIDs = {}
    local _cardYears = self:getYearsData()
    if _cardYears then
        for i = #_cardYears, 1, -1 do
            local _cardAlums = _cardYears[i]:getAlbumDatas()
            if _cardAlums then
                for j = #_cardAlums, 1, -1 do
                    local _info = _cardAlums[j]
                    if _info then
                        local _albumId = _info:getAlbumId()
                        local _status = _info:getStatus()
                        if not self.m_CardSeasonObj["" .. _albumId] then
                            local cardSysInfo = CardSysConfigs.SEASON_LIST["" .. _albumId]
                            if cardSysInfo then
                                local _model = require(cardSysInfo.seasonPath)
                                if _model then
                                    self.m_CardSeasonObj["" .. _albumId] = _model:create()
                                else
                                    printError("请创建" .. _albumId .. "赛季主入口模块！！！")
                                end
                            end
                        end
                        -- 是不是结束的章节 cxc 2022年01月04日10:15:44 历史章节id<当前章节
                        -- if _status == CardSysConfigs.CardSeasonStatus.offline and _albumId ~= self:getCurAlbumID() then
                        if _status == CardSysConfigs.CardSeasonStatus.offline then
                            if tonumber(_albumId) < tonumber(self:getCurAlbumID()) then
                                local _tbId = {seasonId = tonumber(_albumId)}
                                table.insert(self.m_CardCollectionSeasonIDs, _tbId)
                            end
                            if tonumber(_albumId) == tonumber(CardNoviceCfg.ALBUMID) then
                                local _tbId = {seasonId = tonumber(_albumId)}
                                table.insert(self.m_CardCollectionSeasonIDs, _tbId)
                            end
                        end
                    end
                end
            end
        end
    end
    -- 计时器
    self:initAlbumCountData()
end

function CardSysRuntimeData:initAlbumCountData()
    local onlineAlbums = {}
    local _cardYears = self:getYearsData()
    if _cardYears then
        for i = #_cardYears, 1, -1 do
            local _cardAlums = _cardYears[i]:getAlbumDatas()
            if _cardAlums then
                for j = #_cardAlums, 1, -1 do
                    local _info = _cardAlums[j]
                    if _info then
                        local _albumId = _info:getAlbumId()
                        local _status = _info:getStatus()
                        local _leftTime = _info:getLeftTime()
                        -- 正在开启赛季开始倒计时
                        if _status == CardSysConfigs.CardSeasonStatus.online then
                            table.insert(onlineAlbums, _info)
                        elseif _status == CardSysConfigs.CardSeasonStatus.coming then
                            -- 新手期集卡未解锁时是commingsoon状态，只判断时间即可
                            if tonumber(_albumId) == tonumber(CardNoviceCfg.ALBUMID) and _leftTime > 0 then
                                table.insert(onlineAlbums, _info)
                            end
                        end
                    end
                end
            end
        end
    end
    -- 存在一种可能：新手期集卡和常规集卡都是on_line状态
    if onlineAlbums and #onlineAlbums > 0 then
        local albumData = onlineAlbums[1]
        self:startAlbumCountDown(albumData:getAlbumId(), albumData:getExpireAt())
    end
end

function CardSysRuntimeData:stopAlbumCountDown()
    if self.m_albumSche then
        scheduler.unscheduleGlobal(self.m_albumSche)
        self.m_albumSche = nil
    end
end

function CardSysRuntimeData:startAlbumCountDown(_albumId, _expireAt)
    local leftTime = self:getLeftTime(_expireAt)
    if leftTime <= 0 then
        return
    end
    self:stopAlbumCountDown()
    self.m_albumSche = scheduler.scheduleGlobal(
        function()
            local leftTime = self:getLeftTime(_expireAt)
            if leftTime <= 0 then
                self:stopAlbumCountDown()
                self:onlineAlbumOver(_albumId)
            end
        end,
        1
    )
end

function CardSysRuntimeData:getLeftTime(_albumExpireAt)
    local curTime = os.time()
    if globalData.userRunData ~= nil and globalData.userRunData.p_serverTime ~= nil then
        curTime = globalData.userRunData.p_serverTime / 1000
    end
    local leftTime = math.floor(tonumber(_albumExpireAt) / 1000) - curTime
    leftTime = leftTime > 0 and leftTime or 0
    return leftTime
end

function CardSysRuntimeData:onlineAlbumOver(_albumId)
    -- cardnewuser todo 重新遍历数据计时【新手期和普通赛季的数据都有可能在开启】
    -- 正在计时的赛季结束
    CardSysManager:requestCardCollectionSysInfo(function()
        gLobalNoticManager:postNotification(ViewEventType.CARD_ONLINE_ALBUM_OVER, {albumId = _albumId})
    end)    
end

function CardSysRuntimeData:getYearsData()
    return self:getSeasonData():getYearsData()
end

function CardSysRuntimeData:getAlbumSimpleData(_albumId)
    if not _albumId then
        _albumId = self:getSelAlbumID() or self:getCurAlbumID()
    end
    local yearsData = self:getYearsData()
    if yearsData and #yearsData > 0 then
        for i= #yearsData, 1, -1 do
            local cardAlums = yearsData[i]:getAlbumDatas()
            if cardAlums then
                for j = #cardAlums, 1, -1 do
                    local albumSimpleData = cardAlums[j]
                    if albumSimpleData then
                        if tonumber(albumSimpleData:getAlbumId()) == tonumber(_albumId) then
                            return albumSimpleData
                        end
                    end
                end
            end
        end
    end
    return nil
end

-- 获得历史章节ID
function CardSysRuntimeData:getCollectionSeasonIDs()
    return self.m_CardCollectionSeasonIDs
end

-- function CardSysRuntimeData:parsePuzzleGameData(data)
--     local temp = ParsePuzzleGameData:parseData(data)
--     self:setPuzzleGameData(temp)
-- end

-- function CardSysRuntimeData:setPuzzleGameData(data)
--     self.m_CardSeasonsInfo.vegasTornado = data
--     self.m_CardSeasonsInfo.vegasTornado.box = self:sortPuzzleGameBox(self.m_CardSeasonsInfo.vegasTornado.box)
--     self.m_CardSeasonsInfo.vegasTornado.oldBox = self:sortPuzzleGameBox(self.m_CardSeasonsInfo.vegasTornado.oldBox)
-- end

function CardSysRuntimeData:getPuzzleGameData()
    -- return self.m_CardSeasonsInfo.vegasTornado
end

function CardSysRuntimeData:getPuzzleDataByIndex(index)
    local _datas = self:getPuzzleGameData()
    if _datas and _datas.puzzle then
        return _datas.puzzle[index]
    else
        return nil
    end
end

-- 是否可购买开箱子次数
function CardSysRuntimeData:hasPurchasePick()
    local data = self:getPuzzleGameData()
    if data.purchasePicks == data.purchasePicksLimit then
        return false
    else
        return true
    end
end

-- 是否变金箱子
function CardSysRuntimeData:isChangeToGoldenBox()
    local data = self:getPuzzleGameData()
    return data.changeBox
end

function CardSysRuntimeData:sortPuzzleGameBox(boxData)
    if boxData == nil or (boxData and #boxData == 0) then
        return boxData
    end

    local temp = {}
    local positions = {}
    for i = 1, #boxData do
        local box = boxData[i]
        if box.position and box.position > 0 then
            positions[#positions + 1] = box
        else
            temp[#temp + 1] = box
        end
    end

    table.sort(
        positions,
        function(a, b)
            return a.position < b.position
        end
    )

    if #positions == 0 then
        return boxData
    end

    for i = 1, #positions do
        local box = positions[i]
        table.insert(temp, box.position, box)
    end

    return temp
end

-- 设置卡册基本信息 --
function CardSysRuntimeData:setCardAlbumInfo(tInfo)
    -- 【201901 201902 赛季，切赛季界面】
    -- 【201903赛季，切章节选择界面】
    -- 这里重新更改数据结构，以赛季为key整个数据存储
    if not self.m_CardAlbumInfo then
        self.m_CardAlbumInfo = {}
    end

    local paData = ParseCardAlbumData:create()
    paData:parseData(tInfo)
    if paData.albumId and paData.albumId ~= "" then
        self.m_CardAlbumInfo[tostring(paData.albumId)] = paData
    end
end

-- 获得赛季逻辑模块
function CardSysRuntimeData:getSeasonLogic(albumId)
    if not albumId then
        return
    end

    return self.m_CardSeasonObj["" .. albumId]
end

function CardSysRuntimeData:getCurSeasonLogic()
    local albumId = self:getCurAlbumID()
    local _logic = self:getSeasonLogic(albumId)
    return _logic
end

-- 获得当前已有赛季的章节数据
function CardSysRuntimeData:getCardAlbumsInfo()
    return self.m_CardAlbumInfo
end

function CardSysRuntimeData:getCardAlbumInfo(albumId)
    albumId = albumId or self:getSelAlbumID() or self:getCurAlbumID()
    return self.m_CardAlbumInfo and self.m_CardAlbumInfo[tostring(albumId)]
end

function CardSysRuntimeData:getAskCD()
    local albumId = self:getCurAlbumID()
    local albumInfo = self:getCardAlbumInfo(albumId)
    if not albumInfo then
        return 0
    end
    return albumInfo.askChipCD
end

function CardSysRuntimeData:setAskCD(cdTime)
    local albumId = self:getCurAlbumID()
    local albumInfo = self:getCardAlbumInfo(albumId)
    if albumInfo then
        albumInfo.askChipCD = tonumber(cdTime)
    end
end

-- 获取当前赛季ID  --
function CardSysRuntimeData:getCurAlbumID()
    local albumId = nil
    if self.m_CardSeasonsInfo ~= nil then
        albumId = self.m_CardSeasonsInfo:getCurrentAlbumId() -- 201903
    end
    if albumId == nil or albumId == "" then
        albumId = globalData.cardAlbumId
    end
    return albumId
end

-- _round:从0开始，保持跟服务器数据一致
function CardSysRuntimeData:setCurAlbumRound(_round)
    local isNotify = false
    if globalData.cardAlbumRound ~= nil and globalData.cardAlbumRound ~= _round then
        globalData.cardAlbumRound = _round
        isNotify = true
    end

    local info = CardSysRuntimeMgr:getCardAlbumInfo()
    if info and info:getRound() ~= _round then
        info:setRound(_round)
        isNotify = true
    end
    if isNotify then
        gLobalNoticManager:postNotification(CardSysConfigs.ViewEventType.CARD_ALBUM_ROUND_CHANGE, {isMaxRound = false})
    end
end
--- 赛季数据 界面 start -------------------------------------------------------------------------------
-- 获取选中的赛季ID --
function CardSysRuntimeData:getSelAlbumID()
    return self.m_selAlbumId -- 201902
end
function CardSysRuntimeData:setSelAlbumID(albumId)
    self.m_selAlbumId = albumId
end

-- 是否是往期赛季
function CardSysRuntimeData:isPastAlbum(albumId)
    local _curAlbumId = self:getCurAlbumID()
    local info = CardSysRuntimeMgr:getCardAlbumInfo(albumId)
    if info and info.status == CardSysConfigs.CardSeasonStatus.offline and tonumber(albumId) ~= tonumber(_curAlbumId) then
        return true
    end
    return false
end
--- 赛季数据 界面 end ------------------------------------------------------------------------------------

--- 卡册(章节)数据 界面 start -----------------------------------------------------------------------------

function CardSysRuntimeData:isNormalClan(clanType)
    if clanType == CardSysConfigs.CardClanType.normal or clanType == CardSysConfigs.CardClanType.special or clanType == CardSysConfigs.CardClanType.quest then
        return true
    end
    return false
end

-- 判断是否是wild章节
function CardSysRuntimeData:isWildClan(clanType)
    if clanType == CardSysConfigs.CardClanType.puzzle_normal or clanType == CardSysConfigs.CardClanType.puzzle_golden or clanType == CardSysConfigs.CardClanType.puzzle_link then
        return true
    end
    return false
end

function CardSysRuntimeData:isStatueClan(clanType)
    if clanType == CardSysConfigs.CardClanType.statue_left or clanType == CardSysConfigs.CardClanType.statue_right then
        return true
    end
    return false
end

function CardSysRuntimeData:isStatueCard(cardType)
    if cardType == CardSysConfigs.CardType.statue_green or cardType == CardSysConfigs.CardType.statue_blue or cardType == CardSysConfigs.CardType.statue_red then
        return true
    end
    return false
end

function CardSysRuntimeData:isMagicClan(clanType)
    if clanType == CardSysConfigs.CardClanType.quest_new then
        return true
    end
    return false
end

function CardSysRuntimeData:isMagicCard(_cardType)
    if _cardType == CardSysConfigs.CardType.quest_new then
        return true
    end
    return false
end

function CardSysRuntimeData:isQuestMagicClan(clanType)
    if clanType == CardSysConfigs.CardClanType.quest_magic then
        return true
    end
    return false
end

function CardSysRuntimeData:isQuestMagicCard(_cardType)
    if _cardType == CardSysConfigs.CardType.quest_magic_purple or _cardType == CardSysConfigs.CardType.quest_magic_red then
        return true
    end
    return false
end

function CardSysRuntimeData:isObsidianClan(_clanType)
    if _clanType == CardSysConfigs.CardClanType.obsidian then
        return true
    end
    return false
end

function CardSysRuntimeData:isObsidianCard(_cardType)
    if _cardType == CardSysConfigs.CardType.obsidian then
        return true
    end
    return false
end

-- 根据卡ID判断是否是黑耀卡
function CardSysRuntimeData:isObsidianCardWithCardId(_cardId)
    _cardId = _cardId or ""
    if string.find(_cardId, "^9001") then
        return true
    end
    return false
end

function CardSysRuntimeData:isCardNormalPoint(cardData)
    if cardData then
        if cardData.greenPoint and cardData.greenPoint > 0 then
            return true
        end
    end
    return false
end

function CardSysRuntimeData:isCardGoldPoint(cardData)
    if cardData then
        if cardData.goldPoint and cardData.goldPoint > 0 then
            return true
        end
    end
    return false
end

function CardSysRuntimeData:isCardConvertToCoin(cardData)
    if cardData then
        if cardData.exchangeCoins ~= nil and tonumber(cardData.exchangeCoins) > 0 then
            return true
        end
    end
    return false
end

function CardSysRuntimeData:sortCardClanInfo(cardClanData)
    local normalClans = {}
    local wildClans = {}
    local statueClans = {}
    local magicClans = {}
    local obsidianClans = {}
    for i = 1, #cardClanData do
        local clanData = cardClanData[i]
        if self:isWildClan(clanData.type) then
            wildClans[#wildClans + 1] = cardClanData[i]
        elseif self:isStatueClan(clanData.type) then
            statueClans[#statueClans + 1] = cardClanData[i]
        elseif self:isMagicClan(clanData.type) or self:isQuestMagicClan(clanData.type) then
            magicClans[#magicClans + 1] = cardClanData[i]         
        elseif self:isObsidianClan(clanData.type) then
            obsidianClans[#obsidianClans + 1] = cardClanData[i]
        else
            normalClans[#normalClans + 1] = cardClanData[i]
        end
    end

    local sortFunc = function(a, b)
        local aid = a and tonumber(a.clanId)
        local bid = b and tonumber(b.clanId)
        return aid <= bid
    end
    table.sort(wildClans, sortFunc)
    table.sort(normalClans, sortFunc)
    table.sort(statueClans, sortFunc)
    table.sort(magicClans, sortFunc)
    table.sort(obsidianClans, sortFunc)

    local allData = {}
    if #wildClans > 0 then
        for i = 1, #wildClans do
            allData[#allData + 1] = wildClans[i]
        end
    end
    if #normalClans > 0 then
        for i = 1, #normalClans do
            allData[#allData + 1] = normalClans[i]
        end
    end

    if #statueClans > 0 then
        for i = 1, #statueClans do
            allData[#allData + 1] = statueClans[i]
        end
    end

    if #magicClans > 0 then
        for i = 1, #magicClans do
            allData[#allData + 1] = magicClans[i]
        end
    end

    if #obsidianClans > 0 then
        for i = 1, #obsidianClans do
            allData[#allData + 1] = obsidianClans[i]
        end
    end

    return allData, wildClans, normalClans, statueClans, magicClans, obsidianClans
end

-- 卡册章节界面中的所有章节数据 --
function CardSysRuntimeData:getAlbumTalbeviewData()
    local albumInfo = self:getCardAlbumInfo()
    local cardClanData = albumInfo and albumInfo.cardClans or {}
    return self:sortCardClanInfo(cardClanData)
end

-- 卡组界面中使用的卡组数据 --
function CardSysRuntimeData:getClanDataByIndex(index)
    local albumsData = self:getAlbumTalbeviewData()
    return albumsData and albumsData[index]
end
function CardSysRuntimeData:getClanDataByClanId(clanId)
    local cardClanData = self:getAlbumTalbeviewData()
    if cardClanData == nil then
        return
    -- assert(false, "clanId ====== ",clanId)
    end
    for clanIndex = 1, #cardClanData do
        if tonumber(cardClanData[clanIndex].clanId) == tonumber(clanId) then
            return cardClanData[clanIndex]
        end
    end
    return
    -- assert(false, "clanId ====== ",clanId)
end

--- 卡册(章节)数据 界面 end -------------------------------------------------------------------------------

-- 根据数据判断 是否展示卡册面板 --
function CardSysRuntimeData:canShowCardAlbum()
    -- 如果当前只有一个赛季 或者玩家只参与了一个赛季 或者当前有未使用的ACE卡等 则不需要展示卡册 --

    return true
end

-- 是否有开启的赛季 --
function CardSysRuntimeData:hasSeasonOpening()
    -- release_print("---- nadomachine buff, CardSysRuntimeData:hasSeasonOpening 000----")
    local seasonsData = self:getSeasonData()
    if seasonsData then
        -- release_print("---- nadomachine buff, CardSysRuntimeData:hasSeasonOpening 111----")
        return seasonsData:hasSeasonOpening()
    end
    -- release_print("---- nadomachine buff, CardSysRuntimeData:hasSeasonOpening 222----")
    return false
end

-- 是否含有wild数据 --
function CardSysRuntimeData:hasWildCardData()
    local seasonsData = self:getSeasonData()
    if seasonsData then
        return seasonsData:hasWildCardData()
    end
    return false
end

-- 获取含有Link卡，并且能玩Link小游戏的第一个章节 --
-- 如果指定了clanID ，则不管有没有Link卡，返回这章节ID --
function CardSysRuntimeData:getFirstClanCanPlayLinkGame(clanId)
    local cardClanData = self:getAlbumTalbeviewData()
    if cardClanData then
        for clanIndex = 1, #cardClanData do
            local clanData = cardClanData[clanIndex].cards

            if clanId ~= nil then
                -- 如果指定了clanID ，则不管有没有Link卡，返回这章节ID --
                if tonumber(cardClanData[clanIndex].clanId) == tonumber(clanId) then
                    return clanIndex
                end
            else
                -- 如果没有指定 则遍历查找 --
                for index = 1, #clanData do
                    local card = clanData[index]
                    if card.type == "LINK" and card.linkCount ~= 0 then
                        return clanIndex
                    end
                end
            end
        end
    end
    return 1
end

function CardSysRuntimeData:getLinkGameCardData(clanIndex)
    local cardClanData = self:getAlbumTalbeviewData()
    local clanData = cardClanData[clanIndex].cards

    for i = 1, #clanData do
        local card = clanData[i]
        if card.type == "LINK" and card.linkCount > 0 then
            return card
        end
    end
    return
end

-- 多章节同时完成时数据处理 --
function CardSysRuntimeData:getDropClanData(clanReward)
    local clanRewardData = nil
    if #clanReward ~= 0 then
        table.sort(
            clanReward,
            function(a, b)
                return tonumber(a.id) <= tonumber(b.id)
            end
        )
        for k, clan in pairs(clanReward) do
            if not clan.isPop then
                clan.isPop = true
                clanRewardData = clan
                break
            end
        end
    end
    return clanRewardData
end

-- 设置历史掉落数据 --
function CardSysRuntimeData:setCardDropHistoryInfo(tInfo)
    self.m_CardDropHistoryInfo = ParseCardDropHistoryData:create()
    self.m_CardDropHistoryInfo:parseData(tInfo)
end

-- 获取历史掉落数据 --
function CardSysRuntimeData:getCardDropHistoryInfo()
    return self.m_CardDropHistoryInfo.records
end

-- 设置回收机回收卡片spin请求数据 --
function CardSysRuntimeData:setCardWheelSpinInfo(tInfo)
    self.m_CardWheelSpinInfo = ParseCardWheelSpinData:create()
    self.m_CardWheelSpinInfo:parseData(tInfo)
end

-- 获取回收机回收卡片spin请求数据 --
function CardSysRuntimeData:getCardWheelSpinInfo(tInfo)
    return self.m_CardWheelSpinInfo
end

-- 设置Link卡请求link游戏数据 --
function CardSysRuntimeData:setCardLinkPlayInfo(tInfo)
    if self.m_CardSeasonsInfo then
        local _nadoGame = self.m_CardSeasonsInfo.p_nadoGame
        if not _nadoGame then
            _nadoGame = ParseLinkGameData:create()
            self.m_CardSeasonsInfo.p_nadoGame = _nadoGame
        end
        _nadoGame:parseData(tInfo)
    end
end

-- 设置浏览卡片请求数据 --
function CardSysRuntimeData:setCardViewInfo(tInfo)
    self.m_CardViewInfo = ParseCardViewData:create()
    self.m_CardViewInfo:parseData(tInfo)
end

-- 获取浏览卡片请求数据 --
function CardSysRuntimeData:getCardViewInfo()
    return self.m_CardViewInfo
end

-- 获取当前年度 --
function CardSysRuntimeData:getCurrentYear()
    local _curAlbumId = self:getCurAlbumID()
    return tonumber(string.sub(_curAlbumId, 1, 4))
end

-- 获取当前年度的数据 --
function CardSysRuntimeData:getCurrentYearData()
    local year = self:getCurrentYear()
    local seasonsData = self:getSeasonData()
    if seasonsData then
        return seasonsData:getYearDataById(year)
    end
end

-- 获取当前年度的当前的赛季 --
function CardSysRuntimeData:getCurrentAlbum()
    local _yearData = self:getCurrentYearData()
    if _yearData then
        local _cardAlums = _yearData:getAlbumDatas()
        if _cardAlums then
            for i = 1, #_cardAlums do
                local _albumData = _cardAlums[i]
                if _albumData then
                    if _albumData:getStatus() == CardSysConfigs.CardSeasonStatus.online then
                        return i, _albumData:getSeason(), _albumData
                    end
                end
            end
        end
    end
    return nil, nil, nil
end

function CardSysRuntimeData:isSeasonOpen(year, season)
    local currentYear = self:getCurrentYear()
    local _, currentSeason = self:getCurrentAlbum()
    if tonumber(currentYear) == tonumber(year) and tonumber(currentSeason) == tonumber(season) then
        return true
    end
    return false
end

-- 【类型展示，重复卡不计数】 --
function CardSysRuntimeData:getClanCardTypeCount(cards)
    local count = 0
    for k, v in pairs(cards) do
        if v.count > 0 then
            count = count + 1
        end
    end
    return count
end

-- 是否有未使用的ACE卡 --
function CardSysRuntimeData:haveUnuseLinkCard(cards)
    for k, v in pairs(cards) do
        if v.type == CardSysConfigs.CardType.link and v.linkCount > 0 then
            return true
        end
    end
    return false
end

-- 通过卡牌数据获取所属的章节index 和 卡牌index
function CardSysRuntimeData:getClanIndex(cardData)
    local clans = self:getAlbumTalbeviewData()
    for i = 1, #clans do
        local cards = clans[i].cards
        for j = 1, #cards do
            if cards[j].cardId == cardData.cardId then
                return i, j
            end
        end
    end
    return
end

-- 回收机界面打开时的界面 --
function CardSysRuntimeData:getRecoverSourceUI(albumId)
    albumId = albumId or self:getSelAlbumID() or self:getCurAlbumID()
    return self.m_recoverSourceUIs and self.m_recoverSourceUIs[tostring(albumId)]
end

function CardSysRuntimeData:setRecoverSourceUI(source, albumId)
    albumId = albumId or self:getSelAlbumID() or self:getCurAlbumID()
    if not self.m_recoverSourceUIs then
        self.m_recoverSourceUIs = {}
    end
    self.m_recoverSourceUIs[tostring(albumId)] = source
end

function CardSysRuntimeData:setAutoEnterCard(autoEnter)
    self.m_autoEnter = autoEnter
end
function CardSysRuntimeData:getAutoEnterCard()
    return self.m_autoEnter
end

-- 自动进入集卡时自动进入卡册界面
function CardSysRuntimeData:setEnterClanId(clanId)
    self.m_enterClanId = clanId
end
function CardSysRuntimeData:getEnterClanId()
    return self.m_enterClanId
end

-- 自动进入集卡时只进入集卡首页
function CardSysRuntimeData:setEnterCardFroceSeason(forceSeason)
    self.m_enterForceSeason = forceSeason
end
function CardSysRuntimeData:getEnterCardFroceSeason()
    return self.m_enterForceSeason
end

-- 进入集卡时是如何进入的
-- 默认是大厅进入
function CardSysRuntimeData:getEnterCardType()
    return self.m_enterType or 1
end
function CardSysRuntimeData:setEnterCardType(enterType)
    self.m_enterType = enterType
end

-- 本次进入集卡系统后是否点击了link小游戏进入UI的关闭按钮
function CardSysRuntimeData:getLinkCardClickX()
    return self.m_isLinkCardLayerClickX
end
function CardSysRuntimeData:setLinkCardClickX(isClickX)
    self.m_isLinkCardLayerClickX = isClickX
end

function CardSysRuntimeData:isInGuide()
    return self.m_isInGuide
end

function CardSysRuntimeData:setInGuide(isGuide)
    self.m_isInGuide = isGuide
end

function CardSysRuntimeData:enterCard()
    self.m_isInCard = true
end

function CardSysRuntimeData:exitCard()
    self.m_isInCard = false
    --还原
    if self.m_portraitFlag then
        self:changePortraitFlag(false)
    end
end
--集卡系统在竖版关卡中
function CardSysRuntimeData:isPortraitCard()
    return self.m_portraitFlag
end
--物理改变屏幕方向
function CardSysRuntimeData:changePortraitFlag(flag)
    self.m_portraitFlag = flag
    -- globalData.slotRunData.isChangeScreenOrientation = flag
    -- globalData.slotRunData:changeScreenOrientation(not flag)
end

function CardSysRuntimeData:isInCard()
    return self.m_isInCard
end

-- 获取赛季结束的时间戳
function CardSysRuntimeData:getSeasonExpireAt()
    -- season = season or CardSysRuntimeMgr:getCurrentAlbum()
    -- local albumData = CardSysRuntimeMgr:getAlbumDataBySeason(season)
    -- local expireAt = albumData and math.floor((albumData.expireAt) / 1000) or 0
    -- return expireAt
    local expAt = 0
    local albumId, albumIndex, albumData = self:getCurrentAlbum()
    if albumData then
        expAt = albumData:getExpireAt() or 0
    end
    return math.floor(expAt / 1000)
end

-- 当前赛季结束时间戳
-- 返回值：
-- isEnd, isShow, textStr
function CardSysRuntimeData:updateCardTimeStr(expireAt, DayNum)
    local isEnd = false
    local isShow = false
    local textStr = ""
    local isTextPostfix = false
    DayNum = DayNum or self.m_showDayDefaultNum
    -- 当前时间戳
    local nowTime = math.floor(globalData.userRunData.p_serverTime / 1000)
    -- 一天的毫秒
    local leftTime = math.floor(expireAt - nowTime)
    if leftTime > 0 then
        -- 赛季如火如荼
        local day = math.floor(leftTime / ONE_DAY_TIME)
        if day <= DayNum then
            isShow = true
            if day >= 1 then
                -- 大于一天用day显示
                textStr = day
                isTextPostfix = true
            else
                -- 小于一天用时分秒显示
                textStr = util_count_down_str(leftTime)
            end
        else
            isShow = false
        end
    else
        -- 赛季结束了
        isShow = false
        isEnd = true
    end
    return isEnd, isShow, textStr, isTextPostfix
end

function CardSysRuntimeData:getLinkGameData()
    return self.m_CardSeasonsInfo and self.m_CardSeasonsInfo.p_nadoGame
end

function CardSysRuntimeData:getNadoGameReward(reward)
    local items = {}
    for k, v in pairs(reward or {}) do
        if k ~= "cardDrops" then
            if k == "rewards" then
                if v and #v > 0 then
                    -- 将道具组合
                    local cloneItemData = {}
                    for i = 1, #v do
                        if not cloneItemData[v[i].p_icon] then
                            cloneItemData[v[i].p_icon] = clone(v[i])
                        else
                            cloneItemData[v[i].p_icon].p_num = cloneItemData[v[i].p_icon].p_num + v[i].p_num
                        end
                    end
                    local __index = 0
                    for __k, __v in pairs(cloneItemData) do
                        __index = __index + 1
                        if not items[k] then
                            items[k] = {}
                        end
                        items[k][__index] = __v
                    end
                end
            else
                items[k] = v
            end
        end
    end
    return items
end

function CardSysRuntimeData:setClickOtherInAlbum(isClickOther)
    self.m_isClickOtherInAblum = isClickOther
end

function CardSysRuntimeData:isClickOtherInAlbum()
    return self.m_isClickOtherInAblum
end

function CardSysRuntimeData:isWildDropType(_dropType)
    if _dropType == CardSysConfigs.CardDropType.wild then
        return true
    elseif _dropType == CardSysConfigs.CardDropType.wild_normal then
        return true
    elseif _dropType == CardSysConfigs.CardDropType.wild_link then
        return true
    elseif _dropType == CardSysConfigs.CardDropType.wild_golden then
        return true
    end
    return false
end

function CardSysRuntimeData:isStatueDropType(_dropType)
    if _dropType == CardSysConfigs.CardDropType.statue then
        return true
    elseif _dropType == CardSysConfigs.CardDropType.statue_green then
        return true
    elseif _dropType == CardSysConfigs.CardDropType.statue_blue then
        return true
    elseif _dropType == CardSysConfigs.CardDropType.statue_red then
        return true
    end
    return false
end

-- Global Var --
GD.CardSysRuntimeMgr = CardSysRuntimeData:getInstance()
