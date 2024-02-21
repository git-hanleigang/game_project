--[[
    author:{author}
    time:2019-07-10 15:55:34
]]
local BaseView = util_require("base.BaseView")
local CardHistoryCell = class("CardHistoryCell", BaseView)
function CardHistoryCell:initUI()
    self:createCsbNode(string.format(CardResConfig.commonRes.CardHistoryViewCellRes, "common" .. CardSysRuntimeMgr:getCurAlbumID()))
    self.m_cardNode = self:findChild("Node_1")
end

function CardHistoryCell:updateUI(historyData)
    -- 初始化卡片 时间 来源等数据 --
    local cardData = historyData.card

    -- 如果是ACE卡，会在图标左上方添加ACE标识；如果是wild卡，会在图标左上方添加wild标识
    local cardWildTag = self:findChild("Sprite_1")
    --cardWildTag:setVisible(false)
    --link卡 abtest
    -- if not self.m_spLinkCard then
    --     local spLink = util_createSprite(CardResConfig.getLinkCardTarget())
    --     cardWildTag:getParent():addChild(spLink)
    --     spLink:setPosition(cardWildTag:getPosition())
    --     spLink:setScale(cardWildTag:getScale())
    --     --隐藏按钮这里应该显示图片
    --     self.m_spLinkCard = spLink
    -- end
    cardWildTag:setVisible(cardData.type == CardSysConfigs.CardType.link)

    -- 邮票图标 + 邮票名称 + 奖励获得路径 + 获得时间（几年几月几日，时：分）
    local nameLB = self:findChild("CardLink_rule_text")
    local strs = string.split(cardData.name, "|")
    local nameStr = table.concat(strs, " ")
    nameLB:setString(nameStr)
    self:updateLabelSize({label = nameLB, sx = 0.8, sy = 0.8}, 295)

    local dropPath = self:findChild("BitmapFontLabel_1")
    dropPath:setString(historyData.dropName)

    local dropTime = self:findChild("BitmapFontLabel_2")
    dropTime:setString(util_formatToSpecial(math.floor(tonumber(historyData.dropTime) / 1000)))

    self:updateCard(cardData)
end

function CardHistoryCell:updateCard(cardData)
    if not cardData then
        return 
    end
    local _albumId = cardData.albumId
    local miniCard = self.m_cardNode:getChildByName("CARD" .. _albumId)

    if not miniCard then
        self.m_cardNode:removeAllChildren()
        -- miniCard = util_createView("GameModule.Card.commonViews.CardHistoryCard")
        if CardSysRuntimeMgr:isObsidianClan(cardData.type) then
            miniCard = util_createView("GameModule.Card.commonViews.CardHistory.CardHistoryCard201903")
        else
            local _logic = CardSysRuntimeMgr:getSeasonLogic(_albumId)
            if _logic then
                miniCard = _logic:createCardHistoryCardIcon()
            end
        end
        if miniCard then
            miniCard:setName("CARD" .. _albumId)
            self.m_cardNode:addChild(miniCard)
            miniCard:updateUI(cardData, CardSysRuntimeMgr:isStatueCard(cardData.type))
        end
    else
        miniCard:updateUI(cardData, CardSysRuntimeMgr:isStatueCard(cardData.type))
    end
    
end

return CardHistoryCell
