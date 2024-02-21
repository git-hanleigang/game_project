--JungleKingpinBonusReelView.lua

local JungleKingpinBonusReelView = class("JungleKingpinBonusReelView", util_require("base.BaseView"))
--banana droppin' feature 玩法中的奖励类型
local BONUS_TYPE = {
    BONUS_NORMAL_TYPE = 1, --金币奖励
    BONUS_MINI_TYPE = 2,
    --香蕉最小奖励
    BONUS_MAX_TYPE = 3, --香蕉最大奖励
    BONUS_MINOR_TYPE = 4, --minor
    BONUS_MAJOR_TYPE = 5,
    --major
    BONUS_GRAND_TYPE = 6 --grand
}

function JungleKingpinBonusReelView:initUI(machine)
    self.m_machine = machine
    self.m_bUpdataWin = false
    self.m_updataTime = 0.04
    self:createCsbNode("JungleKingpin_BonusReel.csb")
end

--初始轮盘
function JungleKingpinBonusReelView:initBonus()
    --类型 固定 tag值也是固定的
    local BananaNode = {
        {tag = 0, _type = BONUS_TYPE.BONUS_GRAND_TYPE},
        {tag = 2, _type = BONUS_TYPE.BONUS_MAJOR_TYPE},
        {tag = 4, _type = BONUS_TYPE.BONUS_MINOR_TYPE},
        {tag = 6, _type = BONUS_TYPE.BONUS_MAX_TYPE},
        {tag = 8, _type = BONUS_TYPE.BONUS_MINI_TYPE}
    }
    self.m_bananaSymbol = {}
    for i = 1, 5 do
        local name = "Node_banana" .. i
        local banana = util_createView("CodeJungleKingpinSrc.JungleKingpinBanana", BananaNode[i]._type)
        banana:showBananaType()
        local pos = cc.p(self:findChild(name):getPosition())
        self:addChild(banana)
        banana:setTag(BananaNode[i].tag)
        banana:setPosition(pos)
        self.m_bananaSymbol[i] = banana
    end
    local CoinsNode = {
        {tag = 1, _type = BONUS_TYPE.BONUS_NORMAL_TYPE},
        {tag = 3, _type = BONUS_TYPE.BONUS_NORMAL_TYPE},
        {tag = 5, _type = BONUS_TYPE.BONUS_NORMAL_TYPE},
        {tag = 7, _type = BONUS_TYPE.BONUS_NORMAL_TYPE},
        {tag = 9, _type = BONUS_TYPE.BONUS_NORMAL_TYPE}
    }
    self.m_coinsSymbol = {}
    for i = 1, 5 do
        local name = "Node_coins" .. i
        local coins = util_createView("CodeJungleKingpinSrc.JungleKingpinCoins")
        local pos = cc.p(self:findChild(name):getPosition())
        self:addChild(coins)
        coins:setTag(CoinsNode[i].tag)
        coins:setPosition(pos)
        self.m_coinsSymbol[i] = coins
    end
end

--断线重连初始
function JungleKingpinBonusReelView:InitReconnetMap(_map)
    --原始数据
    local reelNode = {
        {tag = 0, _type = BONUS_TYPE.BONUS_GRAND_TYPE},
        {tag = 2, _type = BONUS_TYPE.BONUS_MAJOR_TYPE},
        {tag = 4, _type = BONUS_TYPE.BONUS_MINOR_TYPE},
        {tag = 6, _type = BONUS_TYPE.BONUS_MAX_TYPE},
        {tag = 8, _type = BONUS_TYPE.BONUS_MINI_TYPE},
        {tag = 1, _type = BONUS_TYPE.BONUS_NORMAL_TYPE},
        {tag = 3, _type = BONUS_TYPE.BONUS_NORMAL_TYPE},
        {tag = 5, _type = BONUS_TYPE.BONUS_NORMAL_TYPE},
        {tag = 7, _type = BONUS_TYPE.BONUS_NORMAL_TYPE},
        {tag = 9, _type = BONUS_TYPE.BONUS_NORMAL_TYPE}
    }
    --断线重连 判断是否还在
    local function isHaveInMap(tag)
        for i, v in ipairs(_map) do
            if v.id == tag then
                return true
            end
        end
        return false
    end

    --获取ID 对应 原始类型
    local function getReelNodeTypeByID(_id)
        for i, v in ipairs(reelNode) do
            if v.tag == _id then
                return v._type
            end
        end
    end

    --如若不在了 则上边的集体下移
    local function setReelNodePos(_id, _height)
        for i = 1, _id do
            local node = self:getChildByTag(i - 1)
            if node then
                local pos = cc.p(node:getPosition())
                node:setPosition(cc.p(pos.x, pos.y - _height))
            end
        end
    end

    --删除 不在map内的节点
    for i = 1, 10 do
        local tag = i - 1
        if isHaveInMap(tag) == false then
            local _type = getReelNodeTypeByID(tag)
            local height = self:getMoveHeightByType(_type)
            setReelNodePos(tag, height)
            local node = self:getChildByTag(tag)
            if node then
                node:removeFromParent()
            end
        end
    end
end

function JungleKingpinBonusReelView:playBonusBuling()
    local tag = xcyy.SlotsUtil:getArc4Random() % 5
    local banana = self:getChildByTag(tag * 2)
    local coin = self:getChildByTag(tag * 2 + 1)
    if banana then
        banana:runCsbAction("Banana")
    end
    if coin then
        coin:runCsbAction("jinbi")
    end
end

function JungleKingpinBonusReelView:onEnter()
    schedule(
        self,
        function()
            self:updateBonusNum()
        end,
       0.04
    )

end

function JungleKingpinBonusReelView:onExit()
end

function JungleKingpinBonusReelView:updateBonusNum()
    if not self.m_machine then
        return
    end
    for i, v in ipairs(self.m_bananaSymbol) do
        if v._type == 2 then
            v:changeBonusNum(self:getBonusMinNum())
        elseif v._type == 3 then
            v:changeBonusNum(self:getBonusMaxNum())
        end
    end
end

function JungleKingpinBonusReelView:setCurrBet(_currBet)
    if not _currBet or  _currBet == 0 then
        self.m_currBet = nil
    else
        self.m_currBet = _currBet
    end
end

function JungleKingpinBonusReelView:getBonusMaxNum()
    local totalBet = self.m_currBet or globalData.slotRunData:getCurTotalBet()
    local bonus_max = totalBet / 150 * 2000
    return bonus_max
end

function JungleKingpinBonusReelView:getBonusMinNum()
    local totalBet = self.m_currBet or globalData.slotRunData:getCurTotalBet()
    local bonus_min = totalBet / 150 * 1000
    return bonus_min
end

--轮盘向下移动
function JungleKingpinBonusReelView:bonusReelMoveDown(_id, _type)
    local height = self:getMoveHeightByType(_type)
    for i = 1, _id do
        local node = self:getChildByTag(i - 1)
        if node then
            local pos = cc.p(node:getPosition())
            local endPos = cc.p(pos.x, pos.y - height)
            local moveTo = cc.MoveTo:create(0.2, endPos)
            local fun =
                cc.CallFunc:create(
                function()
                end
            )
            node:runAction(cc.Sequence:create(moveTo, fun))
        end
    end
end

--获取要移动的距离
function JungleKingpinBonusReelView:getMoveHeightByType(_type)
    local height = 0
    if _type == BONUS_TYPE.BONUS_NORMAL_TYPE then
        height = 43
    else
        height = 64
    end
    return height
end

--获取要移动的距离
function JungleKingpinBonusReelView:removeReelNodeByID(_id)
    local node = self:getChildByTag(_id)
    if node then
        node:removeFromParent()
    end
end
--获取要移动的距离
function JungleKingpinBonusReelView:setReelNodeVisibleByID(_id)
    local node = self:getChildByTag(_id)
    if node then
        node:setVisible(false)
    end
end

function JungleKingpinBonusReelView:getMoveStartPos(_id)
    local node = self:getChildByTag(_id)
    local pos = cc.p(0, 0)
    if node then
        pos = node:getParent():convertToWorldSpace(cc.p(node:getPosition()))
    end
    return pos
end

function JungleKingpinBonusReelView:resetReelMap()
    for i = 1, 10 do
        local node = self:getChildByTag(i - 1)
        if node then
            node:removeFromParent()
        end
    end
    self:initBonus()
end

function JungleKingpinBonusReelView:setWinSymbol(_endIndex,_type,_func)
    
    self.m_updataSymbol = {}
    self.m_func = _func
    self.m_bUpdataWin = true
    self.m_iWinTag = _endIndex
    self.m_iWinType = _type
    self.m_iLoopNum = 1
    self.m_iStartNum = 1
    self.m_bAdd = true
    for i = 1, 10 do
        local node = self:getChildByTag(i - 1)
        if node then
            self.m_updataSymbol[#self.m_updataSymbol + 1] = node
        end
    end
    local num = 0
    local HaveNum = #self.m_updataSymbol
    for i=1,#self.m_updataSymbol do
      if   self.m_updataSymbol[i]:getTag() == _endIndex then
        num = num + 1
        break
      end
    end
    self.m_needMoveNum = HaveNum*2+num
    self.m_moveNum = 0
    self:beginUpdate( )
end

function JungleKingpinBonusReelView:beginUpdate()

    scheduler.performWithDelayGlobal(
        function()
            if self.m_bUpdataWin then
                self:updateWinSymbol()
            end
        end,
        self.m_updataTime,
       "JungleKingpin"
    )

end

function JungleKingpinBonusReelView:updateWinSymbol()
    self.m_updataSymbol[self.m_iStartNum]:runCsbAction("liang")
    if self.m_iLoopNum > 2 and self.m_updataSymbol[self.m_iStartNum]:getTag() == self.m_iWinTag then
        self.m_bUpdataWin = false
        self.m_updataSymbol[self.m_iStartNum]:runCsbAction("liang",true)
        gLobalSoundManager:playSound("JungleKingpinSounds/sound_JungleKingpin_bonus_paomadeng_over.mp3")
        self.m_updataTime = 0.04
        if  self.m_func then
            self.m_func()
            self.m_func = nil
        end
        return
    end
    if   self.m_needMoveNum - 3 == self.m_moveNum  then
        self.m_updataTime = 0.14
    end
    gLobalSoundManager:playSound("JungleKingpinSounds/sound_JungleKingpin_bonus_paomadeng.mp3")
    if self.m_bAdd then
        self.m_iStartNum = self.m_iStartNum + 1
    else
        self.m_iStartNum = self.m_iStartNum - 1
    end
    if self.m_iStartNum > #self.m_updataSymbol then
        self.m_iStartNum = #self.m_updataSymbol -1
        self.m_iLoopNum = self.m_iLoopNum + 1
        self.m_bAdd = false
    end
    if self.m_iStartNum < 1 then
        self.m_iStartNum = 2
        self.m_iLoopNum = self.m_iLoopNum + 1
        self.m_bAdd = true
    end
    self.m_moveNum = self.m_moveNum + 1
    self:beginUpdate( )
end

return JungleKingpinBonusReelView
