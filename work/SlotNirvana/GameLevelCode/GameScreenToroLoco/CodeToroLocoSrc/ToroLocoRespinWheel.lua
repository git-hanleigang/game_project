---
--xcyy
--2018年5月23日
--ToroLocoRespinWheel.lua
local ToroLocoPublicConfig = require "ToroLocoPublicConfig"
local ToroLocoRespinWheel = class("ToroLocoRespinWheel", util_require("base.BaseView"))

local JACKPOT_INDEX = {"Grand", "Major", "Minor", "Mini"}

local INIT_NUM = 5  --初始化数量
local ROLL_MAX_NUM = 54  --滚动最大个数
local SHOW_NUM = 3 --显示最大个数

local STOP_NUM = ROLL_MAX_NUM - SHOW_NUM

local MAX_ROLL_SPEED = 30
local MIX_ROLL_SPEED = 3

local ITEM_SZ = 180 --两个node之前的间距

local emRollSatus = {
    emNone = 0,
    emJiasu = 1,
    emRolling = 2,
    emJianSu = 3,
}

function ToroLocoRespinWheel:initUI()
    self:createCsbNode("WheelToroLoco.csb")

    -- 爆炸
    self.m_wheelTotalWinSpine = util_spineCreate("ToroLoco_totalwin",true,true)
    self:findChild("Node_jiesuo"):addChild(self.m_wheelTotalWinSpine, 1)
    self.m_wheelTotalWinSpine:setVisible(false)

    -- 过场
    self.m_wheelGuoChangSpine = util_spineCreate("ToroLoco_guochang",true,true)
    self:findChild("Node_jiesuo"):addChild(self.m_wheelGuoChangSpine, 2)
    self.m_wheelGuoChangSpine:setVisible(false)

    -- 锁链
    self.m_wheelLockSpine = util_spineCreate("WheelToroLoco_tielian",true,true)
    self:findChild("Node_unlock"):addChild(self.m_wheelLockSpine, 3)

    -- 预告
    self.m_wheelYuGaoSpine = util_spineCreate("ToroLoco_yugao",true,true)
    self:findChild("Node_tx"):addChild(self.m_wheelYuGaoSpine)
    self.m_wheelYuGaoSpine:setVisible(false)
end

function ToroLocoRespinWheel:initMachine(machine)
    self.m_machine = machine
    self.m_items = {}
    self.m_multipleList = {}

    self._lastNode = nil

    self._removecount = 0

    self._index = 0

    self._bstop = false

    self._speed = 0

    self._addsppedDt = (1 / 30) *  MAX_ROLL_SPEED

    self._status = emRollSatus.emNone

    self.m_scheduler = cc.Director:getInstance():getScheduler()

    self.panel = self:findChild("Panel_1")
    
    self:initTrainNode()
end

function ToroLocoRespinWheel:initTrainNode()
    for i = 1, INIT_NUM do
        local item = GD.util_createView("CodeToroLocoSrc.ToroLocoRespinWheelNode")
        local node = self:findChild("Node_"..i)
        item:setPosition(cc.p(node:getPosition()))
        item:updateData(1, 1)
        item:setTag(i)
    
        self.panel:addChild(item)
    
        table.insert(self.m_items, item)
    end
    self._index = SHOW_NUM
    self._lastNode = self.m_items[1]
end

--[[
    刷新显示
]]
function ToroLocoRespinWheel:updateTrainNode()
    self.m_wheelYuGaoSpine:setVisible(false)
    
    for i = 1, #self.m_items do
        local pitem = self.m_items[i]
        local indexType, coins = self:getWhellData()
        pitem:updateData(indexType, coins)
    end
end

--[[
    匀速滚动
]]
function ToroLocoRespinWheel:wheelRun()
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
  
function ToroLocoRespinWheel:updateInfo(dt)
    -- 暂停滚动
    if self.m_machine:checkGameRunPause() then
        return
    end

    local num = #self.m_items
    for i=1, num do
        local speed = 2 * self.m_scheduler:getTimeScale()
        local pitem = self.m_items[i]
        local upy = pitem:getPositionY() - speed
        if pitem:getPositionY() <= -55 then
            local indexType, coins = self:getWhellData()
            pitem:updateData(indexType, coins)
            pitem:setPositionY(self._lastNode:getPositionY() + ITEM_SZ)
    
            table.remove(self.m_items, i)
            table.insert(self.m_items, 1, pitem)
            self._lastNode = pitem
        else
            pitem:setPositionY(upy)
        end
    end
end

--[[
    开始滚动
]]
function ToroLocoRespinWheel:beginRun()
    self.m_wheelYuGaoSpine:setVisible(true)
    util_spinePlay(self.m_wheelYuGaoSpine, "start", false)
    util_spineEndCallFunc(self.m_wheelYuGaoSpine, "start" ,function ()
        util_spinePlay(self.m_wheelYuGaoSpine, "idle", true)
    end) 

    self:unscheduleUpdate()

    self._removecount = 0
    self._bstop = false
    self._index = SHOW_NUM
    self._lastNode = self.m_items[1]
    self._speed = 0
    self._status = emRollSatus.emJiasu
    
    gLobalSoundManager:playSound(ToroLocoPublicConfig.SoundConfig.sound_ToroLoco_wheel_run)

    self:onUpdate( function( dt )
        -- 暂停滚动
        if self.m_machine:checkGameRunPause() then
            return
        end
    
        if self._removecount >= 38 then
            self._status = emRollSatus.emJianSu
        end
    
        self:updateTrain(dt)
        
        if self._bstop then
            self:unscheduleUpdate()
            local reelResDis = ITEM_SZ/4*3
            local time = reelResDis/self._speed/60

            for i=1, INIT_NUM do
                local node = self:findChild("Node_"..i)
                local upx = self.m_items[i]:getPositionX()
                local upy = self.m_items[i]:getPositionY() - reelResDis

                self.m_items[i]:runAction(cc.Sequence:create(
                    cc.MoveTo:create(time, cc.p(upx, upy)),
                    cc.MoveTo:create(0.1, cc.p(node:getPosition()))
                ))
            end
            
            performWithDelay(self, function()
                self:playWheelWinEffect(function()
                    if self.m_callback then
                        self.m_callback()
                    end
                end)
            end,0.2 + time)
        end
    end)
end

function ToroLocoRespinWheel:updateTrain(dt)
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
            self._speed = self._speed - 0.2
        end
    end
  
    local speed = self._speed * self.m_scheduler:getTimeScale()
  
    for i = 1, #self.m_items do
        local pitem = self.m_items[i]
        local upy = pitem:getPositionY() - speed
        if pitem:getPositionY() <= -55 then
            self._removecount = self._removecount + 1
            if(self._index < ROLL_MAX_NUM)then
                self._index = self._index + 1
                local indexType, coins = self:getWhellData()
                if(self._index > STOP_NUM-2)then
                    indexType = self.m_multipleList[self._index].indexType or indexType
                    coins = self.m_multipleList[self._index].coins or coins
                end
        
                pitem:updateData(indexType, coins)
                pitem:setPositionY(self._lastNode:getPositionY() + ITEM_SZ)
        
                table.remove(self.m_items, i)
                table.insert(self.m_items, 1, pitem)
                self._lastNode = pitem
            end
    
            if(self._removecount == STOP_NUM )then
                self._bstop = true
                self._status = emRollSatus.emNone
            end
        else
            pitem:setPositionY(upy)
        end
    end
end

--[[
    respin玩法结束 停止滚动
]]
function ToroLocoRespinWheel:stopRoll()
    self:unscheduleUpdate()
    for index = 1, 5 do
        local node = self:findChild("Node_"..index)
        self.m_items[index]:setPosition(cc.p(node:getPosition()) )
    end
end

--[[
    处理中奖数据
]]
function ToroLocoRespinWheel:produceDatas( info )

    self.m_isWinJackpot = false
    local list = {}
    for index = 1, INIT_NUM do
        local indexType, coins = self:getWhellData()
        list[index] = {}
        list[index].indexType = indexType
        list[index].coins = coins
    end
    
    if info and #info > 0 then
        if info[2] == "multiple" then --乘倍
            list[2].indexType = 2
            list[2].coins = info[1]
        elseif info[2] == "bonus" then --金币
            list[2].indexType = 3
            list[2].coins = info[1]
        else -- jackpot
            list[2].indexType = 1
            list[2].coins = info[2]
            self.m_isWinJackpot = true
        end
    end

    self.m_winWheelInfo = info

    local index = 1
    local begin = ROLL_MAX_NUM - INIT_NUM + 1
  
    for i = begin, ROLL_MAX_NUM do
        self.m_multipleList[i] = list[index]
        index = index + 1
    end
end

--[[
    回调函数
]]
function ToroLocoRespinWheel:setRunEndCallFuncBack(_callBack)
    self.m_callback = _callBack
end

--[[
    获取假滚数据
]]
function ToroLocoRespinWheel:getWhellData( )
    local indexType = 1 --假滚类型 1 jackpot 2 乘倍 3 金币
    local coins = 1 
    local totalBet = globalData.slotRunData:getCurTotalBet()
    local random = math.random(1, 100)
    if random <= 33 then
        local coinsList = {15, 20, 50}
        indexType = 3
        coins = coinsList[math.random(1, 3)] * totalBet -- 几种金币的
    elseif random <= 66 then
        indexType = 1
        local index = math.random(1, 4) --4种类型的jackpot
        coins = JACKPOT_INDEX[index]
    else
        indexType = 2
        coins = math.random(2, 5) --几种乘倍 具体值
    end
    return indexType, coins
end

--[[
    播放锁链idle
]]
function ToroLocoRespinWheel:playLockIdle( )
    if self.m_wheelLockSpine:getParent() ~= self:findChild("Node_unlock") then
        util_changeNodeParent(self:findChild("Node_unlock"), self.m_wheelLockSpine)
    end
    util_spinePlay(self.m_wheelLockSpine, "idleframe", true)
end

--[[
    播放锁链idle 差一个集满棋盘
]]
function ToroLocoRespinWheel:playLockIdle2( )
    if self.m_wheelLockSpine:getParent() ~= self:findChild("Node_unlock") then
        util_changeNodeParent(self:findChild("Node_unlock"), self.m_wheelLockSpine)
    end
    util_spinePlay(self.m_wheelLockSpine, "idleframe2", true)
end

--[[
    解锁动画
]]
function ToroLocoRespinWheel:playWheelUnlockEffect(_func)
    gLobalSoundManager:playSound(ToroLocoPublicConfig.SoundConfig.sound_ToroLoco_wheel_unlock)

    util_changeNodeParent(self:findChild("Node_jiesuo"), self.m_wheelLockSpine, 3)

    self.m_wheelGuoChangSpine:setVisible(true)
    self.m_wheelTotalWinSpine:setVisible(true)
    util_spinePlay(self.m_wheelLockSpine, "actionframe_respin", false)
    util_spinePlay(self.m_wheelGuoChangSpine, "actionframe_respin", false)
    util_spinePlay(self.m_wheelTotalWinSpine, "actionframe_respin", false)
    self.m_machine:playRespinReelShakeEffect()

    performWithDelay(self,function()
        self:setRunEndCallFuncBack(_func)
        self:beginRun()
    end, 24/30)
end

--[[
    中奖动画
]]
function ToroLocoRespinWheel:playWheelWinEffect(_func)
    gLobalSoundManager:playSound(ToroLocoPublicConfig.SoundConfig.sound_ToroLoco_wheel_select)

    self:runCsbAction("zhongjiang", false, function()
        self:runCsbAction("idle")
        self.m_machine:playWheelCollectEffect(self.m_items[4], function()
            self.m_items[4]:runCsbAction("idle")
            if _func then
                _func()
            end
        end)
    end)

    if self.m_isWinJackpot then
        self.m_machine.m_respinJackPotBarView:playWinEffect(self.m_winWheelInfo[2])
    end
end

return ToroLocoRespinWheel
