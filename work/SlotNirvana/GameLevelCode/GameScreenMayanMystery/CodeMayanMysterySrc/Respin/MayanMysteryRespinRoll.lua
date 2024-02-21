---
--xcyy
--2018年5月23日
--MayanMysteryRespinRoll.lua
local MayanMysteryRespinRoll = class("MayanMysteryRespinRoll",util_require("base.BaseView"))
local PublicConfig = require "MayanMysteryPublicConfig"

local MULTIPLE = {2,3,4,5}
local INIT_NUM = 7  --初始化数量
local ROLL_MAX_NUM = 59  --滚动最大个数
local SHOW_NUM = 5 --显示最大个数

local STOP_NUM = ROLL_MAX_NUM - SHOW_NUM

local MAX_ROLL_SPEED = 30
local MIX_ROLL_SPEED = 0.7


local MAX_WIDTH = 900
local ITEM_SZ = 163 --两个小球之前的间距

local emRollSatus = {
    emNone = 0,
    emJiasu = 1,
    emRolling = 2,
    emJianSu = 3,
}

function MayanMysteryRespinRoll:initUI()

    self:createCsbNode("MayanMystery_respin_mulbaoshi.csb")
    self.m_run = util_createAnimation("MayanMystery_Respin_xbei_run.csb"):hide()
    self:addChild(self.m_run)

    self.m_datas = {}

    self.m_items = {}

    self._lastNode = nil

    self._removecount = 0

    self._index = 0

    self._bstop = false

    self._speed = 0

    self._rollTime = 0
    self._addsppedDt = (1 / 30) *  MAX_ROLL_SPEED

    self.m_multipleList = {}

    self.m_curItems = nil

    self._status = emRollSatus.emNone

    self.m_curColMul = 2
    
    self:produceDatas( { col = 4, num = 2} )

    self.m_scheduler = cc.Director:getInstance():getScheduler()
end

function MayanMysteryRespinRoll:initMachine(machine)
    self.m_machine = machine

    self.m_mulPanelNode = util_createAnimation("MayanMystery_respin_mulbaoshi_0.csb")
    local startPos = util_convertToNodeSpace(self:findChild("Node_panel"), self.m_machine.m_respinView)
    util_changeNodeParent(self.m_machine.m_respinView, self.m_mulPanelNode, 300)
    self.m_mulPanelNode:setPosition(startPos)

    self.panel = self.m_mulPanelNode:findChild("Panel_1")

    self:initTrainNode()
end

--[[
  info = {
    col = 1,
    num = 2
  }
]]
function MayanMysteryRespinRoll:produceDatas( info )
    local list = {}
    for i=1,INIT_NUM do
        local index = math.random(4,6)
        list[i] = MULTIPLE[index]
    end
  
    local col = INIT_NUM - info.col - 1
    list[col] = info.num
    self.m_curColMul = info.num
  
    local index = 1
    local begin = ROLL_MAX_NUM - INIT_NUM + 1
    if col == 1 then
        self.m_multipleList[begin-1] = self:getNewNums(info.num)
    else
        list[col-1] = self:getNewNums(info.num)
    end
  
    for i = begin,ROLL_MAX_NUM do
        self.m_multipleList[i] = list[index]
        index = index + 1
    end
  
    self._stopColindex = info.col + 2
end

function MayanMysteryRespinRoll:getNewNums(_num)
    if _num == 2 then
        return math.random(4, 5)
    elseif _num == 3 then
        return 5
    elseif _num == 4 then
        return 2
    elseif _num == 5 then
        return math.random(2, 3)
    end
end
  
function MayanMysteryRespinRoll:initTrainNode()
    for i=0, INIT_NUM-1 do
        local item = GD.util_createView("CodeMayanMysterySrc.Respin.MayanMysteryRespinRollNode")
        local node = self.m_mulPanelNode:findChild("Node_"..i)
        item:setPosition(cc.p(node:getPosition()))
    
        local indx = math.random(1,#MULTIPLE)
    
        item:updateData(MULTIPLE[indx])
        item:setTag(i+1)
    
        self.panel:addChild(item)
    
        table.insert(self.m_items, item)
    end
  
    self._index = SHOW_NUM
  
    self._lastNode = self.m_items[1]
end

--[[
    恢复小球层级
]]
function MayanMysteryRespinRoll:changeRollParent( )
    if self.m_curItems then
        if self.m_curItems.oldParent and self.m_curItems.oldPosx then
            util_changeNodeParent(self.m_curItems.oldParent, self.m_curItems)
            self.m_curItems:setPosition(cc.p(self.m_curItems.oldPosx, self.m_curItems.oldPosy))
        end
    end

    self.m_curItems = nil
end

function MayanMysteryRespinRoll:beginRun()
    self:unscheduleUpdate()
    
    self:changeRollParent()

    self._removecount = 0
    self._bstop = false
    self._index = SHOW_NUM
    self._lastNode = self.m_items[1]
    self._rollTime = 0
    self._speed = 0
    self._status = emRollSatus.emJiasu
    
    self:playSpeedeffect()
    self.m_soundRunId = gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_MayanMystery_respin_roll_run, true)
    
    self:onUpdate( function( dt )
        -- 暂停滚动
        if self.m_machine:checkGameRunPause() then
            return
        end

        self._rollTime = self._rollTime + dt
    
        if self._removecount >= 38 then
            self._status = emRollSatus.emJianSu
        end
    
        self:updateTrain(dt)
        
        if self._bstop then
            self:unscheduleUpdate()
            local time = 0
            local random = math.random(1, 10)
            if random <= 5 then -- 50%概率播放 回弹
                local reelResDis = nil
                if self.m_curColMul >= 4 then
                    reelResDis = ITEM_SZ / 2
                else
                    reelResDis = ITEM_SZ / 3
                end
                time = reelResDis/self._speed/60

                for i=1, INIT_NUM do
                    local node = self.m_mulPanelNode:findChild("Node_"..i-1)
                    local upx = self.m_items[i]:getPositionX() + reelResDis
                    local upy = self.m_items[i]:getPositionY()

                    self.m_items[i]:runAction(cc.Sequence:create(
                        cc.MoveTo:create(time, cc.p(upx, upy)),
                        cc.MoveTo:create(0.15, cc.p(node:getPosition()))
                    ))
                end
            else
                time = 0.3
                for i=1, INIT_NUM do
                    local node = self.m_mulPanelNode:findChild("Node_"..i-1)
                    self.m_items[i]:runAction(cc.Sequence:create(
                        cc.MoveTo:create(0.5, cc.p(node:getPosition()))
                    ))
                end
            end
        
            self:performWithDelay(self,function()
                if self.m_soundRunId then
                    gLobalSoundManager:stopAudio(self.m_soundRunId)
                    self.m_soundRunId = nil
                end

                local item = self.m_items[self._stopColindex]
                item.oldParent = item:getParent()
                item.oldPosx, item.oldPosy = item:getPosition()
                self.m_curItems = item
                if self.m_curColMul >= 4 then
                    util_shakeNode(self.m_machine:findChild("root"), 3, 6, 0.4)
                end

                local startPos = util_convertToNodeSpace(item, self.m_machine.m_effectNode)
                util_changeNodeParent(self.m_machine.m_effectNode, item)
                item:setPosition(startPos)

                gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_MayanMystery_respin_mul_select)
                item:playAction("actionframe",false)
            end,0.15+time)

            self:performWithDelay(self,function()
                if self.m_callbackend then
                    self.m_callbackend()
                end
            end,0.3+time)
            
            self:performWithDelay(self,function()
                local item = self.m_items[self._stopColindex]

                if self.m_callback then
                    self.m_callback( item )
                end
            end,1.5+time)
        end
    end)
end
  
  
function MayanMysteryRespinRoll:updateTrain(dt)
    if self._status == emRollSatus.emJiasu then
        if self._speed < MAX_ROLL_SPEED then
            self._speed = self._speed + self._addsppedDt
            if self._speed > MAX_ROLL_SPEED then
                self._speed = MAX_ROLL_SPEED
            end
        else
            self._status = emRollSatus.emRolling
        end
    elseif self._status == emRollSatus.emJianSu then
        if self._speed > MIX_ROLL_SPEED then
            if self._speed <= 7.7 then
                self._speed = self._speed - 0.027
            else
                self._speed = self._speed - 0.29
            end
        end
    end
  
    local speed = self._speed * self.m_scheduler:getTimeScale()
  
    for i = 1, #self.m_items do
  
        local pitem = self.m_items[i]
        local upx = pitem:getPositionX() + speed
        
        if pitem:getPositionX() >= MAX_WIDTH then
    
            self._removecount = self._removecount + 1
        
            if(self._index <= ROLL_MAX_NUM)then
    
                self._index = self._index + 1
        
                local indx = math.random(1,#MULTIPLE)
                local var = MULTIPLE[indx]
                if(self._index > STOP_NUM-2)then
                    var = self.m_multipleList[self._index] or var
                end
        
                pitem:updateData(var)
                pitem:setPositionX(self._lastNode:getPositionX() - ITEM_SZ)
        
                table.remove(self.m_items, i)
                table.insert(self.m_items, 1, pitem)
                
                self._lastNode = pitem
            end
    
            if(self._removecount == STOP_NUM )then
                self._bstop = true
                self._status = emRollSatus.emNone
            end
        else
            pitem:setPositionX(upx)
        end
    end
end
  
function MayanMysteryRespinRoll:run()
  
    self._removecount = 0
    self._bstop = false
    self._index = SHOW_NUM
    self._lastNode = self.m_items[1]
    self._speed = 120
  
    self:unscheduleUpdate()
    self:onUpdate( function( dt )
        self:updateInfo(dt)
    end)
end
  
function MayanMysteryRespinRoll:updateInfo(dt)
    -- 暂停滚动
    if self.m_machine:checkGameRunPause() then
        return
    end

    local num = #self.m_items
    for i=1, num do
        local speed = 2 * self.m_scheduler:getTimeScale()
        
        local pitem = self.m_items[i]
        local upx = pitem:getPositionX() + speed
        if pitem:startus() == false  and pitem:getPositionX() >= MAX_WIDTH then
            local indx = math.random(1, #MULTIPLE)
            local var = MULTIPLE[indx]
    
            pitem:updateData(var)
            pitem:setPositionX(self._lastNode:getPositionX() - ITEM_SZ)
    
            table.remove(self.m_items, 7)
            table.insert(self.m_items, 1, pitem)
            self._lastNode = pitem
        else
            pitem:setPositionX(upx)
        end
    end
end

function MayanMysteryRespinRoll:stopRoll()
    self:unscheduleUpdate()
    for index = 1, 7 do
        local node = self.m_mulPanelNode:findChild("Node_"..(index-1))
        self.m_items[index]:setPosition(cc.p(node:getPosition()) )
    end
end
  
  
function MayanMysteryRespinRoll:playSpeedeffect()
    self.m_run:show()
    self.m_run:playAction("actionframe",false,function()
        self.m_run:hide()
    end)
end
  
  
function MayanMysteryRespinRoll:playItemXbei()
    local item = self.m_items[self._stopColindex]
    local rollNewNode = self.m_machine.m_respinNodeView:findChild("Node_roll")
    if rollNewNode then
        local startPos = util_convertToNodeSpace(item, self.m_machine.m_respinNodeView:findChild("Node_roll"))
        util_changeNodeParent(rollNewNode, item)
        item:setPosition(startPos)
    end

    item:playAction("xbei",false)
end
  
function MayanMysteryRespinRoll:stopSpeedeffect()
    self.m_run:show()
    self.m_run:stopAllActions()
    self.m_run:runAction(cc.FadeOut:create( 0.2 ))
end
  
function MayanMysteryRespinRoll:setRunEndCallFuncBack( _endBack, _callfuncBack)
    self.m_callbackend = _endBack
    self.m_callback = _callfuncBack
end

function MayanMysteryRespinRoll:performWithDelay(_parent, _fun, _time)
    if _time <= 0 then
        _fun()
        return
    end
    local waitNode = cc.Node:create()
    _parent:addChild(waitNode)
    performWithDelay(waitNode,function()
        _fun()
        waitNode:removeFromParent()
    end, _time)

    return waitNode
end

return MayanMysteryRespinRoll