--[[
    author:{author}
    time:2019-07-08 14:28:18
]]
local BaseCardClanCell = util_require("GameModule.Card.baseViews.BaseCardClanCell")
local CardClanCell = class("CardClanCell", BaseCardClanCell)
CardClanCell.m_showNum = 10

function CardClanCell:getCsbName()
    return string.format(CardResConfig.seasonRes.CardClanCellRes, "season201903")
end

function CardClanCell:getMiniChipLua()
    return "GameModule.Card.season201903.MiniChipUnit"    
end

function CardClanCell:getMovePageFlag()
    return not self.notPlayAnimFlag
end

function CardClanCell:updateCell(index,playAnimFlag)
    BaseCardClanCell.updateCell(self, index)

    self:runCsbAction("idle", true)

    local cards = self.m_clansData.cards
    self.notPlayAnimFlag = self.m_showNum > 0

    for i=1,self.m_showNum do
        local tempNode = self:findChild("Node_card"..i)
        if tempNode then
            tempNode:setVisible(false)
            if cards[i] then
                -- 数据 --
                local cardData = cards[i]
                -- mini卡 --
                self:updateCardInfo(tempNode,playAnimFlag, i, cardData,
                function(animIndex)
                    if animIndex == self.m_showNum then
                        self.notPlayAnimFlag = nil
                    end
                end)
            end
        end
    end
end

function CardClanCell:updateCardInfo(nodeCard,playAnimFlag, i, cardData,callBack)
    local tempNode = self:findChild("Node_card"..i)
    local cardNode = tempNode:getChildByName("Node_card")
    local minicard = cardNode:getChildByName("MINICARD") 
    if not minicard then
        minicard = util_createView(self:getMiniChipLua())
        minicard:setName("MINICARD")
        cardNode:addChild(minicard)
        minicard:playAnimByIndex(i,nodeCard,playAnimFlag,callBack)
    else
        nodeCard:setVisible(true)
        if callBack ~= nil then
            callBack(i)
        end
    end
    minicard:reloadUI(cardData)

    minicard:setTouchCallBack(function()
        if not tolua.isnull(self) then
            self:clickMiniCard(i)
        end
    end)
    minicard:updateTagNew(cardData.newCard == true)
    minicard:updateTagNum(cardData.count)
    minicard:updateTouchBtn(true, true, false)
    minicard:updateTagRequest()
end

function CardClanCell:clickMiniCard(_index)
    -- 新手期新增章节和卡牌新手引导：移除章节引导
    local noviceClanView = gLobalViewManager:getViewByName("CardClanView" .. "season302301")
    if noviceClanView then
        noviceClanView:removeGuideMask()
    end
end

-- 只有新手期集卡有引导
function CardClanCell:getGuideNode()
    -- 取最大的没有获得的卡牌
    local guideIndex = 10
    local cardDatas = self.m_clansData.cards
    if cardDatas and #cardDatas > 0 then
        for i=1,#cardDatas do
            local cardData = cardDatas[i]
            if cardData and cardData:getCount() == 0 then
                guideIndex = i
            end
        end
    end
    local tempNode = self:findChild("Node_card"..guideIndex)
    if tempNode then
        return tempNode:getChildByName("Node_card"), guideIndex
    end
end

return CardClanCell
