---
--xcyy
--2018年5月23日
--PenguinsBoomsChooseItem.lua

local PenguinsBoomsChooseItem = class("PenguinsBoomsChooseItem",util_require("Levels.BaseLevelDialog"))

PenguinsBoomsChooseItem.MaxBombCount = 5

function PenguinsBoomsChooseItem:initUI(params)
    self.m_parentView = params.parent
    self.m_index = params.index
    self:createCsbNode("PenguinsBooms_base_bet_choose.csb")

    self.m_qipanCsb = util_createAnimation("PenguinsBooms_base_bet_xiaoqipan.csb")
    self:findChild("Node_xiaoqipan"):addChild(self.m_qipanCsb)


    self:findChild("Node_1"):setVisible(self.m_index < 3)
    self:findChild("Node_2"):setVisible(self.m_index >= 3)

    local specialBets = globalData.slotRunData.machineData.p_betsData.p_specialBets
    local betData
    if self.m_index == 1 then
        local betId = specialBets[1].p_betId
        betData = globalData.slotRunData:getBetDataByIdx(betId, -1)
    else
        local betId = specialBets[self.m_index - 1].p_betId
        betData = globalData.slotRunData:getBetDataByIdx(betId, 0)
    end

    if betData then
        local coins = betData.p_totalBetValue
        self:findChild("m_lb_coins"):setString(util_formatCoins(coins,3))
    end
    
    --炸弹数量
    for _labIndex=1,2 do
        local labCount = self:findChild(string.format("m_lb_num_%d", _labIndex)) 
        labCount:setString(string.format("%d", self.m_index-1))
    end

    --创建点击区域
    local layout = ccui.Layout:create() 
    self:addChild(layout)    
    layout:setAnchorPoint(0.5,0.5)
    local size = self:findChild("di"):getContentSize()
    layout:setContentSize(size)
    layout:setTouchEnabled(true)
    self:addClick(layout)

    self:startBombUpdate()
end

--默认按钮监听回调
function PenguinsBoomsChooseItem:clickFunc(sender)
    self.m_parentView:chooseBet(self.m_index)

end

--[[
    炸弹的计时器
]]
function PenguinsBoomsChooseItem:startBombUpdate()
    self:stopBombUpdate()
    
    self:bombUpdate()
    local nodeBomb = self.m_qipanCsb:findChild("Node_bomb")
    self.m_bombUpDate = schedule(nodeBomb,function()
        self:bombUpdate()
    end, 2)
end
function PenguinsBoomsChooseItem:bombUpdate()
    local showCount = self.m_index - 1
    --加入所有
    local showSpriteList = {}
    for i=1,self.MaxBombCount do
        local spBomb = self.m_qipanCsb:findChild(string.format("bomb%d", i))
        spBomb:setVisible(false)
        table.insert(showSpriteList, spBomb)
    end
    --随机排除
    while #showSpriteList > 0 and #showSpriteList > showCount do
        table.remove(showSpriteList, math.random(1, #showSpriteList))
    end
    --展示
    for i,_spBomb in ipairs(showSpriteList) do
        _spBomb:setVisible(true)
    end
end
function PenguinsBoomsChooseItem:stopBombUpdate()
    if nil ~= self.m_bombUpDate then
        self.m_bombUpDate = nil
        local nodeBomb = self.m_qipanCsb:findChild("Node_bomb")
        nodeBomb:stopAllActions()
    end
end
--[[
    时间线
]]
function PenguinsBoomsChooseItem:playIdleAnim()
    self:runCsbAction("idle1", true)
end
function PenguinsBoomsChooseItem:playCurSelectIdleAnim()
    self:runCsbAction("idle3", true)
end
function PenguinsBoomsChooseItem:playClickAnim()
    self:runCsbAction("actionframe", false, function()
        self:runCsbAction("idle2", true)
    end)
end
function PenguinsBoomsChooseItem:playDarkAnim()
    self:runCsbAction("dark", false, function()
        self:runCsbAction("dark_idle", true)
    end)
end

return PenguinsBoomsChooseItem