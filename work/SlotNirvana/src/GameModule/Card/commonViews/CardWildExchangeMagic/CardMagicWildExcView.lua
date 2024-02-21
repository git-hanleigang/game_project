--[[
    集卡  Magic卡 wild兑换主界面
--]]
local CardMagicWildExcView = class("CardMagicWildExcView", BaseLayer)
local CardMagicWildExcTableView =
    util_require("GameModule.Card.commonViews.CardWildExchangeMagic.CardMagicWildExcTableView")

-- 显示卡类型
local SHOW_TYPE = {
    SHOW_ALL = 1,
    SHOW_NO_HAVE = 2
}

function CardMagicWildExcView:initDatas(_wildType, _sourceType, _closeCB, _cancelCB)
    CardMagicWildExcView.super.initDatas(self)

    self.m_clanType = CardSysConfigs.CardClanType.quest_magic
    self.m_wildType = _wildType
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
    CardSysManager:getWildExcMgr():setShowAll(true)
    CardSysManager:getWildExcMgr():setSelCardId(nil)
    self.m_tableViewList = {}
    self:setPauseSlotsEnabled(true)
    self:setName("CardMagicWildExcView")
    self:setExtendData("CardMagicWildExcView")
    self:setLandscapeCsbName(
        "CardRes/" .. G_GetMgr(G_REF.CardSpecialClan):getThemeName() .. "/csb/wild/cash_wild_exchange_layer.csb"
    )
end

function CardMagicWildExcView:initCsbNodes()
    CardMagicWildExcView.super.initCsbNodes(self)

    self.m_lbTime = self:findChild("lb_time")
    self.m_sp_title_logo_purple = self:findChild("sp_title_logo_1")
    self.m_sp_title_logo_red = self:findChild("sp_title_logo_2")
end

function CardMagicWildExcView:initView()
    CardMagicWildExcView.super.initView(self)

    -- 初始化按钮文本
    self:initButtonLabel()
    -- 初始化title
    self:initTitle()
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

function CardMagicWildExcView:initButtonLabel()
    self:setButtonLabelContent("btn_exchange", "ADD TO MY ALBUM")
end

function CardMagicWildExcView:initTitle()
    local wildType = self.m_wildType
    if wildType then
        self.m_sp_title_logo_red:setVisible(wildType == CardSysConfigs.CardType.wild_magic_red)
        self.m_sp_title_logo_purple:setVisible(wildType == CardSysConfigs.CardType.wild_magic_purple)
    end
end

-- 倒计时
function CardMagicWildExcView:initCountdownUI()
    local wildExcExpireAt = self.m_wildExcData:getExpireAt() -- wild卡倒计时 毫秒
    local seasonExpire = CardSysManager:getSeasonExpireAt() -- 赛季倒计时
    local expire = math.min(seasonExpire, math.floor(wildExcExpireAt * 0.001))
    self.m_widlCardExcExpire = expire
    self.m_scheduler =
        schedule(
        self,
        function()
            self:updateCountdonwUI(expire)
        end,
        1
    )
    self:updateCountdonwUI(expire)
end

function CardMagicWildExcView:updateCountdonwUI(_expireSec)
    local timeStr, bOver = util_daysdemaining(_expireSec, true)
    self.m_wildCardExcOver = bOver
    if bOver then
        self:updateExcBtnState()
        self:clearScheduler()
        self:closeUI(self.m_closeCB)
        G_GetMgr(G_REF.CardSpecialClan):checkCloseExcConfirmUI()
    end
    self.m_lbTime:setString(timeStr)
end

-- 待兑换卡列表
function CardMagicWildExcView:updateCardTbView()
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

    self.m_tableViewList[self.m_showType] = CardMagicWildExcTableView.new(param)
    tbParent:addChild(self.m_tableViewList[self.m_showType])

    local albumId = CardSysRuntimeMgr:getSelAlbumID() or CardSysRuntimeMgr:getCurAlbumID()
    if not albumId then
        return
    end

    local cardAlbums =
        CardSysManager:getWildExcMgr():getAlbumDataByAlbumId(
        albumId,
        CardSysManager:getWildExcMgr():getShowAll(),
        self.m_clanType
    )
    if (not cardAlbums) or (not cardAlbums.cardSpecialClans) or (not cardAlbums.cardSpecialClans[self.m_clanType]) then
        return
    end

    local specialClan = cardAlbums.cardSpecialClans[self.m_clanType]
    local cardClanList = {}
    for i = 1, #specialClan do
        local cardClanData = specialClan[i]
        if cardClanData then
            table.insert(cardClanList, cardClanData)
        end
    end

    if #cardClanList <= 0 then
        return
    end

    if self.m_showType == SHOW_TYPE.SHOW_NO_HAVE then
        self.m_tableViewList[self.m_showType]:releadCardsData(cardClanList)
    else
        self.m_tableViewList[self.m_showType]:releadCardsData(cardClanList, true)
    end
end

-- 更新 tbView 显隐
function CardMagicWildExcView:updateCardTbViewVisible()
    local bShowAll = self.m_showType == SHOW_TYPE.SHOW_ALL
    if self.m_tableViewList[SHOW_TYPE.SHOW_ALL] then
        self.m_tableViewList[SHOW_TYPE.SHOW_ALL]:setVisible(bShowAll)
    end

    if self.m_tableViewList[SHOW_TYPE.SHOW_NO_HAVE] then
        self.m_tableViewList[SHOW_TYPE.SHOW_NO_HAVE]:setVisible(not bShowAll)
    end

    CardSysManager:getWildExcMgr():setShowAll(not bShowAll)
end

-- 显示卡片 typeBtn
function CardMagicWildExcView:updateShowChipTypeUI()
    local btnCheckBox = self:findChild("btn_checkBoxState")
    btnCheckBox:setEnabled(self.m_showType == SHOW_TYPE.SHOW_ALL)
end

-- 兑换按钮触摸状态
function CardMagicWildExcView:updateExcBtnState()
    local curSelCardId = CardSysManager:getWildExcMgr():getSelCardId()
    local bEnabled = not self.m_wildCardExcOver and curSelCardId ~= nil
    self:setButtonLabelDisEnabled("btn_exchange", bEnabled)
end

function CardMagicWildExcView:clickFunc(sender)
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
        G_GetMgr(G_REF.CardSpecialClan):showWildExcCloseConfirmUI(self.m_widlCardExcExpire, confirmCB)
    elseif name == "btn_exchange" then
        -- 去兑换 --
        local selCardId = CardSysManager:getWildExcMgr():getSelCardId()
        if not selCardId then
            return
        end
        local cardData = CardSysManager:getWildExcMgr():getCardDataByCardId(selCardId, self.m_clanType)
        if not cardData then
            return
        end

        local confirmCB = function()
            if tolua.isnull(self) then
                return
            end

            self:gotoExchangeCard(cardData)
        end
        G_GetMgr(G_REF.CardSpecialClan):showWildExchangeConfirmUI(cardData, confirmCB)
    elseif name == "btn_showAll" then
        -- 改变显示 卡类型
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        self.m_showType = (self.m_showType == SHOW_TYPE.SHOW_NO_HAVE and SHOW_TYPE.SHOW_ALL or SHOW_TYPE.SHOW_NO_HAVE)
        self:updateShowChipTypeUI()
        self:updateCardTbViewVisible()
        self:updateCardTbView()
    end
end

-- 去兑换
function CardMagicWildExcView:gotoExchangeCard(_cardData)
    if not _cardData or self.m_bNeting == true then
        return
    end
    self.m_bNeting = true
    local tExtraInfo = {
        ["newCardId"] = _cardData.cardId,
        ["type"] = CardSysManager:getWildExcMgr():getCurrentWildExchangeType()
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

function CardMagicWildExcView:closeUI(_cb)
    if self.m_closing then
        return
    end
    self.m_closing = true

    CardMagicWildExcView.super.closeUI(self, _cb)
end

-- 清楚定时器
function CardMagicWildExcView:clearScheduler()
    if self.m_scheduler then
        self:stopAction(self.m_scheduler)
        self.m_scheduler = nil
    end
end

function CardMagicWildExcView:updateCellSelState()
    if self.m_tableViewList[SHOW_TYPE.SHOW_ALL] then
        self.m_tableViewList[SHOW_TYPE.SHOW_ALL]:updateCellSelState()
    end

    if self.m_tableViewList[SHOW_TYPE.SHOW_NO_HAVE] then
        self.m_tableViewList[SHOW_TYPE.SHOW_NO_HAVE]:updateCellSelState()
    end

    self:updateExcBtnState()
end

return CardMagicWildExcView
