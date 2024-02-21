--[[--
    下UI奖励面板上的气泡
]]
local CardRecoverLettoRewardBubble = class("CardRecoverLettoRewardBubble", BaseView)

function CardRecoverLettoRewardBubble:initUI()
    CardRecoverLettoRewardBubble.super.initUI(self)

    self:initData()
    self:initView()
end

function CardRecoverLettoRewardBubble:getCsbName()
    return string.format(CardResConfig.commonRes.CardRecoverLettoBottomBubbleRes, "common"..CardSysRuntimeMgr:getCurAlbumID())
end

function CardRecoverLettoRewardBubble:initCsbNodes()
    self.m_fntStatueChipMul = self:findChild("chips_chengbei")
    self.m_fntStatueBuffMul = self:findChild("buff_chengbei")
    self.m_touchLayer = self:findChild("touch")
    self:addClick(self.m_touchLayer)
end

function CardRecoverLettoRewardBubble:initData()
    self.m_statueChipMul = 100
    local tCards = CardSysManager:getRecoverMgr():getMaxStarCardList()
    for i=1,#tCards do
        local cardData = tCards[i].cardData
        local cardMul = (tCards[i].cardMul)*100
        self.m_statueChipMul = self.m_statueChipMul + cardMul
    end

    self.m_statueBuffMul = 100
    local buffMul = CardSysManager:getBuffDataByType(BUFFTYPY.BUFFTYPE_CARD_LOTTO_COIN_BONUS)
    if buffMul and buffMul > 0 then
        self.m_statueBuffMul = buffMul*100
    end
end

function CardRecoverLettoRewardBubble:initView()
    self.m_fntStatueChipMul:setString(self.m_statueChipMul.."%")
    self.m_fntStatueBuffMul:setString(self.m_statueBuffMul.."%")
end

function CardRecoverLettoRewardBubble:onEnter()
    self:runCsbAction("show", false, function()
        self:runCsbAction("idle", true, nil, 60)
    end, 60)
end

function CardRecoverLettoRewardBubble:closeUI()
    if self.closed then
        return
    end 
    self.closed = true
    self:runCsbAction("over", false, function()
        self:removeFromParent()
    end, 60)
end

function CardRecoverLettoRewardBubble:clickFunc(sender)
    local name = sender:getName()
    if name == "touch" then
        self:closeUI()      
    end
end


return CardRecoverLettoRewardBubble
