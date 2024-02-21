--[[
    author:{author}
    time:2019-07-16 14:35:39
]]

local BaseView = util_require("base.BaseView")
local BigCardLayer = class("BigCardLayer", BaseView)
BigCardLayer.m_showNum = 10

function BigCardLayer:initUI(clanIndex, index)
    local isAutoScale      =  true
    if CC_RESOLUTION_RATIO == 3 then
        isAutoScale        =  false
    end

    self:createCsbNode( CardResConfig.BigCardLayerRes , isAutoScale )

    self.m_cardLayer    = self:findChild("CardLayer")
    self.btnLeft        = self:findChild("Button_left")
    self.btnRight       = self:findChild("Button_right")
    self.m_clanIndex    = clanIndex
    self.m_index        = index
    self:updateUI(true)

    self.m_layerRight   = self:findChild("layer_right")
    self.m_layerLeft    = self:findChild("layer_left")
    self:addClick(self.m_layerRight)
    self:addClick(self.m_layerLeft)

    self:runCsbAction("start",false,function()
        self:runCsbAction("idle")
    end)
end

function BigCardLayer:getClanData()
    local clansData = CardSysRuntimeMgr:getAlbumTalbeviewData()
    return clansData and clansData[self.m_clanIndex]
end

function BigCardLayer:getCardData(index)
    local clansData = self:getClanData()
    return clansData and clansData.cards and clansData.cards[index]
end

function BigCardLayer:updateUI(isInit)
    local cardData = self:getCardData(self.m_index)

    -- 按钮显示
    self.btnLeft:setVisible(self.m_index > 1)
    self.btnRight:setVisible(self.m_index < self.m_showNum)

    -- 卡牌信息
    self.m_cardLayer:removeAllChildren()

    local view = util_createView("GameModule.Card.season201901.LongCardUnitView", cardData, nil, "idle", true)
    self.m_cardLayer:addChild(view)
    local size = self.m_cardLayer:getContentSize()
    view:setPosition(cc.p(size.width*0.5, size.height*0.5))

end

function BigCardLayer:addIndex()
    if self.m_index >= self.m_showNum then
        return
    end
    self.m_index = self.m_index + 1
    self:updateUI()
end

function BigCardLayer:subIndex()
    if self.m_index <= 1 then
        return
    end
    self.m_index = self.m_index - 1
    self:updateUI()
end

function BigCardLayer:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()
    if name == "Button_left" then
        if self.m_index <= 1 then
            return
        end
        gLobalSoundManager:playSound(CardResConfig.CARD_MUSIC.BtnClick)
        self:subIndex()
    elseif name == "Button_right" then
        if self.m_index >= self.m_showNum then
            return
        end
        gLobalSoundManager:playSound(CardResConfig.CARD_MUSIC.BtnClick)
        self:addIndex()
    elseif name == "Button_x" then
        gLobalSoundManager:playSound(CardResConfig.CARD_MUSIC.BtnBack)
        CardSysManager:closeBigCardView()
    elseif name == "layer_right" then
        if self.m_index >= self.m_showNum then
            return
        end
        gLobalSoundManager:playSound(CardResConfig.CARD_MUSIC.BtnClick)
        self:addIndex()
    elseif name == "layer_left" then
        if self.m_index <= 1 then
            return
        end
        gLobalSoundManager:playSound(CardResConfig.CARD_MUSIC.BtnClick)
        self:subIndex()
    end
end

function BigCardLayer:closeUI()
    if self.isClose then
        return
    end
    self.isClose=true

    self:removeFromParent()
end

return BigCardLayer