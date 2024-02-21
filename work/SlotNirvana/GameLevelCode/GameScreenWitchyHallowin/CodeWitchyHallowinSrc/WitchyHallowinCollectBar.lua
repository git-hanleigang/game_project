---
--xcyy
--2018年5月23日
--WitchyHallowinCollectBar.lua

local WitchyHallowinCollectBar = class("WitchyHallowinCollectBar",util_require("Levels.BaseLevelDialog"))

local SPINE_ITEMS = {
    "WitchyHallowin_guo_zi",
    "WitchyHallowin_guo_hong",
    "WitchyHallowin_guo_lan"
}

local FEED_BACK_ANI = {
    "WitchyHallowin_guo_zi_bd",
    "WitchyHallowin_guo_hong_bd",
    "WitchyHallowin_guo_lan_bd"
}

local LIGHTS_ANI = {
    "shinezi",
    "shinehong",
    "shinelan"
}

function WitchyHallowinCollectBar:initUI(params)
    self.m_machine = params.machine
    self:createCsbNode("WitchyHallowin_Respintitle.csb")

    for index = 1,6 do
        local particle = self:findChild("Particle_"..index)
        if particle then
            particle:setVisible(false)
        end
    end

    self:runCsbAction("idle",true)

    self.m_collect_pos = util_createAnimation("WitchyHallowin_guo.csb")
    self.m_machine:findChild("Node_guo"):addChild(self.m_collect_pos)

    self.m_barItems = {}
    self.m_lights = {}
    for index = 1,3 do
        local item = util_spineCreate(SPINE_ITEMS[index],true,true)
        self.m_collect_pos:findChild("Node_3_"..index):addChild(item)
        self.m_barItems[index] = item
        item.m_level = 1
        item.m_index = index
        util_spinePlay(item,"idleframe1",true)

        local light = util_createAnimation("WitchyHallowin_guo_"..LIGHTS_ANI[index]..".csb")
        self.m_collect_pos:findChild("Node_"..LIGHTS_ANI[index]):addChild(light)
        self.m_lights[index] = light
        light.m_isIdle = false
        light:setVisible(false)

        local darkAni = util_createAnimation("WitchyHallowin_Respintitle_dark.csb")
        self:findChild("Node_dark"..index):addChild(darkAni)
        darkAni:setVisible(false)
        item.m_darkAni = darkAni

        local feedBackAni = util_spineCreate(FEED_BACK_ANI[index],true,true)
        item:addChild(feedBackAni)
        feedBackAni:setVisible(false)
        item.m_feedBackAni = feedBackAni
    end

    util_setCascadeOpacityEnabledRescursion(self,true)
end

--[[
    更新收集等级
]]
function WitchyHallowinCollectBar:initCollectLevel(collectData,collectLevel)
    for index = 1,3 do
        local item = self.m_barItems[index]
        local collectNum = collectData[index] or 0
        --计算当前收集等级
        local level = 1
        if collectNum >= collectLevel[1] and collectNum < collectLevel[2] then
            level = 2
        elseif collectNum >= collectLevel[2] then
            level = 3
        end
        item.m_level = level
        self:updateCollectBar(item)

        self:updateItemBgLight(item)
    end
end

--[[
    刷新收集进度
]]
function WitchyHallowinCollectBar:updateCollectBar(item)
    util_spinePlay(item,"idleframe"..item.m_level,true)
end

--[[
    刷新背景光
]]
function WitchyHallowinCollectBar:updateItemBgLight(item)
    local light = self.m_lights[item.m_index]
    if item.m_level == 3 then
        light:setVisible(true)
        if not light.m_isIdle then
            light.m_isIdle = true
            light:runCsbAction("idle",true)
        end
    else
        light:setVisible(false)
        light.m_isIdle = false
    end
end

--[[
    转化动画
]]
function WitchyHallowinCollectBar:switchAni(item,curLevel,targetLevel)
    if targetLevel ~= curLevel then
        if targetLevel == 2 then  -- 1转2
            util_spinePlay(item,"switch1")
            util_spineEndCallFunc(item,"switch1",function(  )
                util_spinePlay(item,"idleframe2",true)
            end)
        elseif targetLevel == 3 and curLevel == 2 then -- 2转3
            util_spinePlay(item,"switch2")
            util_spineEndCallFunc(item,"switch2",function(  )
                util_spinePlay(item,"idleframe3",true)
            end)
        elseif targetLevel == 3 and curLevel == 1 then --1转3
            util_spinePlay(item,"switch3")
            util_spineEndCallFunc(item,"switch3",function(  )
                util_spinePlay(item,"idleframe3",true)
            end)
        end
        item.m_level = targetLevel

        if targetLevel == 3 then
            local light = self.m_lights[item.m_index]
            light.m_isIdle = true
            light:setVisible(true)
            light:runCsbAction("start",false,function(  )
                light:runCsbAction("idle",true)
            end)
        end
    end
end

--[[
    反馈动画
]]
function WitchyHallowinCollectBar:feedBackAni(index,collectData,collectLevel,isTrigger)
    local item = self.m_barItems[index]
    local collectNum = collectData[index] or 0
    local aniName = "actionframe1"
    if item.m_level == 2 then
        aniName = "actionframe2"
    elseif item.m_level == 3 then
        aniName = "actionframe3"
    end

    --计算当前收集等级
    local level = 1
    if collectNum >= collectLevel[1] and collectNum < collectLevel[2] then
        level = 2
    elseif collectNum >= collectLevel[2] then
        level = 3
    end
    if isTrigger then
        level = 3
    end

    local time = 45 / 30
    local isSwitch = false
    if level ~= item.m_level and level > item.m_level then
        isSwitch = true
    end

    if isSwitch then
        self:switchAni(item,item.m_level,level)
    else

        local feedBackAni = item.m_feedBackAni
        feedBackAni:setVisible(true)
        util_spinePlay(feedBackAni,aniName)
        util_spineEndCallFunc(feedBackAni,aniName,function(  )
            feedBackAni:setVisible(false)
            -- self:updateCollectBar(item,collectData,collectLevel)
        end)
    end

    return time
end

--[[
    获取要收集的罐子
]]
function WitchyHallowinCollectBar:getCollectBarItemByIndex(index)
    local item = self.m_barItems[index]
    return item
end

--[[
    播放触发动画
]]
function WitchyHallowinCollectBar:runTriggerAni(triggerData,func)
    self:runCsbAction("actionframe",false,function(  )
        self:runCsbAction("idle",true)
    end)

    local highLightName = {"zi_tx","hong_tx","lan_tx"}
    --罐子播触发
    for index = 1,#triggerData do
        local light = self.m_lights[index]
        
        local item = self.m_barItems[index]
        if triggerData[index] == 0 then--未触发
            item.m_darkAni:setVisible(true)
            item.m_darkAni:runCsbAction("dark")
            self:findChild(highLightName[index]):setVisible(false)
            if item.m_level == 1 then
                util_spinePlay(item,"dark1")
            else
                util_spinePlay(item,"dark2")
            end

            if light:isVisible() then
                light:runCsbAction("over",false,function(  )
                    light:setVisible(false)
                    light.m_isIdle = false
                end)
            end
        else
            self:findChild(highLightName[index]):setVisible(true)
            for iPar = 1,2 do
                local particle = self:findChild("Particle_"..(iPar + (index - 1) * 2))
                if particle then
                    particle:setVisible(true)
                    particle:resetSystem()
                end
            end
            util_spinePlay(item,"actionframe")
            util_spineEndCallFunc(item,"actionframe",function(  )
                item.m_level = 3
                -- self:updateCollectBar(item)

                if light:isVisible() then
                    light:runCsbAction("over",false,function(  )
                        light:setVisible(false)
                        light.m_isIdle = false
                    end)
                end
            end)
        end
    end
    self.m_machine:delayCallBack(2,function(  )
        for k,light in pairs(self.m_lights) do
            if light:isVisible() then
                light:runCsbAction("over",false,function(  )
                    light:setVisible(false)
                    light.m_isIdle = false
                end)
            end
            
        end
        if type(func) == "function" then
            func()
        end
    end)
end

--[[
    隐藏触发的罐子
]]
function WitchyHallowinCollectBar:hideItemsByTrigger(trigger)
    for index = 1,#trigger do
        if trigger[index] == 1 then
            self.m_barItems[index]:setVisible(false)
        end
    end
end

--[[
    隐藏所有罐子
]]
function WitchyHallowinCollectBar:hideAllItems( )
    for index = 1,3 do
        self.m_barItems[index]:setVisible(false)
    end
end

--[[
    设置收集点是否隐藏
]]
function WitchyHallowinCollectBar:setCollectPosVisible(isVisible)
    self.m_collect_pos:setVisible(isVisible)
end

--[[
    切换收集条父节点
]]
function WitchyHallowinCollectBar:changeItemsParentByTrigger(trigger)
    --计算触发玩法的数量
    local triggerCount = 0
    for index = 1,#trigger do
        if trigger[index] == 1 then
            triggerCount = triggerCount + 1
        end
    end

    local switchFunc = function(item)
        item:setVisible(true)
        item.m_darkAni:setVisible(false)
        item.m_level = 3
        util_spinePlay(item,"switch4")
        util_spineEndCallFunc(item,"switch4",function(  )
            self:updateCollectBar(item)
        end)
    end

    local curCount = 0
    if triggerCount == 1 then
        for index = 1,3 do
            local item = self.m_barItems[index]
            if trigger[index] == 1 then
                util_changeNodeParent(self.m_collect_pos:findChild("Node_1"),item)
                switchFunc(item)
            else
                item:setVisible(false)
            end
        end
    elseif triggerCount == 2 then
        for index = 1,3 do
            local item = self.m_barItems[index]
            if trigger[index] == 1 then
                curCount = curCount + 1
                if curCount > 2 then
                    util_printLog("万圣节女巫 玩法触发数据错误",true)
                    curCount = 2
                end
                util_changeNodeParent(self.m_collect_pos:findChild("Node_2_"..curCount),item)
                switchFunc(item)
            else
                item:setVisible(false)
            end
        end
    else
        self:resetCollectItems()
        for index = 1,3 do
            local item = self.m_barItems[index]
            switchFunc(item)
        end
    end
end

--[[
    重置收集条
]]
function WitchyHallowinCollectBar:resetCollectItems( )
    for index = 1,3 do
        local item = self.m_barItems[index]
        util_changeNodeParent(self.m_collect_pos:findChild("Node_3_"..index),item)
        item:setVisible(true)
        item.m_darkAni:setVisible(false)
    end
    
end

function WitchyHallowinCollectBar:getCollectEndNodeByIndex(collectIndex,endIndex)
    local nodeName = {"Node_zi0","Node_hong0","Node_lan0"}
    local endNode = self.m_collect_pos:findChild(nodeName[collectIndex]..endIndex)
    return endNode
end

return WitchyHallowinCollectBar