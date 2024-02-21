---
--xcyy
--2018年5月23日
--JuicyHolidayCollectBar.lua
local PublicConfig = require "JuicyHolidayPublicConfig"
local JuicyHolidayCollectBar = class("JuicyHolidayCollectBar",util_require("base.BaseView"))

function JuicyHolidayCollectBar:initUI(params)
    self.m_machine = params.machine
    self.m_spine = util_spineCreate("JuicyHoliday_shouji",true,true)
    self:addChild(self.m_spine)
end

--[[
    更新收集等级
]]
function JuicyHolidayCollectBar:initLevel(level)
    self.m_level = level
    self:updateCollectBarIdle()
end

--[[
    刷新收集进度
]]
function JuicyHolidayCollectBar:updateCollectBarIdle()
    local idleName = "idle"
    if self.m_level == 2 then
        idleName = "idle2"
    elseif self.m_level == 3 then
        idleName = "idle3"
    end
    util_spinePlay(self.m_spine,idleName,true)
end

--[[
    转化动画
]]
function JuicyHolidayCollectBar:switchAni(targetLevel,func)
    if targetLevel ~= self.m_level then
        if targetLevel == 2 then  -- 1转2
            gLobalSoundManager:playSound(PublicConfig.SoundConfig["sound_JuicyHoliday_collect_bar_switch_1"])
            util_spinePlay(self.m_spine,"switch1_2")
            util_spineEndCallFunc(self.m_spine,"switch1_2",function(  )
                if type(func) == "function" then
                    func()
                end
            end)
        elseif targetLevel == 3 and self.m_level == 2 then -- 2转3
            gLobalSoundManager:playSound(PublicConfig.SoundConfig["sound_JuicyHoliday_collect_bar_switch_2"])
            util_spinePlay(self.m_spine,"switch2_3")
            util_spineEndCallFunc(self.m_spine,"switch2_3",function(  )
                if type(func) == "function" then
                    func()
                end
            end)
        elseif targetLevel == 3 and self.m_level == 1 then --1转3
            gLobalSoundManager:playSound(PublicConfig.SoundConfig["sound_JuicyHoliday_collect_bar_switch_3"])
            util_spinePlay(self.m_spine,"switch1_3")
            util_spineEndCallFunc(self.m_spine,"switch1_3",function(  )
                if type(func) == "function" then
                    func()
                end
            end)
        end
        self.m_level = targetLevel
    end
end

--[[
    反馈动画
]]
function JuicyHolidayCollectBar:feedBackAni(collectLevel,isTrigger,func)
    local aniName = "actionframe1"
    if self.m_level == 2 then
        aniName = "actionframe2"
    elseif self.m_level == 3 then
        aniName = "actionframe3"
    end

    --计算当前收集等级
    local level = collectLevel
    -- if collectNum >= collectLevel[1] and collectNum < collectLevel[2] then
    --     level = 2
    -- elseif collectNum >= collectLevel[2] then
    --     level = 3
    -- end
    if isTrigger then
        level = 3
    end

    local isSwitch = false
    if level ~= self.m_level and level > self.m_level then
        isSwitch = true
    end

    if isSwitch then
        self:switchAni(level,func)
    else
        util_spinePlay(self.m_spine,aniName)
        util_spineEndCallFunc(self.m_spine,aniName,function(  )
            self:updateCollectBarIdle()
            if type(func) == "function" then
                func()
            end
        end)
    end
end

--[[
    播放触发动画
]]
function JuicyHolidayCollectBar:runTriggerAni(keyFunc,endFunc)
    util_spinePlay(self.m_spine,"actionframe")
    self.m_machine:delayCallBack(57 / 30,function()
        if type(keyFunc) == "function" then
            keyFunc()
        end
    end)
    util_spineEndCallFunc(self.m_spine,"actionframe",function()
        if type(endFunc) == "function" then
            endFunc()
        end
    end)

    
    local rootNode = self.m_machine:findChild("root")
    if not tolua.isnull(rootNode) then
        local tempSpine = util_spineCreate("JuicyHoliday_shouji",true,true)
        local pos = util_convertToNodeSpace(self,rootNode)
        rootNode:addChild(tempSpine)
        tempSpine:setPosition(pos)
        util_spinePlayAndRemove(tempSpine,"actionframe_up")
    end
end

return JuicyHolidayCollectBar