---
--xcyy
--2018年5月23日
--ClawStallMapLevelsNode.lua
local PublicConfig = require "ClawStallPublicConfig"
local ClawStallMapLevelsNode = class("ClawStallMapLevelsNode",util_require("Levels.BaseLevelDialog"))

local MAX_LEVELS_COUNT      =       4

function ClawStallMapLevelsNode:initUI(params)
    self.m_index = params.index
    self.m_machine = params.machine
    local m_mapList = self.m_machine.m_mapList
    self:createCsbNode("ClawStall_Map_Level_node.csb")

    self.m_curItemIndex = MAX_LEVELS_COUNT * (self.m_index - 1)

    self.m_items = {}
    --小关图标
    for index = 1,3 do
        local item = util_createAnimation("ClawStall_Map_xiaoguan.csb")
        self:findChild("node_level_"..index):addChild(item)
        self.m_items[#self.m_items + 1] = item
        item:findChild("m_lb_num"):setString(self.m_curItemIndex + index)
        item:findChild("fenzhi"):setVisible(false)
    end

    --大关图标
    local bigItem = util_createAnimation("ClawStall_Map_daguan.csb")
    self:findChild("node_level_4"):addChild(bigItem)
    self.m_items[#self.m_items + 1] = bigItem
    bigItem:findChild("m_lb_num"):setString(self.m_curItemIndex + MAX_LEVELS_COUNT)
    for index = 1,20 do
        bigItem:findChild("Node_"..(index - 1)):setVisible(false)   
    end
    

    --刷新大关信号显示
    local data = m_mapList[self.m_curItemIndex + MAX_LEVELS_COUNT]
    if data.type == "BIG" then
        local offsetIndex = 5
        local rowCount = 3
        if data.mapRows == "maprow4" then -- 4行玩法
            offsetIndex = 0
            rowCount = 4
        end
        bigItem:findChild("Node_3Rows"):setVisible(rowCount == 3)
        bigItem:findChild("Node_4Rows"):setVisible(rowCount == 4)
        bigItem:findChild("Panel_4"):setVisible(rowCount == 4)
        bigItem:findChild("Panel_3"):setVisible(rowCount == 3)
        if data and data.fixPos then
            for i,posIndex in ipairs(data.fixPos) do
                local lockNode = bigItem:findChild("Node_"..posIndex + offsetIndex)
                
                if lockNode then
                    lockNode:setVisible(true)  
                end
            end
        end

        for index = 1,3 do
            bigItem:findChild("Particle_4_"..index):setVisible(false)
            bigItem:findChild("Particle_3_"..index):setVisible(false)
        end
    end
    -- bigItem:runCsbAction("actionframe",true)

    --灯光
    self.m_lights = {}
    for index = 1,4 do
        local light
        if index == 4 then
            light = util_createAnimation("ClawStall_Map_LightsH.csb")
        else
            light = util_createAnimation("ClawStall_Map_Lights.csb")
        end

        self:findChild("lights_"..index):addChild(light)
        self.m_lights[#self.m_lights + 1] = light
        light:runCsbAction("idle",true)
    end
end

--[[
    刷新显示
]]
function ClawStallMapLevelsNode:refreshView(curIndex)
    -- if true then
    --     return
    -- end
    for index = 1,4 do
        local light = self.m_lights[index]
        local item = self.m_items[index]
        light:runCsbAction("idle")
        if curIndex >= self.m_curItemIndex + index then
            light:setVisible(false)
            item:runCsbAction("idle3")
        else
            light:setVisible(true)
            item:runCsbAction("idle",true)
        end

        if index < 4 then
            local fenzhi = item:findChild("fenzhi")
            if fenzhi then
                fenzhi:setVisible(false)
            end
        end
    end
end

--[[
    显示赢钱动画
]]
function ClawStallMapLevelsNode:showWinCoinsAni(curIndex,func)
    local isInSelf = false
    if curIndex > self.m_curItemIndex and  curIndex <= self.m_curItemIndex + MAX_LEVELS_COUNT then
        isInSelf = true
    end
    if not isInSelf then
        return
    end
    local itemIndex = curIndex % MAX_LEVELS_COUNT
    if itemIndex == 0 then
        itemIndex = MAX_LEVELS_COUNT
    end
    --光消失
    local light = self.m_lights[itemIndex]
    light:runCsbAction("xiaoshi",false,function(  )
        
    end)

    local item = self.m_items[itemIndex]
    if itemIndex < 4 then
        local selfData = self.m_machine.m_runSpinResultData.p_selfMakeData or {}
        local winCoins = selfData.collectWin or 0
        local str = util_formatCoins(winCoins,3)
        local fenzhi = item:findChild("fenzhi")
        if fenzhi then
            fenzhi:setVisible(true)
        end
        local m_lb_coins = item:findChild("m_lb_coins")
        if m_lb_coins then
            m_lb_coins:setString(str)
        end
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_ClawStall_trigger_small_level)
        item:runCsbAction("actionframe",false,function(  )
            
            self.m_machine:delayCallBack(0.5,function(  )
                if fenzhi then
                    fenzhi:setVisible(false)
                end
                self.m_machine:flyMapWinCoinsAni(str,item,function(  )
                    item:runCsbAction("bianan",false,function(  )
                        self:refreshView(curIndex)
                        if type(func) == "function" then
                            func()
                        end
                    end)
                    
                end)
            end)
            
            
        end)
    else
        for index = 1,3 do
            item:findChild("Particle_4_"..index):setVisible(true)
            item:findChild("Particle_3_"..index):setVisible(true)
            item:findChild("Particle_4_"..index):resetSystem()
            item:findChild("Particle_3_"..index):resetSystem()
        end
        self.m_machine:clearCurMusicBg()
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_ClawStall_trigger_big_level)
        --大关
        item:runCsbAction("actionframe",false,function(  )
            self:refreshView(curIndex)
            if type(func) == "function" then
                func()
            end
        end)
    end
    
end


return ClawStallMapLevelsNode