--[[
    卡牌基础信息展示面板 基类
]]
local BaseView = util_require("base.BaseView")
local BaseCardUnitView = class("BaseCardUnitView", BaseView)

-- 提取变量方便控制
local CARD_STAR_WIDTH = 60 -- 星星资源宽度
local CARD_STAR_INTERVAL = 10 -- 星星之间的间隙

BaseCardUnitView.m_cardData = nil
BaseCardUnitView.m_lastCardData = nil

function BaseCardUnitView:ctor()
    BaseCardUnitView.super.ctor(self)
end

-- 初始化UI --
function BaseCardUnitView:initUI(cardData, touchLayer, actionName, useClanIcon)
    self:reloadUI(cardData, touchLayer, actionName, useClanIcon)
end

-- 重新加载 --
function BaseCardUnitView:reloadUI(cardData, touchLayer, actionName, useClanIcon)
    self:initData(cardData, actionName, useClanIcon)
    self:updateUI()
end

-- 流程 start ---------------------------------------------------------

-- 创建csb文件，需要重写 --
function BaseCardUnitView:createCsbInfo(actionName)
end

-- 初始化数据 --
function BaseCardUnitView:initData(data, actionName, useClanIcon)
    self.isClose = false
    self.m_cardData = data
    self.m_useClanIcon = useClanIcon
    self:initSpecialData()
    self:createCsbInfo(actionName)
end

function BaseCardUnitView:initSpecialData()
end

function BaseCardUnitView:setCardData(cardData)
    self.m_lastCardData = self.m_cardData
    self.m_cardData = cardData
end

function BaseCardUnitView:getCardData()
    return self.m_cardData
end

-- 更新界面 --
function BaseCardUnitView:updateUI()
    if self.m_lastCardData and self.m_cardData then
        if self.m_lastCardData.cardId == self.m_cardData.cardId then
            return
        end
    end
    self:setCardStar()
    self:setCardName()
    self:setCardIcon()
    self:updateSpecialUI()
end

-- 点击事件 --
function BaseCardUnitView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()
end

-- 关闭事件 --
function BaseCardUnitView:closeUI()
    if self.isClose then
        return
    end
    self.isClose = true

    self:removeFromParent()
end

function BaseCardUnitView:onEnter()
end

function BaseCardUnitView:onExit()
end

-- 流程 end ---------------------------------------------------------

-- 判断是否获得此卡
function BaseCardUnitView:isHaveCard()
    if self.m_cardData and self.m_cardData.count then
        return self.m_cardData.count > 0
    end
    return false
end
--是否是拼图卡
function BaseCardUnitView:isPuzzleCard()
    if self.m_cardData.type == CardSysConfigs.CardType.puzzle then
        return true
    end
    return false
end
-- 判断link卡的可玩次数 --
function BaseCardUnitView:isHaveLinkCount()
    if self.m_cardData.type == CardSysConfigs.CardType.link and self.m_cardData.linkCount > 0 then
        return true
    end
    return false
end

-- 控件刷新 start ----------------------------------------------------
-- 卡牌星级 --
function BaseCardUnitView:getStarNode()
    return self:findChild("Node_star")
end
function BaseCardUnitView:createCardStarIcon(starNum)
    local isHaveCard = self:isHaveCard()
    local iconName
    if isHaveCard then
        iconName = CardResConfig.CardUnitStarRes[2][starNum]
    else
        iconName = CardResConfig.CardUnitStarRes[1][1]
    end
    local sprite = util_createSprite(CardResConfig.CardUnitOtherResPath .. iconName)
    if not sprite then
        print("!!! ---------- CardResConfig.CardUnitResPath, iconName, isHaveCard", CardResConfig.CardUnitResPath, iconName, isHaveCard)
        return
    end
    sprite:setAnchorPoint(cc.p(0.5, 0.5))
    return sprite
end
function BaseCardUnitView:setCardStar()
    local starNode = self:getStarNode()
    if not starNode then
        return
    end
    local starNum = self.m_cardData.star
    -- 根据奇数偶数分别排版
    local firstPosX = 0
    if starNum % 2 == 0 then
        -- 偶数
        firstPosX = -(CARD_STAR_WIDTH / 2 + CARD_STAR_INTERVAL / 2) * (starNum - 1)
    else
        -- 奇数
        firstPosX = -(CARD_STAR_WIDTH + CARD_STAR_INTERVAL) * (starNum - 1) * 0.5
    end
    starNode:removeAllChildren()
    for i = 1, starNum do
        local sprite = self:createCardStarIcon(starNum)
        sprite:setPositionX(firstPosX + (CARD_STAR_WIDTH + CARD_STAR_INTERVAL) * (i - 1))
        starNode:addChild(sprite)
    end
end

-- 卡牌名称 --
function BaseCardUnitView:getNameNode()
    local nameLabel = self:findChild("Font_title")
    local nameHaveLabel = self:findChild("Font_title_have")

    local unHaveNode = self:findChild("Node_unhave")
    local haveNode = self:findChild("Node_have")
    return nameLabel, nameHaveLabel, unHaveNode, haveNode
end
function BaseCardUnitView:setCardName()
    local nameLabel, nameHaveLabel, unHaveNode, haveNode = self:getNameNode()

    local isHaveCard = self:isHaveCard()
    unHaveNode:setVisible(not isHaveCard)
    haveNode:setVisible(isHaveCard)
    if isHaveCard then
        nameHaveLabel:setString(self.m_cardData.name)
    else
        nameLabel:setString(self.m_cardData.name)
    end
end

-- 卡牌图标 --
function BaseCardUnitView:getCardIconNode()
    return self:findChild("card_icon"), self:findChild("card_icon_2")
end
function BaseCardUnitView:setCardIcon()
    local cardIconNode, cardIconNode2 = self:getCardIconNode()
    self:changeTexture(cardIconNode)
    self:changeTexture(cardIconNode2)
end
function BaseCardUnitView:changeTexture(sprite)
    if not sprite then
        return
    end

    --背景置灰移除
    local node_hui = self:findChild("node_hui")
    if node_hui then
        node_hui:removeAllChildren()
    end

    if self.m_useClanIcon then
        local isHaveCard = self:isHaveCard()
        if isHaveCard then
            if self:isHaveLinkCount() then
                util_changeTexture(sprite, CardResConfig.getLinkCardIcon())
            else
                util_changeTexture(sprite, CardResConfig.getCardIcon(self.m_cardData.cardId))
            end
        else
            if self.m_cardData.type == CardSysConfigs.CardType.link then
                util_changeTexture(sprite, CardResConfig.getLinkCardIcon())
            else
                local isLoad = util_changeTexture(sprite, CardResConfig.getCardClanIcon(self.m_cardData.clanId, false))

                -- 每个赛季的图片出的尺寸不一样，在这里调整一下
                if self.m_cardData.albumId == "201901" then
                    sprite:setScale(1)
                elseif self.m_cardData.albumId == "201902" then
                    --只有加成成功才缩放
                    if isLoad then
                        sprite:setScale(1.5)
                    end
                end
            end
            --卡片置灰
            util_setSpriteGray(sprite)
            if node_hui then
                local bg_hui = util_createSprite(CardResConfig.CardHuiBg)
                if bg_hui then
                    node_hui:addChild(bg_hui)
                    --背景置灰
                    util_setSpriteGray(bg_hui)
                end
            end
        end
    else
        util_changeTexture(sprite, CardResConfig.getCardIcon(self.m_cardData.cardId))
    end
    --拼图卡
    if self:isPuzzleCard() then
        sprite:setScale(0.85)
    end
end

-- 子类重写去做自己的界面UI --
function BaseCardUnitView:updateSpecialUI()
end

-- 控件刷新 end ------------------------------------------------------

function BaseCardUnitView:createFullScreenTouchLayer(name)
    local touch = ccui.Layout:create()
    touch:setName(name)
    touch:setTag(10)
    touch:setTouchEnabled(true)
    touch:setSwallowTouches(false)
    touch:setAnchorPoint(cc.p(0.5000, 0.5000))
    touch:setContentSize(cc.size(display.width, display.height))
    touch:setPosition(cc.p(0, 0))
    touch:setClippingEnabled(false)
    touch:setBackGroundColorType(ccui.LayoutBackGroundColorType.solid)
    touch:setBackGroundColor(cc.c4b(255, 255, 255))
    touch:setBackGroundColorOpacity(0)
    return touch
end

return BaseCardUnitView
