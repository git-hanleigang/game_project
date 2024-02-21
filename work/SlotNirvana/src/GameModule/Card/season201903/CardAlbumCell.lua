--[[
    author:{author}
    time:2019-07-08 14:28:18
]]
local BaseView = util_require("base.BaseView")
local CardAlbumCell = class(CardAlbumCell, BaseView)

function CardAlbumCell:getCsbName()
    return string.format(CardResConfig.seasonRes.CardAlbumCellRes, "season201903")
end

function CardAlbumCell:getTagNewLua()
    return "GameModule.Card.season201903.CardTagNew"    
end

-- 初始化UI --
function CardAlbumCell:initUI()
    self:createCsbNode(self:getCsbName())
    self:initNode()
end

function CardAlbumCell:initNode()
    self.m_nodeBase = self:findChild("Node_zong")
    self.m_spLogo = self:findChild("sp_logo")
    self.m_spLogoDark = self:findChild("sp_logo_dark")
    self.m_procellLb = self:findChild("BitmapFontLabel_1")
    self.m_newNode = self:findChild("Node_new")
    self.m_jindu = self:findChild("jindu")
    self.m_spDuihao = self:findChild("sp_duihao")

    self.m_touch = self:findChild("touch")
    self:addClick(self.m_touch)
    self.m_touch:setSwallowTouches(false)
end

function CardAlbumCell:getContentSize()
    return cc.size(368,386)
end

function CardAlbumCell:playAnim(isPlayStart)
    if isPlayStart then
        self:runCsbAction("show", false, function()
            self:runCsbAction("idle", true)
        end)
    else
        self:runCsbAction("idle", true)
    end
    
end

function CardAlbumCell:updateCell(clanIndex, cellData)
    self.m_clanIndex = clanIndex
    self.m_cellData = cellData

    -- 卡组logo
    local icon = CardResConfig.getCardClanIcon( self.m_cellData.clanId)
    util_changeTexture(self.m_spLogo, icon)
    util_changeTexture(self.m_spLogoDark, icon)

    -- 章节卡牌收集进度，【类型展示，重复卡不计数】
    local cur = CardSysRuntimeMgr:getClanCardTypeCount(self.m_cellData.cards)
    local max = #self.m_cellData.cards
    self.m_jindu:setPercent(cur*100/max)
    if cur == max then
        self.m_spDuihao:setVisible(true)
        self.m_procellLb:setVisible(false)
    else
        self.m_spDuihao:setVisible(false)
        self.m_procellLb:setVisible(true)
        self.m_procellLb:setString(string.format("%d/%d", cur, max))
    end
end

function CardAlbumCell:updateTagNew()
    -- new
    local isNew = self:hasNewCardInClan()
    if not self.m_tagNewUI then
        self.m_tagNewUI = util_createView(self:getTagNewLua())
        self.m_tagNewUI:playIdle()
        self.m_newNode:addChild(self.m_tagNewUI)
    end
    self.m_tagNewUI:setVisible(isNew)    
end

function CardAlbumCell:clickFunc(sender)
    local name = sender:getName()
    if name == "touch" then

        -- 新手期新增章节和卡牌新手引导：移除章节引导
        local noviceAlbumView = gLobalViewManager:getViewByName("CardAlbumView" .. "season302301")
        if noviceAlbumView then
            noviceAlbumView:removeGuideMask()
        end

        gLobalSoundManager:playSound(CardResConfig.CARD_MUSIC.BtnClick)
        -- TEST 显示卡组选择界面 --
        self:runCsbAction("animation0", false, function()
            self:runCsbAction("idle")
        end)
        CardSysManager:showCardClanView(self.m_clanIndex, true)
        self:checkLogNovicePopup()
    end
end

function CardAlbumCell:hasNewCardInClan()
    if self.m_cellData and self.m_cellData.cards and #self.m_cellData.cards > 0 then
        for i = 1, #self.m_cellData.cards do
            local cardData = self.m_cellData.cards[i]
            if cardData.newCard == true then
                return true
            end
        end
    end
    return false
end

-- 新手期集卡宣传图 进入集卡 是否 点击了第一个卡册
function CardAlbumCell:checkLogNovicePopup()
    local bNovice = CardSysManager:isNovice()
    if not bNovice or self.m_clanIndex ~= 1 then
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

    logNovice:sendPopupLayerLog("Play", "CP", cardPubEnterInfo.entrySite, nil, true)
    logNovice:resetNewUserGoCardSysSign()
end

function CardAlbumCell:getGuideNode()
    return self.m_nodeBase
end

return CardAlbumCell