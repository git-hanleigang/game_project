--[[
    --^^^这快代码目前被放弃了，最后决定不启用的话,上线前记得检查移除 22.05.12
    出卡口 
]]
local ScratchWinnerBonusExport = class("ScratchWinnerBonusExport",util_require("Levels.BaseLevelDialog"))
local ScratchWinnerShopManager = require "CodeScratchWinnerSrc.ScratchWinnerShopManager"

function ScratchWinnerBonusExport:initUI(_machine)
    self:createCsbNode("ScratchWinner_chukakou_all.csb")
    self.m_cardParent = self:findChild("Layout_card")
    self.m_cardParentSize = self.m_cardParent:getContentSize()

    self.m_machine  = _machine
    self.m_cardList = {}
    self.m_bottomCardList = {}
end

--[[
    _dataList = {
        {
            index      = 1,
            name       = "",
            lines      = {},
            reels      = {},
            bingoReels = {},
        }
        
]]
function ScratchWinnerBonusExport:setDataList(_dataList)
    self.m_dataList = _dataList
end

function ScratchWinnerBonusExport:playExportAnim(_animIndex, _fun)
    local cardData = self.m_dataList[_animIndex]
    if not cardData then
        self:playOverAnim(_fun)
        return
    end
    local cardConfig = ScratchWinnerShopManager:getInstance():getCardConfig(cardData.name)
    for k,v in pairs(self.m_cardList) do
        v:setVisible(false)
    end
    local curCard = self:getOneCardView(cardData, self.m_cardList)

    local time = 1
    local viewSize = cardConfig.cardViewExportSize
    curCard:setLocalZOrder(100 + _animIndex)
    curCard:setPosition(self.m_cardParentSize.width/2, self.m_cardParentSize.height+viewSize.height/2)
    local endPos = cc.p(self.m_cardParentSize.width/2, self.m_cardParentSize.height-viewSize.height/2)

    local actList = {}
    local actMove = cc.MoveTo:create(time, endPos)
    local actOrbitCamera = cc.OrbitCamera:create(time, 1, 0, -60, 60, 90, 0)
    local actScale = cc.ScaleTo:create(time, 1)

    curCard:setScale(0.6) 
    curCard:setRotation(3) 
    curCard:setVisible(true) 
    table.insert(actList, cc.Spawn:create(actMove, actOrbitCamera, actScale))
    table.insert(actList, cc.RotateTo:create(0.1, 0))

    table.insert(actList, cc.CallFunc:create(function()
        if nil ~= self.m_dataList[_animIndex+1] then
            self:changeBottomCard(cardData, endPos, _animIndex)
        end
        self:playExportAnim(_animIndex+1, _fun)
    end))

    curCard:runAction(cc.Sequence:create(actList))
end

function ScratchWinnerBonusExport:playStartAnim(_fun)
    self:runCsbAction("start", false, function()
        self:runCsbAction("start2", false, function()
            _fun()
        end)
    end)
end
function ScratchWinnerBonusExport:playOverAnim(_fun)
    self:runCsbAction("over2", false, function()
        self:runCsbAction("over", false, function()
            _fun()
            --隐藏所有卡片
            for k,_card in pairs(self.m_cardList) do
                _card:setVisible(false)
            end
            for k,_card in pairs(self.m_bottomCardList) do
                _card:setVisible(false)
            end
        end)
    end)
end

function ScratchWinnerBonusExport:getOneCardView(_cardData, _pool)
    local cardConfig = ScratchWinnerShopManager:getInstance():getCardConfig(_cardData.name)

    local card = _pool[_cardData.name]
    if not card then
        local codeName   = cardConfig.cardViewCode
        card = util_createView(codeName, cardConfig)
        self.m_cardParent:addChild(card)
        card:initMachine(self.m_machine)
        _pool[_cardData.name] = card
        card:setVisible(false) 
    end
    -- 界面展示
    card:findChild("Sprite_mask"):setVisible(true)
    --一些特殊卡片的特殊展示
    if "bingo" == _cardData.name then
        card:initCardData(_cardData)
        card:upDateBingoLinesList()
    end

    return card
end

--[[
    垫底的卡片
]]
function ScratchWinnerBonusExport:changeBottomCard(_cardData,_endPos,_cardIndex)
    local nextCard = self:getOneCardView(_cardData, self.m_bottomCardList)
    nextCard:setPosition(_endPos)
    nextCard:setVisible(true)
    nextCard:setLocalZOrder(_cardIndex)
end


return ScratchWinnerBonusExport