local ScratchWinnerBaseCard = class("ScratchWinnerBaseCard", util_require("Levels.BaseLevelDialog"))
local ScratchWinnerShopManager = require "CodeScratchWinnerSrc.ScratchWinnerShopManager"
local ScratchWinnerMusicConfig = require "CodeScratchWinnerSrc.ScratchWinnerMusicConfig"

function ScratchWinnerBaseCard:initUI(_csbName)
    self:createCsbNode(_csbName)
    self:initCountBtn()
    self:initTouchEffect()
    local panelBuy = self:findChild("Panel_buy")
    if nil ~= panelBuy then
        self:addClick(panelBuy)
    end
    

    self.m_lockState = true
    self.m_cellData  = nil
    self.m_canClick  = true
    -- 是否可以越界
    self.m_bExceed   = true
end
-- 父节点切换时需要重新添加事件监听
function ScratchWinnerBaseCard:addBaseCardObserver()
    --bet数值切换
    gLobalNoticManager:addObserver(self,function(self,params)
        self:upDateLockState(true)
    end,ViewEventType.NOTIFY_BET_CHANGE)
    --bonus玩法切换
    gLobalNoticManager:addObserver(self,function(self,params)
        if "over" ==  params.state then
            self:upDateLockState(false)
            self:changeAllBtnEnable(true)

            self.m_buyCount = 0
            self:upDateBuyCountLab(self.m_buyCount)
        end
    end,"ScratchWinnerMachine_bonus")
    --准备请求购买数据
    gLobalNoticManager:addObserver(self,function(self,params)
        self:changeAllBtnEnable(false)
        self:checkClearCountLabel(params)
    end,"ScratchWinnerMachine_readySendBuyData")
    --一张卡片弹出了
    gLobalNoticManager:addObserver(self,function(self,params)
        local cardName = params[1]
        if cardName == self.m_cellData.name then
            self:changeBuyCount(-1, false)
        end
    end,"ScratchWinnerMachine_cardExport")
end
function ScratchWinnerBaseCard:removeBaseCardObserver()
    gLobalNoticManager:removeAllObservers(self)
end
--[[
    其他通用控件
]]
-- 数量按钮
function ScratchWinnerBaseCard:initCountBtn()
    self.m_buyCount = 0
    local btnParent = self:findChild("Node_goumai")
    if not btnParent then
        return
    end
    
    self.m_btnCountCsb = util_createAnimation("ScratchWinner_btnCount.csb")
    btnParent:addChild(self.m_btnCountCsb)

    self.m_btnAdd   = self.m_btnCountCsb:findChild("btn_add")
    self.m_btnSub   = self.m_btnCountCsb:findChild("btn_sub")
    self.m_labCount = self.m_btnCountCsb:findChild("m_lb_num")

    self:addClick(self.m_btnAdd)
    self:addClick(self.m_btnSub)
    
    self:upDateBuyCountLab(self.m_buyCount)
end
function ScratchWinnerBaseCard:upDateBuyCountLab(_count)
    if not self.m_labCount then
        return
    end
    self.m_labCount:setString(_count)
    self:updateLabelSize({label=self.m_labCount,sx=1,sy=1}, 77)
end
-- 如果购买列表不包含自身就清空自身数量文本
function ScratchWinnerBaseCard:checkClearCountLabel(_params)
    if nil == self.m_cellData then
        return
    end

    local buyList  = _params[1]
    local cardName = self.m_cellData.name
    for _name,v in pairs(buyList) do
        if _name == cardName then
            return
        end
    end

    self.m_buyCount = 0
    self:upDateBuyCountLab(self.m_buyCount)
end
-- 触摸反馈
function ScratchWinnerBaseCard:initTouchEffect()
    local parent = self:findChild("Node_clickbd")
    if not parent then
        return
    end
    self.m_touchEffectCsb = util_createAnimation("ScratchWinner_entrance_clickbd.csb")
    parent:addChild(self.m_touchEffectCsb)
    self.m_touchEffectCsb:setVisible(false)
end

--[[
    触摸相关
]]
function ScratchWinnerBaseCard:clickStartFunc(sender)
    local name = sender:getName()
    if name == "btn_add" then
        self:startChangeCountUpDate(1)
    elseif "btn_sub" == name then
        self:startChangeCountUpDate(-1)
    end
end
function ScratchWinnerBaseCard:clickMoveFunc(sender)
    local name = sender:getName()
    if name == "btn_add" or "btn_sub" == name then
        local pos  = sender:getTouchMovePosition()
        local nPos = sender:getParent():convertToNodeSpace(pos)
        local rect = sender:getBoundingBox()
        local bTouch = cc.rectContainsPoint(rect, nPos)
        if not bTouch then
            self:stopChangeCountUpDate()
        end
    end
end
function ScratchWinnerBaseCard:clickEndFunc(sender)
    self:stopChangeCountUpDate()
end

function ScratchWinnerBaseCard:clickFunc(sender)
    if not self.m_canClick then
        return
    end
    
    local name = sender:getName()

    if "btn_add" == name then
        gLobalSoundManager:playSound(ScratchWinnerMusicConfig.Sound_Click)
        self:changeBuyCount(1, true)
    elseif "btn_sub" == name then
        gLobalSoundManager:playSound(ScratchWinnerMusicConfig.Sound_Click)
        self:changeBuyCount(-1, true)
    elseif "Panel_buy" == name then
        self:playTouchAnim()
    end
end

function ScratchWinnerBaseCard:playTouchAnim()
    -- 没有spine 或者 触摸时间没结束 直接跳出
    if not self.m_cardSpine or self.m_cardSpine.m_bTouch then
        return
    end
    -- 默认购买1张
    if self.m_buyCount <= 0 then
        -- 数量小于0时 不再跳出而是默认为1
        self.m_buyCount = 1
        self:upDateBuyCountLab(self.m_buyCount)
    end

    local buyList = { [self.m_cellData.name] =  self.m_buyCount }
    local buyState = ScratchWinnerShopManager:getInstance():checkBuyState_coins(buyList) 
    -- 金币不足打开商店
    if not buyState then
        self.m_machine:operaUserOutCoins()
        return
    end

    -- 无法购买 就返回
    local buyState = ScratchWinnerShopManager:getInstance():checkBuyState(buyList, {skipCheckCoins=true}) 
    if not buyState then
        return
    end
    gLobalSoundManager:playSound(ScratchWinnerMusicConfig.Sound_Card_Buy)
    local keyName   = string.format("Sound_SelectCard_%d", math.random(1, 2))
    local soundName =  ScratchWinnerMusicConfig[keyName]
    gLobalSoundManager:playSound(soundName)

    self.m_cardSpine.m_bTouch = true

    if self.m_touchEffectCsb then
        self.m_touchEffectCsb:setVisible(true)
        self.m_touchEffectCsb:runCsbAction("actionframe", false, function()
            self.m_touchEffectCsb:setVisible(false)
        end)
    end
 
    local buyList = { [self.m_cellData.name] =  self.m_buyCount }
    gLobalNoticManager:postNotification("ScratchWinnerMachine_readySendBuyData", {buyList})

    util_spinePlay(self.m_cardSpine, "entrance_actionframe", false)
    performWithDelay(self.m_cardSpine,function()
        self.m_cardSpine.m_bTouch = nil
        util_spinePlay(self.m_cardSpine, "entrance_idle", true)
        self:sendBuyData()
    end, 18/30)
    
end


function ScratchWinnerBaseCard:changeBuyCount(_changeCount, _bNotic)
    local minCount = 0
    local maxCount = 100
    local nextCount = self.m_buyCount + _changeCount

    if self.m_bExceed then
        if minCount-1 == nextCount then
            nextCount = maxCount
        elseif maxCount+1 == nextCount then
            nextCount = minCount
        end
    end
    
    nextCount = math.max(minCount ,nextCount)
    nextCount = math.min(maxCount ,nextCount)

    if self.m_buyCount ~= nextCount then
        self.m_buyCount = nextCount
        self:upDateBuyCountLab(self.m_buyCount)
        if _bNotic then
            gLobalNoticManager:postNotification("ScratchWinnerMachine_changeBuyCount", {})
        end
    end
end
function ScratchWinnerBaseCard:function_name()
    
end

function ScratchWinnerBaseCard:sendBuyData()
    if nil == self.m_cellData then
        return
    end

    local buyList = {
        [self.m_cellData.name] =  self.m_buyCount,
    }
    ScratchWinnerShopManager:getInstance():sendBuyData(buyList)
end
--[[
    长按数量按钮
]]
function ScratchWinnerBaseCard:startChangeCountUpDate(_changeCount)
    self:stopChangeCountUpDate()
    self.m_bExceed = true

    local actTable = {}
    table.insert(actTable, cc.DelayTime:create(0.3))
    table.insert(actTable, cc.CallFunc:create(function()
        local interval = 0.05 --0.1
        self.m_bExceed = false
        schedule(
            self.m_btnCountCsb, 
            function() 
                if self.m_machine:checkGameRunPause() then
                    self.m_btnAdd:setBright(true)
                    self.m_btnSub:setBright(true)
                    self:stopChangeCountUpDate()
                    return
                end
                self:changeBuyCount(_changeCount, true)
            end, 
            interval
        )
    end))
    self.m_btnCountCsb:runAction(cc.Sequence:create(actTable))
end
function ScratchWinnerBaseCard:stopChangeCountUpDate()
    self.m_btnCountCsb:stopAllActions()
end
--[[
    展示和隐藏相关
]]
function ScratchWinnerBaseCard:playShowAnim()
    self:runCsbAction("idle")
    if self.m_btnCountCsb then
        self.m_btnCountCsb:runCsbAction("idle")
    end
end
function ScratchWinnerBaseCard:playHideAnim()
    self:runCsbAction("over")
    if self.m_btnCountCsb then
        self.m_btnCountCsb:runCsbAction("over")
    end
end
--[[
    按钮点击状态
]]
function ScratchWinnerBaseCard:changeAllBtnEnable(_bEnable)
    self.m_canClick = _bEnable

    self.m_btnAdd:setEnabled(_bEnable)
    self.m_btnSub:setEnabled(_bEnable)
end
--[[
    卡片spine
]]
function ScratchWinnerBaseCard:upDateCardSpine()
    if nil ~= self.m_cardSpine then
        return
    end

    if nil == self.m_cellData or nil ~= self.m_cardSpine then
        return
    end

    local spineParent = self:findChild("Node_cardSpine")
    if nil == spineParent then
        return
    end

    local cardConfig = ScratchWinnerShopManager:getInstance():getCardConfig(self.m_cellData.name)
    if "" == cardConfig.cardSpine then
        return
    end

    self.m_cardSpine = util_spineCreate(cardConfig.cardSpine,true,true)
    spineParent:addChild(self.m_cardSpine)

    if "commingSoon" ~= self.m_cellData.name then
        util_spinePlay(self.m_cardSpine, "entrance_idle", true)
    end
end
--[[
    jackpot
]]
function ScratchWinnerBaseCard:upDataCardJackpotValue()
    if nil ~= self.m_upDateJackpot or nil == self.m_cellData then
        return
    end
    local lbCoins = self:findChild("m_lb_coins")
    local jpIndex = self.m_machine:getScratchWinnerJackpotIndex(self.m_cellData.jpIndex)
    if jpIndex <= 0 then
        if nil ~= lbCoins then
            lbCoins:setString("")
        end
        return 
    end
    
    local value   = self.m_machine:BaseMania_updateJackpotScore(jpIndex)
    lbCoins:setString(util_formatCoins(value,20,nil,nil,true))
    self:updateLabelSize({label=lbCoins,sx=1,sy=1}, 273)

    self.m_upDateJackpot = schedule(self, function()
        local value   = self.m_machine:BaseMania_updateJackpotScore(jpIndex)
        lbCoins:setString(util_formatCoins(value,20,nil,nil,true))
        self:updateLabelSize({label=lbCoins,sx=1,sy=1}, 273)
    end, 0.08)
end
--[[
    锁定状态
]]
function ScratchWinnerBaseCard:upDateLockState(_playAnim)
    if nil == self.m_cellData then
        return
    end

    -- 锁定
    local unLockBetIndex = self.m_cellData.unlockBetLevel
    local currBetIndex   = globalData.slotRunData:getCurBetIndex()
    if currBetIndex < unLockBetIndex then
        self:setLockState(true, _playAnim)

        self.m_buyCount = 0
        self:upDateBuyCountLab(self.m_buyCount)
        return
    end
    
    -- 解锁
    self:setLockState(false, _playAnim)
end
function ScratchWinnerBaseCard:setLockState(_lockState, _playAnim)
    if _lockState == self.m_lockState then
        return
    end
    self.m_lockState = _lockState
    local lockNode   = self:findChild("lock")

    if _playAnim then
        lockNode:setVisible(_lockState)--^^^
    else
        lockNode:setVisible(_lockState)
    end
end

--[[
    出卡流程
]]
function ScratchWinnerBaseCard:playExportAnim(_order, _list, _fun, _fun2)
    local cardName  = self.m_cellData.name
    self.m_cardSpine:stopAllActions()
    util_spinePlay(self.m_cardSpine, "switch", false)
    -- 播放大卡的移动
    util_spineEndCallFunc(self.m_cardSpine, "switch", function()
        -- util_spinePlay(self.m_cardSpine, "entrance_idle", true)
        _fun()

        local spineParent = self:findChild("Node_cardSpine")
        local pos = spineParent:getParent():convertToWorldSpace(cc.p(spineParent:getPosition()))
        self.m_machine:playExportAnim(pos, _order, cardName, _fun2)
    end)
end

--[[
    list 调用
]]
function ScratchWinnerBaseCard:initMachine(_machine)
    self.m_machine = _machine
end

-- 设置数据
function ScratchWinnerBaseCard:setCellData(_data)
    --[[
        _data = {
            name           = "",    
            jpIndex        = 0,     
            unlockBetLevel = 0,     
        }
    ]]
    self.m_cellData = _data
end

--刷新ui
function ScratchWinnerBaseCard:updateCellUi()
    if nil == self.m_cellData then
        return
    end

    self:upDataCardJackpotValue()
    self:upDateCardSpine()
end

--尺寸
function ScratchWinnerBaseCard:getCellSize()
    local rootNode = self:findChild("root")
    return rootNode:getContentSize()
end


return ScratchWinnerBaseCard