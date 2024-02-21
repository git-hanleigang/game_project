--[[
    author:{author}
    time:2019-07-08 14:28:18
]]
local CardDropClan = class("CardDropClan", BaseView)

function CardDropClan:getCsbName()
    return "CardsBase201903/CardRes/season201903/DropNew2/clan_cell.csb"
end

function CardDropClan:getTagNewLua()
    return "GameModule.Card.season201903.CardTagNew"    
end

function CardDropClan:initCsbNodes()
    self.m_nodeBase = self:findChild("node_scale")
    -- if globalData.slotRunData.isPortrait == true then
    --     self.m_nodeBase:setScale(1.25)
    -- end

    self.m_spLogo = self:findChild("sp_logo")
    self.m_spLogoDark = self:findChild("sp_logo_dark")
    self.m_procellLb = self:findChild("lb_pro")
    self.m_newNode = self:findChild("Node_new")
    self.m_jindu = self:findChild("jindu")
end

function CardDropClan:getContentSize()
    -- return cc.size(368,386)
    return cc.size(120,120)
end

-- function CardDropClan:playAnim(isPlayStart)
--     if isPlayStart then
--         self:runCsbAction("show", false, function()
--             self:runCsbAction("idle", true)
--         end)
--     else
--         self:runCsbAction("idle", true)
--     end
-- end

function CardDropClan:playFlyto(_over)
    self:runCsbAction("flyto", false, _over, 60)
end

function CardDropClan:getClanId()
    return self.m_cellData.clanId
end

function CardDropClan:updateCell(clanIndex, cellData)
    self.m_clanIndex = clanIndex
    self.m_cellData = cellData
    self:updateLogo()
    self:updatePro(self.m_cellData.cur, self.m_cellData.max)
end

function CardDropClan:playFlyIn(_isSkip)
    self:updateTagNew()
    if not _isSkip then
        self:playFlyto()
        self:increasePro()
    else
        local clanCollect = CardSysRuntimeMgr:getClanCollectByClanId(self.m_cellData.clanId)
        if clanCollect then
            local tarPro = clanCollect.cur
            local tarMax = clanCollect.max        
            self.m_cellData.cur = tarPro
            self.m_cellData.max = tarMax
            self:updatePro(tarPro, tarMax)
        end
    end
end

function CardDropClan:updateLogo()
    local clanId = self.m_cellData.clanId
    -- 卡组logo
    local icon = CardResConfig.getCardClanIcon(clanId)
    util_changeTexture(self.m_spLogo, icon)
    util_changeTexture(self.m_spLogoDark, icon)    
end

function CardDropClan:updatePro(_cur, _max)
    self.m_jindu:setPercent(_cur*100/_max)
    self.m_procellLb:setString(string.format("%d/%d", _cur, _max))  
end

function CardDropClan:increasePro()
    -- 如果一个章节涨多次的话，只需要第一次能执行即可
    if self.m_increasing then
        return
    end
    self.m_increasing = true
    local clanId = self.m_cellData.clanId
    local clanCollect = CardSysRuntimeMgr:getClanCollectByClanId(clanId)
    if clanCollect == nil then
        return
    end
    local curPro = self.m_cellData.cur
    local curMax = self.m_cellData.max
    local tarPro = clanCollect.cur
    local tarMax = clanCollect.max
    print("CardDropClan increasePro clanCollect", curPro, curMax, tarPro, tarMax)
    local curPercent = curPro/curMax*100
    local tarPercent = tarPro/tarMax*100

    if tarPercent > curPercent then
        local nowPercent = curPercent
        local perPercent = math.max(1, (tarPercent - curPercent)/10)

        local function update()
            nowPercent = nowPercent + perPercent
            if nowPercent >= tarPercent then
                self.m_increasing = false
                self.m_cellData.cur = tarPro
                self.m_cellData.max = tarMax
                self.m_jindu:setPercent(tarPercent)
                self.m_procellLb:setString(string.format("%d/%d", tarPro, curMax))
                if self.m_sche then
                    self:stopAction(self.m_sche)
                    self.m_sche = nil
                end
            else
                self.m_jindu:setPercent(nowPercent)
            end
        end
        self.m_sche = util_schedule(self, update, 0.05)
    end
end

function CardDropClan:updateTagNew()
    -- new
    -- local isNew = self:hasNewCardInClan()
    if not self.m_tagNewUI then
        self.m_tagNewUI = util_createView(self:getTagNewLua())
        self.m_tagNewUI:playIdle()
        self.m_newNode:addChild(self.m_tagNewUI)
    end
    -- self.m_tagNewUI:setVisible(isNew)
end

function CardDropClan:onEnter()
    print("CardDropClan:onEnter self.m_clanIndex=", self.m_clanIndex)
    CardDropClan.super.onEnter(self)
end

-- function CardDropClan:clickFunc(sender)
--     local name = sender:getName()
--     if name == "touch" then

--         -- 新手期新增章节和卡牌新手引导：移除章节引导
--         local noviceAlbumView = gLobalViewManager:getViewByName("CardAlbumView" .. "season302301")
--         if noviceAlbumView then
--             noviceAlbumView:removeGuideMask()
--         end

--         gLobalSoundManager:playSound(CardResConfig.CARD_MUSIC.BtnClick)
--         -- TEST 显示卡组选择界面 --
--         self:runCsbAction("animation0", false, function()
--             self:runCsbAction("idle")
--         end)
--         CardSysManager:showCardClanView(self.m_clanIndex, true)
--         self:checkLogNovicePopup()
--     end
-- end

-- function CardDropClan:hasNewCardInClan()
--     if self.m_cellData and self.m_cellData.cards and #self.m_cellData.cards > 0 then
--         for i = 1, #self.m_cellData.cards do
--             local cardData = self.m_cellData.cards[i]
--             if cardData.newCard == true then
--                 return true
--             end
--         end
--     end
--     return false
-- end

-- -- 新手期集卡宣传图 进入集卡 是否 点击了第一个卡册
-- function CardDropClan:checkLogNovicePopup()
--     local bNovice = CardSysManager:isNovice()
--     if not bNovice or self.m_clanIndex ~= 1 then
--         return
--     end

--     local logNovice = gLobalSendDataManager:getLogNovice()
--     if not logNovice then
--         return
--     end
--     local cardPubEnterInfo = logNovice:getNewUserGoCardSysSign()
--     if not cardPubEnterInfo or not cardPubEnterInfo.bPubEnter then
--         return
--     end

--     logNovice:sendPopupLayerLog("Play", "CP", cardPubEnterInfo.entrySite, nil, true)
--     logNovice:resetNewUserGoCardSysSign()
-- end

return CardDropClan