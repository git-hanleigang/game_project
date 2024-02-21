---
--xcyy
--2018年5月23日
--WolfSmashGuideBtnView.lua

local WolfSmashGuideBtnView = class("WolfSmashGuideBtnView",util_require("Levels.BaseLevelDialog"))
local PublicConfig = require "WolfSmashPublicConfig"

function WolfSmashGuideBtnView:initUI(machine,index)
    self.m_machine = machine
    self:createCsbNode("WolfSmash_yindao_anniu.csb")
    self.m_Click = true
    self:setBtnVisibleForIndex(index)
    -- self:showBtnForIndex()
end

function WolfSmashGuideBtnView:setBtnVisibleForIndex(index)
    for i=1,3 do
        self:findChild("Button_"..i):setVisible(false)
        self:findChild("ef_sg"..i):setVisible(false)
    end
    if index == 1 then
        self:findChild("Button_1"):setVisible(true)
        self:findChild("ef_sg"..1):setVisible(true)
    elseif index == 2 then
        self:findChild("Button_3"):setVisible(true)
        self:findChild("ef_sg"..3):setVisible(true)
    elseif index == 3 then
        self:findChild("Button_2"):setVisible(true)
        self:findChild("ef_sg"..2):setVisible(true)
    end
end

function WolfSmashGuideBtnView:showBtnForIndex()
    self:runCsbAction("start",false,function ()
        self:runCsbAction("idleframe",true)
    end)
end

function WolfSmashGuideBtnView:hideBtnForIndex(func)
    self:runCsbAction("over",false,function ()
        if type(func) == "function" then
            func()
        end
    end)
end

--默认按钮监听回调
function WolfSmashGuideBtnView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

    -- if not self.m_Click then
    --     return
    -- end
    -- self.m_Click = false
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_WolfSmash_click)
    if name == "Button_2" then
        if self.m_machine.curGuideIndex ~= 4 then
            return
        end
        self.m_machine:showGuideFourClick()
        self:delayCallBack(20/60,function ()
            self.m_machine:showGuideFourClickForPlay()
        end)
        
    elseif name == "Button_1" then         --点击随机按钮
        if self.m_machine.curGuideIndex ~= 3 then
            return
        end
        self.m_machine:showGuideThreeClick()
    elseif name == "Button_3" then          --点击重置按钮
        if self.m_machine.curGuideIndex == 4 then
            self.m_machine:showGuideFourClick()
            self:delayCallBack(20/60,function ()
                self.m_machine:showGuideFourClickForReset()
            end)
        else
            if self.m_machine.curGuideIndex ~= 2 then
                return
            end
            self.m_machine:showGuideTwoClick()
            
        end
        
    end
end


--[[
    延迟回调
]]
function WolfSmashGuideBtnView:delayCallBack(time, func)
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

return WolfSmashGuideBtnView