--[[
Author: dinghansheng dinghansheng@luckxcyy.com
Date: 2022-06-28 11:42:05
LastEditors: dinghansheng dinghansheng@luckxcyy.com
LastEditTime: 2022-06-28 11:42:09
FilePath: /SlotNirvana/src/views/gameviews/GameTopWheelUP.lua
Description: 这是处理水 spine
--]]
local GameTopWheelUP = class("GameTopWheelUP",BaseView)

function GameTopWheelUP:ctor()
    GameTopWheelUP.super.ctor(self)
end

function GameTopWheelUP:initUI()
    GameTopWheelUP.super.initUI(self)
    self.m_curPercent = 100
    self:initView()
end

function GameTopWheelUP:initView()
    --self:initClippNode()
    self.m_progress:setPercent(self.m_curPercent)
end

function GameTopWheelUP:getCsbName()
    return "GameNode/GameTopWheelUp.csb"
end

function GameTopWheelUP:initCsbNodes()
    self.m_nodeMask = self:findChild("node_mask")
    self.m_progress = self:findChild("LoadingBar_1")
end

function GameTopWheelUP:initClippNode()
    local clippShape = util_createSprite("GameNode/ui/lunpan_mask.png")
    local clippNode = cc.ClippingNode:create()
    
    clippNode:setStencil(clippShape)
    clippNode:setInverted(false)
    clippNode:setAlphaThreshold(0)
    local waterSpine = util_spineCreate("GameNode/spine/jindutiao_shui",true,true, 1)
    if waterSpine then
        self.m_waterSpine = waterSpine
        util_spinePlay(waterSpine,"animation",true)
        clippNode:addChild(self.m_waterSpine)
        
        --self.m_waterSpine:setPosition(cc.p(0,40))
        self.m_nodeMask:addChild(clippNode)
    end
end

function GameTopWheelUP:updateLeftTime()
    if self.m_curPercent > 100 then
        self:clearScheduler()
        return
    end
    self.m_curPercent = self.m_curPercent + 1
    if self.m_curPercent >= 100 then
        self.m_curPercent = 100
    end
    self.m_progress:setPercent(self.m_curPercent)
end

--停掉定时器
function GameTopWheelUP:clearScheduler()
    if self.m_leftTimeScheduler then
        self:stopAction(self.m_leftTimeScheduler)
        self.m_leftTimeScheduler = nil
        self.m_curPercent = 90
    end
end

-- 进度长满的动效
function GameTopWheelUP:progressAnimation(_call)
    local actionList = {}
    
    actionList[#actionList+1] = cc.CallFunc:create(function ()
        self:updateLeftTime()
        self.m_leftTimeScheduler = schedule(self, handler(self, self.updateLeftTime), 0.1)
    end)
    actionList[#actionList+1] = cc.DelayTime:create(1.5)
    actionList[#actionList+1] = cc.CallFunc:create(function ()
        if _call then
            _call()
        end
    end)
    local seq = cc.Sequence:create(actionList)
    self:runActionEx(seq)
end
return GameTopWheelUP
