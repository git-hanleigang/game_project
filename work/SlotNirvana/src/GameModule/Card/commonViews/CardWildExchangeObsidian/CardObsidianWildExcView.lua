--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-02-22 17:27:24
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-02-22 17:27:46
FilePath: /SlotNirvana/src/GameModule/Card/commonViews/CardWildExchangeObsidian/CardObsidianWildExcView.lua
Description: 集卡  黑耀卡 wild兑换主界面
--]]
local CardObsidianWildExcView = class("CardObsidianWildExcView", BaseLayer)
local CardObsidianWildExcTableView = util_require("GameModule.Card.commonViews.CardWildExchangeObsidian.CardObsidianWildExcTableView")

-- 显示卡类型
local SHOW_TYPE = {
    SHOW_ALL = 1,
    SHOW_NO_HAVE = 2,
}

function CardObsidianWildExcView:initDatas(_seasonId, _sourceType, _closeCB, _cancelCB)
    CardObsidianWildExcView.super.initDatas(self)

    self.m_seasonId = _seasonId or G_GetMgr(G_REF.ObsidianCard):getSeasonId()
    self.m_sourceType = _sourceType
    self.m_closeCB = function()
        -- 大厅点击集卡 进来的 主动关闭后显示集卡
        if self.m_sourceType and self.m_sourceType == "lobby" then
            CardSysRuntimeMgr:setIgnoreWild(true)
            CardSysManager:enterCardCollectionSys()
        end
        -- 主动关闭回调， 兑换关闭走统一兑换cb
        if _closeCB then
            _closeCB()
        end
    end
    self.m_cancelCB = _cancelCB
    
    self.m_wildExcData = CardSysManager:getWildExcMgr():getRunData()

    self.m_showType = SHOW_TYPE.SHOW_NO_HAVE
    CardSysManager:getWildExcMgr():setShowAll(false)
    CardSysManager:getWildExcMgr():setSelCardId(nil)
    self.m_tableViewList = {}
    self:setPauseSlotsEnabled(true)
    self:setName("CardObsidianWildExcView")
    self:setExtendData("CardObsidianWildExcView")
    self:setLandscapeCsbName(string.format("CardRes/CardObsidian_%s/csb/wild/cash_wild_exchange_layer.csb", self.m_seasonId))
end

function CardObsidianWildExcView:initCsbNodes()
    CardObsidianWildExcView.super.initCsbNodes(self)
    
    self.m_lbTime = self:findChild("lb_time")
end

function CardObsidianWildExcView:initView()
    CardObsidianWildExcView.super.initView(self)
    
    -- 倒计时
    self:initCountdownUI()
    -- 待兑换卡列表
    self:updateCardTbView()
    -- 显示卡片 typeBtn
    self:updateShowChipTypeUI()
    -- 兑换按钮触摸状态
    self:updateExcBtnState()

    self:runCsbAction("idle")
end

-- 倒计时
function CardObsidianWildExcView:initCountdownUI()
    local obsidianYearsData = G_GetMgr(G_REF.ObsidianCard):getShortCardYears()
    local wildExcExpireAt = self.m_wildExcData:getExpireAt()
    local albumId = G_GetMgr(G_REF.ObsidianCard):getCurAlbumID()
    local obsidianExpireSec = obsidianYearsData:getExpireAt(albumId)
    local expire = math.min(obsidianExpireSec, math.floor(wildExcExpireAt * 0.001))
    self.m_widlCardExcExpire = expire
    self.m_scheduler = schedule(self, function()
        self:updateCountdonwUI(expire)
    end, 1)
    self:updateCountdonwUI(expire)
end
function CardObsidianWildExcView:updateCountdonwUI(_expireSec)
    local timeStr, bOver = util_daysdemaining(_expireSec, true)
    self.m_wildCardExcOver = bOver
    if bOver then
        self:updateExcBtnState()
        self:clearScheduler()
        self:closeUI(self.m_closeCB)
        G_GetMgr(G_REF.ObsidianCard):checkCloseExcConfirmUI()
    end
    self.m_lbTime:setString(timeStr)
end

-- 待兑换卡列表
function CardObsidianWildExcView:updateCardTbView()
    if self.m_tableViewList[self.m_showType] then
        return
    end
    
    local tbParent = self:findChild("layout_content")
    local size = tbParent:getContentSize()
    local param = {
        tableSize = size,
        parentPanel = tbParent,
        directionType = 2
    }

    self.m_tableViewList[self.m_showType] = CardObsidianWildExcTableView.new(param)
    tbParent:addChild(self.m_tableViewList[self.m_showType])

    local cardAlbums = self.m_wildExcData:getWildObsidianCardAlbums()
    if #cardAlbums == 0 then
        return
    end
    -- 黑耀卡 赛季只有一个 album
    local cardClanData = cardAlbums[1].cardClans
    if not cardClanData then
        return
    end

    local cards = cardClanData.cards or {}
    if self.m_showType == SHOW_TYPE.SHOW_NO_HAVE then
        local filterCards = self:getNoHaveCardsList(cards)
        self.m_tableViewList[self.m_showType]:releadCardsData(filterCards)
    else
        self.m_tableViewList[self.m_showType]:releadCardsData(cards, true)
    end
end
-- 获取 玩家身上没有的卡列表
function CardObsidianWildExcView:getNoHaveCardsList(_cards)

    local filterCards = {}
    for idx, cardData  in ipairs(_cards) do
        if cardData.count and cardData.count <= 0 then
            table.insert(filterCards, cardData)
        end
    end

    return filterCards
end

-- 更新 tbView 显隐
function CardObsidianWildExcView:updateCardTbViewVisible()
    local bShowAll = self.m_showType == SHOW_TYPE.SHOW_ALL
    if self.m_tableViewList[SHOW_TYPE.SHOW_ALL] then
        self.m_tableViewList[SHOW_TYPE.SHOW_ALL]:setVisible(bShowAll)
    end

    if self.m_tableViewList[SHOW_TYPE.SHOW_NO_HAVE] then
        self.m_tableViewList[SHOW_TYPE.SHOW_NO_HAVE]:setVisible(not bShowAll)
    end

    CardSysManager:getWildExcMgr():setShowAll(bShowAll)
end

-- 显示卡片 typeBtn
function CardObsidianWildExcView:updateShowChipTypeUI()
    local btnCheckBox = self:findChild("btn_checkBoxState")
    btnCheckBox:setEnabled(self.m_showType == SHOW_TYPE.SHOW_ALL)
end

-- 兑换按钮触摸状态
function CardObsidianWildExcView:updateExcBtnState()
    local curSelCardId = CardSysManager:getWildExcMgr():getSelCardId()
    local bEnabled = not self.m_wildCardExcOver and curSelCardId ~= nil
    self:setButtonLabelDisEnabled("btn_exchange", bEnabled) 
end

function CardObsidianWildExcView:clickFunc(sender)
    local name = sender:getName()

    if name == "btn_close" then
        -- 关闭
        if self.m_wildCardExcOver then
            self:closeUI(self.m_closeCB)
            return
        end

        local confirmCB = function()
            if tolua.isnull(self) then
                return
            end
            self:closeUI(self.m_closeCB)
        end
        G_GetMgr(G_REF.ObsidianCard):showWildExcCloseConfirmUI(self.m_widlCardExcExpire, confirmCB)
    elseif name == "btn_exchange" then
        -- 去兑换 --
        local selCardId = CardSysManager:getWildExcMgr():getSelCardId()
        if not selCardId then
            return
        end
        local cardData = CardSysManager:getWildExcMgr():getObsidianCardDataByCardId(selCardId)
        if not cardData then
            return
        end

        local confirmCB = function()
            if tolua.isnull(self) then
                return
            end

            self:gotoExchangeCard(cardData)
        end
        G_GetMgr(G_REF.ObsidianCard):showWildExchangeConfirmUI(cardData, confirmCB)
    elseif name == "btn_showAll" then
        -- 改变显示 卡类型
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        self.m_showType = (self.m_showType == SHOW_TYPE.SHOW_NO_HAVE and SHOW_TYPE.SHOW_ALL or SHOW_TYPE.SHOW_NO_HAVE)
        self:updateShowChipTypeUI()
        self:updateCardTbView()
        self:updateCardTbViewVisible()
    end
end

-- 去兑换
function CardObsidianWildExcView:gotoExchangeCard(_cardData)
    if not _cardData or self.m_bNeting == true then
        return
    end
    self.m_bNeting = true
    local tExtraInfo = {
        ["newCardId"] = _cardData.cardId,
        ["type"] = CardSysConfigs.CardType.wild_obsidian
    }
    local excSuccess = function()
        CardSysManager:doWildExchange()
        if not tolua.isnull(self) then
            self.m_bNeting = false
            self:closeUI(self.m_cancelCB)
        end
    end
    local excFaild = function(errorCode, errorData)
        if not tolua.isnull(self) then
            self.m_bNeting = false
        end
    end
    CardSysManager:getWildExcMgr():sendCardExchangeRequest(tExtraInfo, excSuccess, excFaild)
end

function CardObsidianWildExcView:closeUI(_cb)
    if self.m_closing then
        return
    end
    self.m_closing = true

    CardObsidianWildExcView.super.closeUI(self, _cb)
end

-- 清楚定时器
function CardObsidianWildExcView:clearScheduler()
    if self.m_scheduler then
        self:stopAction(self.m_scheduler)
        self.m_scheduler = nil
    end
end

function CardObsidianWildExcView:updateCellSelState()
    if self.m_tableViewList[SHOW_TYPE.SHOW_ALL] then
        self.m_tableViewList[SHOW_TYPE.SHOW_ALL]:updateCellSelState()
    end

    if self.m_tableViewList[SHOW_TYPE.SHOW_NO_HAVE] then
        self.m_tableViewList[SHOW_TYPE.SHOW_NO_HAVE]:updateCellSelState()
    end

    self:updateExcBtnState()
end
return CardObsidianWildExcView