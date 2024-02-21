---
--xcyy
--2018年5月23日
--DazzlingDiscoMultipleBar.lua
local PublicConfig = require "DazzlingDiscoPublicConfig"
local DazzlingDiscoMultipleBar = class("DazzlingDiscoMultipleBar",util_require("Levels.BaseLevelDialog"))

local ITEM_NAME = {
    "X1",
    "X2",
    "X3",
    "X5",
    "X6",
    "X7",
    "X8",
    "X10",
    "jackpot",
}

function DazzlingDiscoMultipleBar:initUI(params)
    self.m_machine = params.machine
    self.m_curMultiIndex = 0
    self:createCsbNode("DazzlingDisco_chengbeilan.csb")

    self.m_multiItems = {}
    for index = 1,9 do
        local item = util_createAnimation("DazzlingDisco_chengbeilan_sekuai.csb")
        for iName = 1,#ITEM_NAME do
            item:findChild("Node_"..ITEM_NAME[iName]):setVisible(index == iName)
        end
        self:findChild("Node_"..index):addChild(item)
        item:runCsbAction("idle")

        self.m_multiItems[index] = item
    end

end

--[[
    进度增长动画
]]
function DazzlingDiscoMultipleBar:addMultiAni(count,func)
    --进度增长
    if count > self.m_curMultiIndex then
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_DazzlingDisco_multiple_bar_up)
        local item = self.m_multiItems[count]
        self:updateCurMulti(count)
        item:runCsbAction("start",false,function(  )
            
        end)
        if count > 1 and count < #ITEM_NAME then
            self.m_machine:showMultiAni(item,ITEM_NAME[count],function(  )
                if type(func) == "function" then
                    func()
                end
            end)
        elseif count == #ITEM_NAME then --触发玩法
            self.m_machine:changeBgAni("jackpotReel")
            self.m_machine:clearCurMusicBg()
            gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_DazzlingDisco_multiple_trigger)
            self:runCsbAction("actionframe_chufa",false,function(  )
                self:runCsbAction("idle")
                --播完触发进度清空
                for index = 1,#self.m_multiItems do
                    local item = self.m_multiItems[index]
                    item:runCsbAction("over")
                end
                self.m_machine:delayCallBack(20 / 60,function(  )
                    self:updateCurMulti(0)
                end)


                if type(func) == "function" then
                    func()
                end
            end)

        else
            if type(func) == "function" then
                func()
            end
        end
        
    elseif count < self.m_curMultiIndex then --进度清空
        for index = 1,self.m_curMultiIndex do
            local item = self.m_multiItems[index]
            item:runCsbAction("over")
        end
        self.m_machine:delayCallBack(20 / 60,function(  )
            self:updateCurMulti(count)
            if type(func) == "function" then
                func()
            end
        end)
        
    else--不增长直接刷进度
        self:updateCurMulti(count)
        if type(func) == "function" then
            func()
        end
    end
end

--[[
    刷新当前进度
]]
function DazzlingDiscoMultipleBar:updateCurMulti(count)
    for index = 1,9 do
        local item = self.m_multiItems[index]
        item:findChild(ITEM_NAME[index]):setVisible(index <= count)
    end

    self.m_curMultiIndex = count
end


return DazzlingDiscoMultipleBar