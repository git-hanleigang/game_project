--[[
    author:{author}
    time:2019-07-08 14:28:18
]]
local BaseView = util_require("base.BaseView")
local CardClanCell = class(CardClanCell, BaseView)
CardClanCell.m_showNum = 10
-- 初始化UI --
function CardClanCell:initUI()
    self:createCsbNode(CardResConfig.CardClanViewCardNodes)
end

function CardClanCell:getClanData()
    local clansData = CardSysRuntimeMgr:getAlbumTalbeviewData()
    return clansData and clansData[self.m_index]
end

function CardClanCell:updateCell(index)
    self.m_index = index
    self.m_clansData = self:getClanData()
    if not self.m_clansData then
        -- 如果出现这种情况即为不合理情况，查看服务器数据
        -- release_print("!!! self.m_index --- ".. self.m_index)
        return
    end
    local cards = self.m_clansData.cards
    for i=1,self.m_showNum do
        local tempNode = self:findChild("Node_card"..i)
        if tempNode then
            if cards[i] then
                tempNode:setVisible(true)
                -- 数据 --
                local cardData = cards[i]
                -- mini卡 --
                local cardNode = tempNode:getChildByName("Node_card")
                local view = util_createView("GameModule.Card.views.MiniCardUnitView", cardData, nil, "idle", nil, true, true, nil, true)
                view:setName("miniCard")
                cardNode:addChild(view)
                -- 注册touch --
                local touch = tempNode:getChildByName("touch")
                if touch then
                    touch:setName("touch_"..i)
                    touch:setSwallowTouches(false)
                    self:addClick(touch)
                end
                -- new、+99 --
                local pointNode = tempNode:getChildByName("point")
                local numberNode = pointNode:getChildByName("word")
                -- local posX , posY = numberNode:getPosition()
                
                if cardData.newCard == true then
                    pointNode:setVisible(true)
                    numberNode:setString("NEW")
                    numberNode:setScale(1)
                    numberNode:setPositionX(30)
                else
                    if cardData.count > 1 then
                        pointNode:setVisible(true)
                        numberNode:setString("+"..(cardData.count-1))
                        numberNode:setScale(1)
                        numberNode:setScale(1.2)
                        numberNode:setPositionX(28)
                    else
                        pointNode:setVisible(false)
                    end
                end
                -- link标记 --
                local linkNode = tempNode:getChildByName("link")
                linkNode:setVisible(cardData.linkCount > 0)
                -- link tip --
                self:showLinkTip(tempNode, cardData.linkCount)
                --link卡 abtest
                -- if linkNode then
                --     util_changeTexture(linkNode,CardResConfig.getLinkCardTarget())
                -- end
            else
                tempNode:setVisible(false)
            end
        end
    end
end

function CardClanCell:showLinkTip(tempNode, linkCount)
    local linkTipView = tempNode:getChildByName("linkTip")
    if linkCount > 0 then
        if not linkTipView then
            linkTipView = util_createView("GameModule.Card.season201901.CardClanCellLinkTip")
            linkTipView:setName("linkTip")
            tempNode:addChild(linkTipView)
            linkTipView:setPosition(cc.p(110,0))
        end
        linkTipView:setVisible(true)
    else
        local linkTipView = tempNode:getChildByName("linkTip")
        if linkTipView then
            linkTipView:setVisible(false)
        end
    end    
end

function CardClanCell:canClick()
    -- local cardData = CardSysRuntimeMgr:getLinkGameCardData(self.m_index)
    -- if cardData then
    --     -- 有link卡小游戏界面会弹出
    --     return false
    -- end  
    return true
end

function CardClanCell:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

    if not self:canClick() then
        return
    end

    for i=1,self.m_showNum do
        local _name = "touch_"..i
        if name == _name then
            -- 显示大卡界面 --
            gLobalSoundManager:playSound(CardResConfig.CARD_MUSIC.BtnClick)
            -- 如果是link卡点击，要判断是否有link游戏次数
            -- 如果有link游戏次数有直接打开link小游戏进入界面
            -- 
            if self.m_clansData then
                local cardData = self.m_clansData.cards[i]
                if cardData.type == "LINK" and cardData.linkCount ~= 0 then
                    -- CardSysManager:showAce
                    CardSysManager:showLinkCardView(cardData)
                else
                    CardSysManager:showBigCardView(self.m_index, i)
                end
            end
        end
    end
end

return CardClanCell