--[[
    集卡系统 卡片卡组掉落界面
]]
local CHIP_WIDTH = 376
local CHIP_HEIGHT = 376

local CHIP_SCALE_SINGLE = 0.65
local CHIP_SCALE_MUL = 0.43

local SINGLE_WIDTH_OFFSET = CHIP_WIDTH

local MUL_WIDTH_OFFSET = CHIP_WIDTH
local MUL_HEIGHT_OFFSET = 164

local CHIP_MOVE_TIME = 10/30

local BaseCardDropShow = util_require("GameModule.Card.baseViews.BaseCardDropShow")
local CardDropShow = class("CardDropShow", BaseCardDropShow)

function CardDropShow:initData_(baseNode)
    self.m_listView = baseNode
    self.m_linkCards = {}
end

function CardDropShow:getLinkCards()
    return self.m_linkCards
end

-- 创建卡片单元
-- 1行,65%,W176
-- 2行,43%,W122,H164
function CardDropShow:_createCards(cardDatas, chipScale, offsetW, layoutPosY)
    local listSize = self.m_listView:getContentSize()
    local listPos = cc.p(self.m_listView:getPosition())

    local startX = 0 
    local nums = math.floor((#cardDatas)/2)
    if (#cardDatas)%2 == 0 then
        startX = listSize.width*0.5 - (2*nums-1)*(offsetW*0.5)
    else
        startX = listSize.width*0.5 - (2*nums)*(offsetW*0.5)
    end

    for i=1,#cardDatas do
        local cardData = cardDatas[i]
        local cardSprite = util_createView("GameModule.Card.season201903.MiniChipUnit")
        cardSprite:playIdle()
        cardSprite:reloadUI(cardData)
        cardSprite:updateTagNew(cardData.firstDrop == true)
        if globalData.slotRunData.isPortrait == true then
            cardSprite:setScale(chipScale*0.8)
        else
            cardSprite:setScale(chipScale)
        end
        self.m_listView:addChild(cardSprite)
        
        cardSprite:setPosition(cc.p(listPos.x+listSize.width*0.5, listSize.height*0.5))
        
        local finalPos = cc.p(startX + offsetW*(i-1), layoutPosY)
        self.m_flyCards[#self.m_flyCards + 1] = {card = cardSprite, finalPos = finalPos}
        
        if cardData.type == CardSysConfigs.CardType.link then
            self.m_linkCards[#self.m_linkCards+1] = {spObj = cardSprite, cardData = cardData}
        end
    end

end

--显示卡片
function CardDropShow:initCards(flyCardsData,useClanIcon)
    local listSize = self.m_listView:getContentSize()
    local layoutSize = cc.size(listSize.width, listSize.height*0.5)

    self.m_flyCards = {}
    local rowNum = math.ceil((#flyCardsData)/7)
    if rowNum == 1 then -- 1-7
        local colnum = #flyCardsData
        local offsetx = CHIP_SCALE_SINGLE*SINGLE_WIDTH_OFFSET
        if colnum*offsetx > listSize.width then
            offsetx = math.floor(listSize.width/colnum)
        end
        local layoutPosY = listSize.height*0.5
        self:_createCards(flyCardsData, CHIP_SCALE_SINGLE, offsetx, layoutPosY)
    else
        local chipScale = CHIP_SCALE_MUL
        local startY = listSize.height*0.5 - (CHIP_HEIGHT*0.5 + MUL_HEIGHT_OFFSET*0.5)
        local offsetY = CHIP_HEIGHT + MUL_HEIGHT_OFFSET
        if (#flyCardsData)%2 == 0 then
            -- 偶数 上下对半分
            local colnum = (#flyCardsData)/2

            local offsetx = chipScale*MUL_WIDTH_OFFSET
            if colnum*offsetx > listSize.width then
                offsetx = math.floor(listSize.width/colnum)
            end
            local index = 0
            for i=1,2 do
                local listData = {}
                for j=1,colnum do
                    index = index + 1
                    listData[#listData+1] = flyCardsData[index]
                end
                local layoutPosY = 0
                if i == 1 then
                    layoutPosY = listSize.height*0.75
                elseif i == 2 then
                    layoutPosY = listSize.height*0.25
                end
                self:_createCards(listData, chipScale, offsetx, layoutPosY)
            end
        else
            -- 奇数 上比下少一个
            local colnum = math.floor((#flyCardsData)/2) + 1
            
            local chipScale = CHIP_SCALE_MUL
            local offsetx = chipScale*MUL_WIDTH_OFFSET
            if colnum*offsetx > listSize.width then
                offsetx = math.floor(listSize.width/colnum)
            end                            
            local index = 0
            local startNum = colnum - 1
            for i=1,2 do
                local listData = {}
                startNum = startNum + (i-1)
                for j=1,startNum do
                    index = index + 1
                    listData[#listData+1] = flyCardsData[index]
                end
                local layoutPosY = 0
                if i == 1 then
                    layoutPosY = listSize.height*0.75
                elseif i == 2 then
                    layoutPosY = listSize.height*0.25
                end
                self:_createCards(listData, chipScale, offsetx, layoutPosY)
            end
        end
    end
end


function CardDropShow:flyCards()
    if self.m_flyCards and #self.m_flyCards > 0 then
        for i=1,#self.m_flyCards do
            local card = self.m_flyCards[i].card
            local finalPos = self.m_flyCards[i].finalPos
    
            -- local delay = cc.DelayTime:create(1)
            -- local move = cc.MoveTo:create(CHIP_MOVE_TIME, finalPos)
            -- local seq = cc.Sequence:create(delay, move)
            -- card:runAction(seq)
    
            local move = cc.MoveTo:create(CHIP_MOVE_TIME, finalPos)
            card:runAction(move)
        end
    end
    return CHIP_MOVE_TIME
end



return CardDropShow