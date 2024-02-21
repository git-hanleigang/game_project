---
--xcyy
--2018年5月23日
--WolfSmashNewFreeSpinStartView.lua

local WolfSmashNewFreeSpinStartView = class("WolfSmashNewFreeSpinStartView",util_require("Levels.BaseLevelDialog"))
local PublicConfig = require "WolfSmashPublicConfig"

function WolfSmashNewFreeSpinStartView:initUI(params)

    local bonusMultipleNum = params.bonusMultipleNum
    self.endFunc1 = params.endFunc1
    self.endFunc2 = params.endFunc2
    self:createCsbNode("WolfSmash/FreeSpinStart_0.csb")
    self:addPigForView(bonusMultipleNum)
    self.m_Click = false
    self:startView()
    
end

function WolfSmashNewFreeSpinStartView:addPigForView(bonusMultipleNum)

    local function getPigGuaDianName(index)
        if index == 1 then
            return "X2piggy"
        elseif index == 2 then
            return "X3piggy"
        elseif index == 3 then
            return "X5piggy"
        elseif index == 4 then
            return "X10piggy"
        end
    end

    for i, _data in ipairs(bonusMultipleNum) do
        local pig = util_createView("CodeWolfSmashSrc.newFree.WolfSmashNewPigBtnView",{machine = self , index = i,isFreeStart = true})
        util_spinePlay(pig.m_pigSpine, "idleframe2_2",true)
        pig:setIsClick(false)
        pig:findChild("m_lb_num"):setString(_data[2])
        if _data[2] == 0 then
            pig:runCsbAction("darkidle")
            util_spinePlay(pig.m_pigSpine, "darkidle",true)
        end
        local guaDianName = getPigGuaDianName(i)
        self:findChild(guaDianName):addChild(pig)
    end
    
end

function WolfSmashNewFreeSpinStartView:startView()
    self:runCsbAction("start",false,function ()
        self.m_Click = true
        self:runCsbAction("idle",true)
    end)
end

function WolfSmashNewFreeSpinStartView:hideView()
    if self.endFunc1 then
        self.endFunc1()
    end
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_WolfSmash_free_select_hide)
    self:runCsbAction("over",false,function ()
        if self.endFunc2 then
            self.endFunc2()
        end
        self:removeFromParent()
    end)
end


--默认按钮监听回调
function WolfSmashNewFreeSpinStartView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()
    if not self.m_Click then
        return
    end
    -- gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_WolfSmash_click)
    if name == "Button_1" then       --选中
        self.m_Click = false
        self:hideView()
    end
end


--[[
    延迟回调
]]
function WolfSmashNewFreeSpinStartView:delayCallBack(time, func)
    local waitNode = cc.Node:create()
    self:addChild(waitNode)
    performWithDelay(
        waitNode,
        function()
            waitNode:removeFromParent(true)
            waitNode = nil
            if type(func) == "function" then
                func()
            end
        end,
        time
    )

    return waitNode
end

return WolfSmashNewFreeSpinStartView