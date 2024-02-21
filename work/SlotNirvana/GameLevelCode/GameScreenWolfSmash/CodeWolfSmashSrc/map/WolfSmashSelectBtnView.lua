---
--xcyy
--2018年5月23日
--WolfSmashSelectBtnView.lua

local WolfSmashSelectBtnView = class("WolfSmashSelectBtnView",util_require("Levels.BaseLevelDialog"))
local PublicConfig = require "WolfSmashPublicConfig"
local CURCLICKTYPE = {
    PLAY = 1,
    RANDOM = 2,
    RESET = 3,
    PIG = 4,
    STOP = 5,
}

function WolfSmashSelectBtnView:initUI(machine,index)
    self.m_machine = machine
    self:createCsbNode("WolfSmash_yindao_anniu.csb")
    -- self.m_Click = true
    self:setBtnVisibleForIndex(index)
    self.index = index
    self:showBtnForIndex()
end

function WolfSmashSelectBtnView:setBtnVisibleForIndex(index)
    for i=1,3 do
        if i == index then
            self:findChild("Button_"..i):setVisible(true)
            self:findChild("ef_sg"..i):setVisible(true)
        else
            self:findChild("Button_"..i):setVisible(false)
            self:findChild("ef_sg"..i):setVisible(false)
        end
        
    end
    -- if index == 1 then
        
    -- elseif index == 2 then
    --     self:findChild("Button_3"):setVisible(true)
    -- elseif index == 3 then
    --     self:findChild("Button_2"):setVisible(true)
    -- end
end

function WolfSmashSelectBtnView:showBtnForStart()
    self:runCsbAction("start",false,function ()
        self:runCsbAction("idleframe",true)
    end)
end

function WolfSmashSelectBtnView:showBtnForIndex()
    self:runCsbAction("idleframe",true)
end

function WolfSmashSelectBtnView:hideBtnForIndex()
    self:runCsbAction("idle")
end

function WolfSmashSelectBtnView:setBottomEnabled(isEnabled)
    self:findChild("Button_"..self.index):setEnabled(isEnabled)
    if isEnabled then
        self:showBtnForIndex()
    else
        self:hideBtnForIndex()
    end
end

--默认按钮监听回调
function WolfSmashSelectBtnView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()
    if not self.m_machine.m_Click or self.m_machine.curClickType == CURCLICKTYPE.PLAY then
        return
    end

    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_WolfSmash_click)
    if name == "Button_2" then
        self.m_machine:showPlayClick()
    elseif name == "Button_1" then         --点击随机按钮
        self.m_machine:showRandomClick()
    elseif name == "Button_3" then          --点击重置按钮
        self.m_machine:showResetClick()
    end
end


--[[
    延迟回调
]]
function WolfSmashSelectBtnView:delayCallBack(time, func)
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

return WolfSmashSelectBtnView