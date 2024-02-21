--[[
    集卡系统 卡片卡组掉落界面
]]
local BaseCardDropShow = util_require("GameModule.Card.baseViews.BaseCardDropShow")
local CardDropShow = class("CardDropShow", BaseCardDropShow)

-- 创建卡片单元
function CardDropShow:createCards(cardDatas,layoutSize,isOnly)
    local spanX = 35
    local scale = 0.2384
    local cellWidth = 418*scale
    local startX = (layoutSize.width-cellWidth*6-spanX*5)*0.5+cellWidth*0.5
    local layout=ccui.Layout:create()
    layout:setContentSize(layoutSize)
    local onlyXList = {0,0,0,0,0,0}
    if isOnly then
        --只有一排时候特殊处理
        scale = 0.371
        if #cardDatas == 1 then
            onlyXList[1]=layoutSize.width*0.5
        elseif #cardDatas == 2 then
            local newSpanX = 150
            onlyXList[1]=layoutSize.width*0.5 - newSpanX
            onlyXList[2]=layoutSize.width*0.5 + newSpanX
        elseif #cardDatas == 3 then
            local newSpanX = 250
            onlyXList[1]=layoutSize.width*0.5 - newSpanX
            onlyXList[2]=layoutSize.width*0.5
            onlyXList[3]=layoutSize.width*0.5 + newSpanX
        elseif #cardDatas == 4 then
            local newSpanX = 120
            onlyXList[1]=layoutSize.width*0.5 - newSpanX*3
            onlyXList[2]=layoutSize.width*0.5 - newSpanX
            onlyXList[3]=layoutSize.width*0.5 + newSpanX
            onlyXList[4]=layoutSize.width*0.5 + newSpanX*3
        elseif #cardDatas == 5 then
            local newSpanX = 180
            onlyXList[1]=layoutSize.width*0.5 - newSpanX*2
            onlyXList[2]=layoutSize.width*0.5 - newSpanX
            onlyXList[3]=layoutSize.width*0.5
            onlyXList[4]=layoutSize.width*0.5 + newSpanX
            onlyXList[5]=layoutSize.width*0.5 + newSpanX*2
        elseif #cardDatas == 6 then
            local newSpanX = 85
            onlyXList[1]=layoutSize.width*0.5 - newSpanX*5
            onlyXList[2]=layoutSize.width*0.5 - newSpanX*3
            onlyXList[3]=layoutSize.width*0.5 - newSpanX
            onlyXList[4]=layoutSize.width*0.5 + newSpanX
            onlyXList[5]=layoutSize.width*0.5 + newSpanX*3
            onlyXList[6]=layoutSize.width*0.5 + newSpanX*5
        end
    end
    for i=1,#cardDatas do
        local cardData = cardDatas[i]
        local cardSprite = nil
        if cardData.type == CardSysConfigs.CardType.puzzle then
            -- 拼图卡
            cardSprite = util_createView("GameModule.Card.views.PuzzleCardUnitView", cardData, "show", cardData.firstDrop == true)
        else
            cardSprite = util_createView("GameModule.Card.views.MiniCardUnitView", cardData, nil, "show", true, self.m_useClanIcon, nil, true)
        end             
        layout:addChild(cardSprite)
        cardSprite:setScale(scale)
        --光圈
        if cardData.type == CardSysConfigs.CardType.link then
            if cardSprite.bg then
                local spEff = util_createSprite(CardResConfig.DropLinkEff)
                spEff:setScale(2.73)
                cardSprite.bg:getParent():addChild(spEff,-1)
            end
        elseif cardData.type == CardSysConfigs.CardType.golden then
            if cardSprite.bg then
                local spEff = util_createSprite(CardResConfig.DropGoldEff)
                spEff:setScale(2.73)
                cardSprite.bg:getParent():addChild(spEff,-1)
            end
        end
        if isOnly then
            cardSprite:setPosition(onlyXList[i],layoutSize.height*0.5)
        else
            cardSprite:setPosition(startX+(i-1)*(spanX+cellWidth),layoutSize.height*0.5)
        end
    end
    self.m_listView:pushBackCustomItem(layout)
end

return CardDropShow