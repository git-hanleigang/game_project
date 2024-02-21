--bet选择弹板
local PenguinsBoomsChooseBetView = class("PenguinsBoomsChooseBetView",util_require("Levels.BaseLevelDialog"))
local PublicConfig = require "PenguinsBoomsPublicConfig"
--[[
    params = {
        machine  = machine,
        fnOver   = function,
        bAuto    = false,
        betLevel = 1,
    }
]]
PenguinsBoomsChooseBetView.ItemOrder = {
    Normal = 50,
    Select = 100,
}
function PenguinsBoomsChooseBetView:initUI(params)
    self.m_machine  = params.machine
    self.m_betLevel = params.betLevel
    self.m_fnOver   = params.fnOver
    self.m_bAuto    = true == params.bAuto

    self.m_isClicked = true

    self:createCsbNode("PenguinsBooms_base_bet_tb.csb")

    self.m_items = {}
    local itemParent = self:findChild("Node_choose")
    for index = 1,4 do
        local item = util_createView("CodePenguinsBoomsSrc.PenguinsBoomsChooseItem",{parent = self,index = index})
        self.m_items[index] = item
        local posNode = self:findChild(string.format("Node_choose%d", index))
        posNode:addChild(item)
        posNode:setLocalZOrder(self.ItemOrder.Normal)
    end

    self:playStartAnim()
end

--[[
    选择bet
]]
function PenguinsBoomsChooseBetView:chooseBet(_selectIndex)
    if self.m_isClicked then
        return
    end
    gLobalSoundManager:playSound(PublicConfig.sound_PenguinsBooms_betView_select)

    self.m_isClicked = true
    self:stopAllActions()
    local betLevel = _selectIndex - 1
    self.m_machine:changeBetByLevel(betLevel)
    -- 一个触发其余压暗
    self:playItemSelectAnim(_selectIndex)

    performWithDelay(self,function()
        self:playOverAnim()
    end, 30/60 + 0.5)
end

function PenguinsBoomsChooseBetView:clickFunc(betLevel)
    if self.m_isClicked then
        return
    end

    self.m_isClicked = true
    self:stopAllActions()
    self:playOverAnim()
end

--[[
    弹板时间线
]]
function PenguinsBoomsChooseBetView:playStartAnim()
    gLobalSoundManager:playSound(PublicConfig.sound_PenguinsBooms_betView_start)

    self:runCsbAction("start", false, function()
        self.m_isClicked = false
        self:playIdleAnim()
    end)
end
function PenguinsBoomsChooseBetView:playIdleAnim()
    local animName = "idle"
    self:runCsbAction(animName, true)

    if self.m_bAuto then
        local animTime = util_csbGetAnimTimes(self.m_csbAct, animName)
        animTime = 5
        performWithDelay(self,function()
            self.m_isClicked = true
            gLobalSoundManager:playSound(PublicConfig.sound_PenguinsBooms_betView_select)
            self:playItemSelectAnim(self.m_betLevel+1)

            performWithDelay(self,function()
                self:playOverAnim()
            end, 30/60 + 0.5)
        end, animTime)
    end

    self:playItemIdle()
end
function PenguinsBoomsChooseBetView:playItemSelectAnim(_selectIndex)
    -- 一个触发其余压暗
    for _itemIndex,_item in ipairs(self.m_items) do
        if _selectIndex == _itemIndex then
            _item:getParent():setLocalZOrder(self.ItemOrder.Select)
            _item:playClickAnim()
        else
            _item:getParent():setLocalZOrder(self.ItemOrder.Normal)
            _item:playDarkAnim()
        end
    end
end
function PenguinsBoomsChooseBetView:playItemIdle()
    for _itemIndex,_item in ipairs(self.m_items) do
        if _itemIndex - 1 == self.m_betLevel then
            _item:playCurSelectIdleAnim()
        else
            _item:playIdleAnim()
        end
    end
end

function PenguinsBoomsChooseBetView:playOverAnim()
    gLobalSoundManager:playSound(PublicConfig.sound_PenguinsBooms_betView_over)
    self:runCsbAction("over",false,function()
        if "function" == type(self.m_fnOver) then
            self.m_fnOver()
        end
        self:removeFromParent()
    end)
    local curBet = globalData.slotRunData:getCurTotalBet()
    self.m_machine:changeTipsByChangeBets(curBet)
end


return PenguinsBoomsChooseBetView