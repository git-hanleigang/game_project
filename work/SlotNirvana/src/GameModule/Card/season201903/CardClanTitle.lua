--[[
    卡组的标题
    201903
]]
local CardClanTitleBase = util_require("GameModule.Card.baseViews.CardClanTitleBase")
local CardClanTitle = class("CardClanTitle", CardClanTitleBase)

function CardClanTitle:initUI()
    CardClanTitle.super.initUI(self)
    self:initTitleLight()
end

function CardClanTitle:initCsbNodes()
    CardClanTitle.super.initCsbNodes(self)
    self.m_cardLogo         = self:findChild("card_logo")
    self.m_coinNormal       = self:findChild("Node_show1")
    self.m_coinCompleted    = self:findChild("Node_show2")
    self.m_dengNode         = self:findChild("Node_deng")    
    self.m_btnQuest         = self:findChild("Button_i")
end

-- 子类重写
function CardClanTitle:getCsbName()
    return string.format(CardResConfig.seasonRes.CardClanTitleRes, "season201903")
end

-- 子类重写
function CardClanTitle:getTitleLightLua()
    return "GameModule.Card.season201903.CardClanTitleLight"
end

-- 子类重写
function CardClanTitle:getQuestInfoLua()
    return "GameModule.Card.season201903.CardClanQuestInfo"    
end

function CardClanTitle:initTitleLight()
    if not self.m_titleLight then
        self.m_titleLight = util_createView(self:getTitleLightLua())
        self.m_dengNode:addChild(self.m_titleLight)
    end
end

function CardClanTitle:updateView(index, clanData)
    CardClanTitle.super.updateView(self, index, clanData)
    self:changeAnim(index)
    self.curTitleIndex = index
end

function CardClanTitle:getMovePageFlag()
    return not self.playAnimFlag
end

function CardClanTitle:setPlayChangeAnimCallBack(callBack)
    self.playChangeAnimCallBack = callBack
end

function CardClanTitle:changeAnim(index)
    self.playAnimFlag = true
    self:updateCoin(index)
    self:updateQuestBtn()
    if self.curTitleIndex == nil then
        self:updateLogo()
        
        performWithDelay(self, function()
            self.playAnimFlag = nil
        end, 12/45)
        self:runCsbAction("show",false,function()
            self:updateIdleAnim(index)
        end)
    else
        if self.playChangeAnimCallBack ~= nil then
            self.playChangeAnimCallBack(index)
        end
        self:runCsbAction("change_down",false,function()
            self:updateLogo()
            self:runCsbAction("change_up",false,function()
                self:updateIdleAnim(index)
                self.playAnimFlag = nil
            end)
        end)
    end
end

function CardClanTitle:closeUI()
    self:runCsbAction("over",false)
end

function CardClanTitle:updateIdleAnim(index)
    self:runCsbAction("idle",true)
end

-- logo
function CardClanTitle:updateLogo()
    local icon = CardResConfig.getCardClanIcon(self.m_clanData.clanId)
    util_changeTexture(self.m_cardLogo, icon)
end

-- 奖励
function CardClanTitle:updateCoin()
    local count = CardSysRuntimeMgr:getClanCardTypeCount(self.m_clanData.cards)
    local isCompleted = count >= #self.m_clanData.cards
    if isCompleted then
        self.m_coinNormal:setVisible(false)
        self.m_coinCompleted:setVisible(true)
    else
        local lb_coins = self:findChild("coins")
        local sp_coins_zi = self:findChild("coins_zi")
        lb_coins:setString(util_formatCoins(tonumber(self.m_clanData.coins), 30).." COINS")

        local size = lb_coins:getContentSize()
        local scale = lb_coins:getScale()
        local pos = cc.p(lb_coins:getPosition())
        sp_coins_zi:setPositionX(pos.x + (scale*size.width)/2 + 5)

        self.m_coinNormal:setVisible(true)
        self.m_coinCompleted:setVisible(false)
    end
end

-- quest章节
function CardClanTitle:updateQuestBtn()
    local isShow = false
    if self.m_clanData.type == CardSysConfigs.CardClanType.quest then
        isShow = true
    end
    
    self.m_btnQuest:setVisible(isShow)
end

function CardClanTitle:clickFunc(sender)
    local name = sender:getName()
    if name == "Button_i" then
        -- 打开quest介绍弹板
        local view = util_createView(self:getQuestInfoLua())
        gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
    end
end

return CardClanTitle