---
--xcyy
--2018年5月23日
--BunnyBountyCollectBar.lua
local PublicConfig = require "BunnyBountyPublicConfig"
local BunnyBountyCollectBar = class("BunnyBountyCollectBar", util_require("base.BaseView"))

--篮子层级(绿 蓝 红)
local BASKET_ZORDER = {30,20,10}

BunnyBountyCollectBar.m_rabbit_pos = nil  --兔子当前的位置

function BunnyBountyCollectBar:initUI(params)
    self.m_machine = params.machine
    self.m_collect_bars = {}
    self.m_isstopSpineIdle = false
    --创建收集篮子
    for index = 1,3 do
        local item = self:createBasket(index)--util_spineCreate("BunnyBounty_jackpot"..index,true,true)
        self:addChild(item,BASKET_ZORDER[index])
        self.m_collect_bars[index] = item
    end

    --用于随机动作
    self.m_rand_ary = {1,2,3}

    --free收集用篮子
    self.m_collect_bar_free = self:createBasket(2)
    self:addChild(self.m_collect_bar_free,BASKET_ZORDER[1])
    self.m_collect_bar_free:setVisible(false)
    self:runFreeRabbitIdle()

    --当前兔子的时间线
    self.m_rabbit_actionIndex = 1
    --当前兔子的状态
    self.m_status_rabbit = ""
end




--[[
    创建一个篮子
]]
function BunnyBountyCollectBar:createBasket(type)
    local item = util_spineCreate("BunnyBounty_jackpot"..type,true,true)
    item.m_spine_rabbit = util_spineCreate("BunnyBounty_juese",true,true)
    local node = cc.Node:create()
    node:addChild(item.m_spine_rabbit)
    util_spinePushBindNode(item,"tuzi",node)
    item.m_spine_rabbit:setVisible(false)
    return item
end
--[[
    初始化显示
]]
function BunnyBountyCollectBar:initCollectLevel(levels)
    for index = 1,3 do
        local level = levels[index]
        local item = self.m_collect_bars[index]
        item.m_level = level
        self:runBarLevelIdleAni(item,level)
    end

    self.m_collect_bar_free.m_level = levels[2]
    self:runBarLevelIdleAni(self.m_collect_bar_free,self.m_collect_bar_free.m_level)
end

--[[
    收集条按等级播idle
]]
function BunnyBountyCollectBar:runBarLevelIdleAni(item,level)
    if item == self.m_collect_bar_free then
        util_spinePlay(item,"idleframe"..level.."_s",true)
        item.m_aniName = "idleframe"..level.."_s"
    else
        util_spinePlay(item,"idleframe"..level,true)
        item.m_aniName = "idleframe"..level
    end
    
end

--[[
    收集反馈动效
]]
function BunnyBountyCollectBar:runCollectFeedBackAni(item,targetLevel,isTrigger,func)
    --时间线后缀
    local str = ""
    if item == self.m_collect_bar_free then
        str = "_s"
    end
    local aniName = "shouji"..targetLevel
    --升级
    if targetLevel > item.m_level then
        if targetLevel - item.m_level == 2 then -- 从1到3
            aniName = "switch3"
        else
            aniName = "switch"..item.m_level
        end
    end
    aniName = aniName..str
    item.m_level = targetLevel
    item.m_aniName = aniName
    util_spinePlay(item,aniName)
    util_spineEndCallFunc(item,aniName,function()
        if not isTrigger then
            self:runBarLevelIdleAni(item,targetLevel)
        end
        
        if type(func) == "function" then
            func()
        end
    end)
end

--[[
    收集动效
]]
function BunnyBountyCollectBar:runCollectAni(symbolType,level,isTrigger,func)
    local item = self:getBarItemBySymbolType(symbolType)
    if item then
        self:runCollectFeedBackAni(item,level,isTrigger,func)
    else
        if type(func) == "function" then
            func()
        end
    end
end

--[[
    根据动作索引获取进度条
]]
function BunnyBountyCollectBar:getBarItemByActionIndex(actionIndex)
    if actionIndex == 1 then
        return self.m_collect_bars[2]
    elseif actionIndex == 2 then
        return self.m_collect_bars[1]
    elseif actionIndex == 3 then
        return self.m_collect_bars[3]
    else
        return self.m_collect_bar_free
    end
end

--[[
    根据小块类型获取对应的进度条
]]
function BunnyBountyCollectBar:getBarItemBySymbolType(symbolType)
    if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
        return self.m_collect_bar_free
    end

    local item
    if symbolType == self.m_machine.SYMBOL_SCORE_BONUS_1 then -- 绿色
        item = self.m_collect_bars[1]
    elseif symbolType == self.m_machine.SYMBOL_SCORE_BONUS_2 then -- 蓝色
        item = self.m_collect_bars[2]
    elseif symbolType == self.m_machine.SYMBOL_SCORE_BONUS_3 then -- 红色
        item = self.m_collect_bars[3]
    end

    return item
end

--[[
    获取是否播放idle 30%概率
]]
function BunnyBountyCollectBar:getIdleChance()
    local isPlay = (math.random(1, 100) <= 35) 
    return isPlay
end

--[[
    free中兔子idle
]]
function BunnyBountyCollectBar:runFreeRabbitIdle()
    if not self:getIdleChance() or globalData.slotRunData.currSpinMode ~= FREE_SPIN_MODE then
        performWithDelay(self.m_collect_bar_free,function()
            self:runFreeRabbitIdle()
        end,3)
        return
    end
    --当前执行动作的兔子
    local spine_rabbit = self.m_collect_bar_free.m_spine_rabbit
    spine_rabbit:setVisible(true)

    --当前兔子的状态
    self.m_status_rabbit = "start"


    local params = {}
    params[#params + 1] = {
        type = "spine",   --"animation":帧动画 "spine":骨骼动画 "delay":延时动作 "seq":序列动作 必传参数
        node = spine_rabbit,   --执行动画节点  必传参数
        actionName = "start4", --动作名称  动画必传参数,单延时动作可不传
        callBack = function()
            self.m_status_rabbit = "idle"
        end
    }
    params[#params + 1] = {
        type = "spine",   --"animation":帧动画 "spine":骨骼动画 "delay":延时动作 "seq":序列动作 必传参数
        node = spine_rabbit,   --执行动画节点  必传参数
        actionName = "idle4", --动作名称  动画必传参数,单延时动作可不传
        callBack = function()
            self.m_status_rabbit = "over"
        end
    }
    params[#params + 1] = {
        type = "spine",   --"animation":帧动画 "spine":骨骼动画 "delay":延时动作 "seq":序列动作 必传参数
        node = spine_rabbit,   --执行动画节点  必传参数
        actionName = "over4", --动作名称  动画必传参数,单延时动作可不传
        callBack = function()
            self.m_status_rabbit = ""
            spine_rabbit:setVisible(false)
            performWithDelay(self.m_collect_bar_free,function()
                self:runFreeRabbitIdle()
            end,3)
        end,   --回调函数 可选参数
    }
    util_runAnimations(params)
end

--[[
    兔子idle
]]
function BunnyBountyCollectBar:runRabbitIdle()

    if not self:getIdleChance() or self.m_isstopSpineIdle or globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
        performWithDelay(self,function()
            self:runRabbitIdle()
        end,3)
        return
    end

    local randIndex = math.random(1,#self.m_rand_ary)
    local actionIndex = self.m_rand_ary[randIndex]
    --当前兔子的时间线
    self.m_rabbit_actionIndex = actionIndex
    local barItem = self:getBarItemByActionIndex(actionIndex)
    --重置随机动作数组
    self.m_rand_ary = {}
    for index = 1,3 do
        if index ~= actionIndex then
            self.m_rand_ary[#self.m_rand_ary + 1] = index
        end
    end

    self:stopAllActions()

    --当前执行动作的兔子
    local spine_rabbit = barItem.m_spine_rabbit
    spine_rabbit:setVisible(true)

    --当前兔子的状态
    self.m_status_rabbit = "start"
    
    
    local params = {}
    params[#params + 1] = {
        type = "spine",   --"animation":帧动画 "spine":骨骼动画 "delay":延时动作 "seq":序列动作 必传参数
        node = spine_rabbit,   --执行动画节点  必传参数
        actionName = "start"..actionIndex, --动作名称  动画必传参数,单延时动作可不传
        callBack = function()
            self.m_status_rabbit = "idle"
        end
    }
    params[#params + 1] = {
        type = "spine",   --"animation":帧动画 "spine":骨骼动画 "delay":延时动作 "seq":序列动作 必传参数
        node = spine_rabbit,   --执行动画节点  必传参数
        actionName = "idle"..actionIndex, --动作名称  动画必传参数,单延时动作可不传
        callBack = function()
            self.m_status_rabbit = "over"
        end
    }
    params[#params + 1] = {
        type = "spine",   --"animation":帧动画 "spine":骨骼动画 "delay":延时动作 "seq":序列动作 必传参数
        node = spine_rabbit,   --执行动画节点  必传参数
        actionName = "over"..actionIndex, --动作名称  动画必传参数,单延时动作可不传
        callBack = function()
            self.m_status_rabbit = ""
            spine_rabbit:setVisible(false)
            performWithDelay(self,function()
                self:runRabbitIdle()
            end,3)
        end,   --回调函数 可选参数
    }
    util_runAnimations(params)
end

--[[
    显示free用收集条
]]
function BunnyBountyCollectBar:showFreeCollectBar()
    for index = 1,3 do
        local item = self.m_collect_bars[index]
        item:setVisible(false)
    end

    --同步bonus收集条进度
    local bonusItem = self.m_collect_bars[2]
    self.m_collect_bar_free.m_level = bonusItem.m_level
    self:runBarLevelIdleAni(self.m_collect_bar_free,self.m_collect_bar_free.m_level)

    self.m_collect_bar_free:setVisible(true)
    local rowCount = self.m_machine.m_iReelRowNum
    local posNode = self.m_machine:findChild("Node_free_dfdc_"..rowCount.."x5")
    if posNode then
        local pos = util_convertToNodeSpace(posNode,self)
        self.m_collect_bar_free:setPosition(pos)
    end
end

--[[
    显示base用收集条
]]
function BunnyBountyCollectBar:showBaseCollectBar()
    for index = 1,3 do
        local item = self.m_collect_bars[index]
        item:setVisible(true)
    end
    self.m_collect_bar_free:setVisible(false)
end

--[[
    额外的触发动画
]]
function BunnyBountyCollectBar:runExtraTriggerAni(symbolType)
    local item = self:getBarItemBySymbolType(symbolType)
    if item then
        local str = ""
        item.m_aniName = "actionframe3"
        util_spinePlay(item,"actionframe3")
        util_spineEndCallFunc(item,"actionframe3",function()
            item.m_level = 3
            item.m_aniName = "idleframe4"
            util_spinePlay(item,"idleframe4",true)
        end)
    end
end

--[[
    触发动画
]]
function BunnyBountyCollectBar:runTriggerAni(symbolType,triggerType,func)
    self:stopSpineIdle()
    self:checkRabbitStatus()
    if triggerType == "fsAndRs"  and symbolType == self.m_machine.SYMBOL_SCORE_BONUS_3 then
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_BunnyBounty_collect_trigger_double)
    elseif symbolType == self.m_machine.SYMBOL_SCORE_BONUS_1 and triggerType ~= "fsAndRs" then -- 绿色
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_BunnyBounty_collect_trigger_green)
    elseif symbolType == self.m_machine.SYMBOL_SCORE_BONUS_2 and triggerType == "bonus" then -- 蓝色
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_BunnyBounty_collect_trigger_blue)
    elseif symbolType == self.m_machine.SYMBOL_SCORE_BONUS_3 then -- 红色
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_BunnyBounty_collect_trigger_red)
    end

    local item = self:getBarItemBySymbolType(symbolType)
    if item then
        local str = ""
        if triggerType == "fsAndRs" then
            str = "2"
        elseif item == self.m_collect_bar_free then
            str = "_s"
        end
        -- util_spineAddPlay(item,"actionframe"..str)
        item.m_aniName = "actionframe"..str
        util_spinePlay(item,"actionframe"..str)
        util_spineFrameCallFunc(item,"actionframe"..str,"chuxian",function()
            if type(func) == "function" then
                func()
            end
        end,function()
            item.m_level = 3
            item.m_aniName = "idleframe4"..str
            util_spinePlay(item,"idleframe4"..str,true)
        end)
    else
        if type(func) == "function" then
            func()
        end
    end
    
end

--[[
    校验兔子当前时间线状态,避免触发时跳帧
]]
function BunnyBountyCollectBar:checkRabbitStatus()
    if self.m_status_rabbit == "" or self.m_status_rabbit == "over" then
        return
    end

    local actionIndex = self.m_rabbit_actionIndex
    if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
        actionIndex = 4
    end

    local barItem = self:getBarItemByActionIndex(actionIndex)

    util_spinePlay(barItem.m_spine_rabbit,"over"..actionIndex)
    util_spineEndCallFunc(barItem.m_spine_rabbit,"over"..actionIndex,function()
        barItem.m_spine_rabbit:setVisible(false)
    end)
end

--[[
    兔子触发动画
]]
function BunnyBountyCollectBar:runRabbitTrigger(triggerType,keyFunc,endFunc)

    local aniName,overAni = "",""
    local barItem,respinItem
    if triggerType == "free" then
        aniName = "actionframe_guochang"
        overAni = "over2"
        barItem = self:getBarItemBySymbolType(self.m_machine.SYMBOL_SCORE_BONUS_1)
    elseif triggerType == "bonus" then
        aniName = "actionframe_guochang4"
        overAni = "over1"
        barItem = self:getBarItemBySymbolType(self.m_machine.SYMBOL_SCORE_BONUS_2)
    elseif triggerType == "respin" then
        aniName = "actionframe_guochang2"
        overAni = "over3"
        barItem = self:getBarItemBySymbolType(self.m_machine.SYMBOL_SCORE_BONUS_3)
    elseif triggerType == "fsAndRs" then
        aniName = "actionframe_guochang3"
        overAni = "over3"
        barItem = self:getBarItemBySymbolType(self.m_machine.SYMBOL_SCORE_BONUS_1)
        respinItem = self:getBarItemBySymbolType(self.m_machine.SYMBOL_SCORE_BONUS_3)
    end

    local spine_rabit = barItem.m_spine_rabbit
    

    spine_rabit:setVisible(true)
    util_spinePlay(spine_rabit,aniName)
    util_spineFrameCallFunc(spine_rabit,aniName,"shijian",function()
        if type(keyFunc) == "function" then
            keyFunc()
        end
    end,function()
        util_spinePlay(spine_rabit,overAni)
        spine_rabit:setVisible(false)
        if type(endFunc)  == "function" then
            endFunc()
        end
    end)

    --respin和free同时触发时,两只兔子同时执行,兔子跳到最高点切换显示
    if respinItem then
        local spine_respin = respinItem.m_spine_rabbit
        util_spinePlay(spine_respin,aniName)
        util_spineEndCallFunc(spine_respin,aniName,function()
            spine_respin:setVisible(false)
        end)
        performWithDelay(spine_respin,function()
            spine_rabit:setVisible(false)
            spine_respin:setVisible(true)
        end,3)
    end
end

--[[
    停止spine idle
]]
function BunnyBountyCollectBar:stopSpineIdle()
    self:stopAllActions()
    self.m_isstopSpineIdle = true
end

--[[
    恢复兔子idle
]]
function BunnyBountyCollectBar:resumeSpinIdle()
    self.m_isstopSpineIdle = false
    self:runRabbitIdle()
end

return BunnyBountyCollectBar
