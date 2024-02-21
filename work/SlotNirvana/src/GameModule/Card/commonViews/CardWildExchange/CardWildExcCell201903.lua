local BaseCardWildExcCell = util_require("GameModule.Card.baseViews.BaseCardWildExcCell")
local CardWildExcCell201903 = class("CardWildExcCell201903", BaseCardWildExcCell)

function CardWildExcCell201903:initDatas(_isOneLine)
    self.m_isOneLine = _isOneLine
end

function CardWildExcCell201903:getCsbName()
    local albumId = CardSysRuntimeMgr:getCurAlbumID()
    if tonumber(albumId) >= 202203 then
        if self.m_isOneLine then
            return "CardRes/common" .. albumId .. "/cash_wild_exchange_cell201903_1.csb"
        else
            return "CardRes/common" .. albumId .. "/cash_wild_exchange_cell201903_2.csb"
        end
    else
        return "CardRes/common" .. albumId .. "/cash_wild_exchange_cell201903.csb"
    end
end

function CardWildExcCell201903:getMiniChipLua()
    return "GameModule.Card.season201903.MiniChipUnit"
end

-- 初始化资源及数据 --
function CardWildExcCell201903:loadDataRes(nIndex, tData)
    -- 初始化标题和icon --
    self.m_ClanIcon = self:findChild("logo")
    self.m_ClanName = self:findChild("font_biaoti")

    local icon = CardResConfig.getCardClanIcon(tData.clanId)
    util_changeTexture(self.m_ClanIcon, icon)

    self.m_ClanName:setString(tData.name)

    -- self.m_clickCallBack = callBack
    self.m_myIndex = nIndex

    self.m_ClanData = tData

    -- 初始化1张卡片 --
    self.m_cardsNodeList = {}
    for i = 1, 10 do
        local panel = self:findChild("Panel_" .. i)
        if panel then
            self.m_cardsNodeList[i] = panel
            self.m_cardsNodeList[i]:setTag(i)
            self.m_cardsNodeList[i]:setSwallowTouches(false)
            -- 隐藏选择层 --
            self:cancelCardSeledByIndex(i)
            -- 隐藏遮罩层 --
            local mask = self.m_cardsNodeList[i]:getChildByName("mask")
            if mask then
                mask:setVisible(false)
            end

            if tData.cards[i] ~= nil then
                self:addNodeClicked(self.m_cardsNodeList[i])
                -- 初始化卡牌 --
                local cardNode = self:findChild("Node_" .. i)
                local miniChip = util_createView(self:getMiniChipLua())
                miniChip:playIdle()
                miniChip:reloadUI(tData.cards[i], true)
                cardNode:addChild(miniChip)

                -- 如果卡片未获得 则增加蒙版 --
                if tData.cards[i].count == 0 then
                    -- 如果需要遮罩 才显示 --
                    if CardSysManager:getWildExcMgr():getShowAll() == true then
                        -- util_changeTexture(mask, string.format(CardResConfig.otherRes.CardMarkRes, tData.cards[i].star))
                        -- mask:setVisible(true)
                        miniChip:setCardGrey(true, cc.c3b(66, 66, 66))
                    end
                end

                -- 判断某卡是否被选中 --
                if tonumber(tData.cards[i].cardId) == tonumber(CardSysManager:getWildExcMgr():getSelCardId()) then
                    self:markCardSeledByIndex(i)
                end
            end
        end
    end
end

return CardWildExcCell201903
