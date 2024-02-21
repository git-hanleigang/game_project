---
--xcyy
--2018年5月23日
--WolfSmashNewFreeBtnView.lua

local WolfSmashNewFreeBtnView = class("WolfSmashNewFreeBtnView",util_require("Levels.BaseLevelDialog"))
local PublicConfig = require "WolfSmashPublicConfig"

function WolfSmashNewFreeBtnView:initUI(machine)
    self.m_machine = machine
    self:createCsbNode("Socre_WolfSmash_xiugai_anniu.csb")
    self.m_Click = true
end

function WolfSmashNewFreeBtnView:setBottomEnabled(showIndex)
    self:findChild("Button_AUTO"):setVisible(showIndex == 1)
    self:findChild("WolfSmash_xiugai_anniu_6_2"):setVisible(showIndex == 1)
    self:findChild("Button_STOP"):setVisible(showIndex == 2)
    self:findChild("WolfSmash_xiugai_anniu_7_3"):setVisible(showIndex == 2)
end

function WolfSmashNewFreeBtnView:setClickState(isClick)
    self.m_Click = isClick
end

--默认按钮监听回调
function WolfSmashNewFreeBtnView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()
    if not self.m_Click then
        return
    end

    if name == "Button_AUTO" then
        self.m_machine:showAutoAllUi(true)
    elseif name == "Button_STOP" then
        self.m_machine:showAutoAllUi(false)
    end
end


--[[
    延迟回调
]]
function WolfSmashNewFreeBtnView:delayCallBack(time, func)
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

return WolfSmashNewFreeBtnView