-- 跳过图层
local PenguinsBoomsSkip = class("PenguinsBoomsSkip",util_require("Levels.BaseLevelDialog"))

function PenguinsBoomsSkip:initUI(_data)
    --[[
        _data = {
            machine        = machine,
            skipEffectNode = cc.Node
        }
    ]]
    self.m_machine        = _data.machine
    self.m_skipEffectNode = _data.skipEffectNode
    -- 点击跳过时的回调
    self.m_skipCallBack = nil

    self:createCsbNode("PenguinsBooms_skip.csb")

    self:addClick(self:findChild("Panel_skip"))
end

--执行下一步流程
function PenguinsBoomsSkip:runNext(_time, _fun)
    if not self:isVisible() then
        print("[PenguinsBoomsSkip:runNext] 不在执行延时回调")
        return
    end

    local waitNode = cc.Node:create()
    self.m_skipEffectNode:addChild(waitNode)
    performWithDelay(waitNode,function()
        waitNode:removeFromParent()
        _fun()
    end, _time)
end
--[[
    点击事件
]]
function PenguinsBoomsSkip:clickFunc(sender)
    self:skipPanelClickCallBack()
end

function PenguinsBoomsSkip:skipPanelClickCallBack()
    if self.m_skipCallBack then
        self.m_skipCallBack()
    end
end

-- 设置跳过后的回调
function PenguinsBoomsSkip:setSkipCallBack(_fun)
    self.m_skipCallBack = _fun
end
function PenguinsBoomsSkip:clearSkipCallBack()
    self.m_skipEffectNode:removeAllChildren()
    self.m_skipCallBack = nil
end

return PenguinsBoomsSkip