local CardDropChipList = class("CardDropChipList", BaseView)

function CardDropChipList:initDatas(_cardDatas)
    self.m_cardDatas = CardSysManager:getDropMgr():resetDropCardData(_cardDatas)
    self.m_colMaxNum = 5 -- zuida

    self.m_rowMaxNum = 2

    self.m_chipSize = cc.size(160, 200)

    self.m_chips = {} -- 所有
    self.m_nadoChips = {} -- 增加nado机次数，向nado机飞粒子
    self.m_firstDropChips = {} -- 飞入章节列表增加进度
    self.m_coinChips = {} -- 转换成金币留在卡牌列表，最后有飞金币
    self.m_storeChips = {} -- 转换成商城积分飞入商店

    -- local totalCardNum = #self.m_cardDatas
    -- self.m_rowNum = math.floor(totalCardNum / self.m_colMaxNum)
    -- if math.fmod(totalCardNum, self.m_colMaxNum) > 0 then
    --     self.m_rowNum = self.m_rowNum + 1
    -- end
end

--移动资源到包内
function CardDropChipList:getCsbName()
    if globalData.slotRunData.isPortrait == true then
        return "CardsBase201903/CardRes/season201903/DropNew2/chip_list_shu.csb"    
    end
    return "CardsBase201903/CardRes/season201903/DropNew2/chip_list.csb"
end

function CardDropChipList:initCsbNodes()
    self.m_panelLayer = self:findChild("Panel_Layer")
    self.m_nodeFlyTickets = self:findChild("node_flyTickets")

    self.m_pSize = self.m_panelLayer:getContentSize()

    self.m_bottomPos = cc.p(self.m_pSize.width/2, 0)
end

function CardDropChipList:initUI()
    CardDropChipList.super.initUI(self)

    -- util_setCascadeColorEnabledRescursion(self, true)
    -- util_setCascadeOpacityEnabledRescursion(self, true)
end

function CardDropChipList:onEnterFinish()
    CardDropChipList.super.onEnterFinish(self)
    self:initChipPosList()
end

-- 居中对齐
-- 分上下两行
function CardDropChipList:initChipPosList()
    self.m_chipPosList = {}
    local showColMax = 5 -- 最多展示列数
    local showRawMax = 2 -- 最多展示行数
    local cardNum = #self.m_cardDatas

    local colMax = math.min(showColMax, cardNum) -- 实际展示列数
    local startX = self.m_pSize.width/2 - self.m_chipSize.width/2*(colMax-1)

    local rawMax = math.min(showRawMax, math.ceil(cardNum/showColMax)) -- 实际展示行数
    local startY = self.m_pSize.height/2 + self.m_chipSize.height/2*(rawMax-1)
    for cardIndex=1,cardNum do
        local yushu = math.fmod(cardIndex, colMax)
        local colIndex = yushu==0 and colMax or yushu
        local posX = startX + self.m_chipSize.width*(colIndex-1)

        local rawIndex = math.ceil(cardIndex/colMax)
        local posY = startY - self.m_chipSize.height*(rawIndex-1)
        table.insert(self.m_chipPosList, {x = posX, y = posY})
    end
end

function CardDropChipList:getChipParentLayer()
    return self.m_panelLayer
end

function CardDropChipList:getChipPosList()
    return self.m_chipPosList
end

function CardDropChipList:getChipBottomPos()
    return self.m_bottomPos
end

function CardDropChipList:addChips(_chipNode)
    if _chipNode == nil then
        return
    end
    table.insert(self.m_chips, _chipNode)

    local cardData = _chipNode:getCardData()
    if cardData and cardData.type == CardSysConfigs.CardType.link then
        table.insert(self.m_nadoChips, _chipNode)
    end
    if cardData and cardData.firstDrop == true then
        table.insert(self.m_firstDropChips, _chipNode)
    elseif (cardData.greenPoint > 0 or cardData.goldPoint > 0) then
        table.insert(self.m_storeChips, _chipNode)
    elseif cardData and cardData.exchangeCoins > 0 then
        table.insert(self.m_coinChips, _chipNode)
    end
end

function CardDropChipList:getChips()
    return self.m_chips
end

function CardDropChipList:getNadoChips()
    return self.m_nadoChips
end

function CardDropChipList:getFirstDropChips()
    return self.m_firstDropChips
end

function CardDropChipList:getCoinChips()
    return self.m_coinChips
end

function CardDropChipList:getStoreChips()
    return self.m_storeChips
end

function CardDropChipList:hideChips()
    if self.m_nadoChips and #self.m_nadoChips > 0 then
        for i=1,#self.m_nadoChips do
            self.m_nadoChips[i]:setVisible(false)
        end
    end
    if self.m_firstDropChips and #self.m_firstDropChips > 0 then
        for i=1,#self.m_firstDropChips do
            self.m_firstDropChips[i]:setVisible(false)
        end
    end
    if self.m_storeChips and #self.m_storeChips > 0 then
        for i=1,#self.m_storeChips do
            self.m_storeChips[i]:setVisible(false)
        end
    end
end

function CardDropChipList:getMoveUpDistance()
    local flyClanLen = #self.m_firstDropChips
    local moveUpRow = math.floor(flyClanLen/self.m_colMaxNum)
    local moveUpDistance = moveUpRow*self.m_chipSize.height
    return moveUpDistance
end

function CardDropChipList:moveUpChipList(_moveTime, _over, _isSkin)
    local upDis = self:getMoveUpDistance()
    if not (upDis and upDis > 0) then
        if _over then
            _over()
        end
        return
    end
    if _isSkin then
        if self.m_coinChips and #self.m_coinChips > 0 then
            for i=1,#self.m_coinChips do
                local pos = cc.p(self.m_coinChips[i]:getPosition())
                self.m_coinChips[i]:setPosition(cc.p(pos.x, pos.y+upDis))
            end
        end        
        if _over then
            _over()
        end
        return
    end
    if self.m_coinChips and #self.m_coinChips > 0 then
        for i=1,#self.m_coinChips do
            self:moveUpTo(_moveTime, self.m_coinChips[i], upDis)
        end
    end
    if self.m_storeChips and #self.m_storeChips > 0 then
        for i=1,#self.m_storeChips do
            self:moveUpTo(_moveTime, self.m_storeChips[i], upDis)
        end
    end
    if _over then
        util_performWithDelay(self, _over, _moveTime)
    end
end

function CardDropChipList:moveUpTo(_moveTime, _moveNode, _upDis, _over)
    local pos = cc.p(_moveNode:getPosition())
    local actionList = {}
    actionList[#actionList + 1] = cc.MoveTo:create(_moveTime, cc.p(pos.x, pos.y+_upDis))
    actionList[#actionList + 1] = cc.CallFunc:create(function()
        if _over then
            _over()
        end
    end)
    _moveNode:runAction(cc.Sequence:create(actionList))
end

function CardDropChipList:playChipListAction(_chipTypes, _actionType)
    local isSuc = false
    if _chipTypes and #_chipTypes > 0 then
        for i=1,#_chipTypes do
            local chipNodes = nil
            if _chipTypes[i] == "firstDrop" then
                chipNodes = self.m_firstDropChips
            elseif _chipTypes[i] == "store" then
                chipNodes = self.m_storeChips
            elseif _chipTypes[i] == "coin" then
                chipNodes = self.m_coinChips
            end
            if chipNodes and #chipNodes > 0 then
                for j=1,#chipNodes do
                    self:playChipAction(chipNodes[j], _actionType)
                end
                isSuc = true
            end
        end
    end
    return isSuc
end

function CardDropChipList:playChipAction(_chipNode, _actionType)
    if _actionType == "switch" then
        _chipNode:playSwitch()
    elseif _actionType == "over" then
        _chipNode:playOver()
    end
end

function CardDropChipList:getMergeParticleFlyNode()
    if self.m_mergeParticle then
        local nodeFly = self.m_mergeParticle:findChild("fly")
        return nodeFly
    end
    return nil
end

function CardDropChipList:playMergeParticleStart(_over)
    if self.m_mergeParticle then
        self.m_mergeParticle:findChild("start_lizi"):resetSystem()
        self.m_mergeParticle:findChild("start_lizi"):setPositionType(0)        
        self.m_mergeParticle:playAction("start", false, _over, 30)
    else
        if _over then
            _over()
        end
    end
end

function CardDropChipList:playMergeParticleFly(_over)
    if self.m_mergeParticle then
        self.m_mergeParticle:findChild("fly_lizi"):resetSystem()
        self.m_mergeParticle:findChild("fly_lizi"):setPositionType(0)
        self.m_mergeParticle:playAction("fly", false, _over, 30)
    else
        if _over then
            _over()
        end
    end
end

function CardDropChipList:playMergeParticleOver(_over, _isSkip)
    if _isSkip then
        if self.m_mergeParticle then 
            self.m_mergeParticle:setVisible(false)
        end
        if _over then
            _over()
        end
        return
    end
    if self.m_mergeParticle then 
        self.m_mergeParticle:findChild("over_lizi"):resetSystem()
        self.m_mergeParticle:findChild("over_lizi"):setPositionType(0)        
        self.m_mergeParticle:playAction("over", false, _over, 30)
    else
        if _over then
            _over()
        end
    end
end

function CardDropChipList:createMergeParticle(_type)
    -- local particle = util_createAnimation("CardsBase201903/CardRes/season201903/DropNew2/chip_particle_" .. _type .. ".csb")
    local particle = util_createAnimation("CardsBase201903/CardRes/season201903/DropNew2/chip_fly_lizi.csb")
    self.m_nodeFlyTickets:addChild(particle)
    particle:findChild("start_lizi"):stopSystem()
    particle:findChild("fly_lizi"):stopSystem()
    particle:findChild("over_lizi"):stopSystem()
    -- particle:setName(_type)
    self.m_mergeParticle = particle
end

function CardDropChipList:getStoreTickets()
    return self.m_ticketNodes
end

function CardDropChipList:showFlyStoreTickets(_normalPoint, _goldenPoint)
    self.m_ticketNodes = {}
    local UIList = {}
    if _normalPoint and _normalPoint > 0 then
        local ticket = self:createStoreTicket("green", _normalPoint)
        ticket:playStart()
        table.insert(self.m_ticketNodes, ticket)
        table.insert(UIList, {node = ticket, scale = 1, anchor = cc.p(0.5, 0.5), size = ticket:getTicketSize()})
    end
    if _goldenPoint and _goldenPoint > 0 then
        local ticket = self:createStoreTicket("golden", _goldenPoint)
        ticket:playStart()
        table.insert(self.m_ticketNodes, ticket)
        table.insert(UIList, {node = ticket, scale = 1, anchor = cc.p(0.5, 0.5), size = ticket:getTicketSize()})
    end
    if #UIList > 0 then
        util_alignCenter(UIList)
    end
    local startTime = 0.5
    return startTime
end

function CardDropChipList:createStoreTicket(_storeType, _point)
    local csbname = "CardsBase201903/CardRes/season201903/DropNew2/store_" .. _storeType .. "_fly.csb"
    local ticket = util_createView("GameModule.Card.commonViews.CardDropV2.CardDropStoreTicket", csbname, _point)
    self.m_nodeFlyTickets:addChild(ticket)
    ticket:setName(_storeType)
    return ticket
end

return CardDropChipList
