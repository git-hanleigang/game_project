---
--island
--2018年5月3日
--SlotsAnimNode.lua
--
-- slotsnode 动画节点

local SlotsAnimNode = class("SlotsAnimNode",cc.Node)

SlotsAnimNode.p_symbolType = nil  -- 信号类型
SlotsAnimNode.m_csbNode = nil
SlotsAnimNode.m_csbAct = nil
SlotsAnimNode.m_csbPath = nil

function SlotsAnimNode:create()
    local slotsNode = SlotsAnimNode.new()
    return slotsNode
end

-- 构造函数
function SlotsAnimNode:ctor()
    self.m_csbNode = nil
    self.m_csbAct = nil

    local function onNodeEvent(eventName)
        if "enter" == eventName then
            self:onEnter()
        elseif "exit" == eventName then
            self:onExit()
        end
    end
    self:registerScriptHandler(onNodeEvent)
end

---
--
function SlotsAnimNode:onEnter()

end
-- 播放默认的动画，
function SlotsAnimNode:runDefaultAnim()
    util_csbPauseForIndex(self:getCsbAct(true),0)
end

--
function SlotsAnimNode:onExit()

end

function SlotsAnimNode:isSameCCBName(ccbName)
    return self.m_ccbName == ccbName
end
---
-- 加载ccb 
-- @param ccbName string ccb名字
--
function SlotsAnimNode:loadCCBNode(ccbName,symbolType)
    self.m_ccbName = ccbName
    self.p_symbolType = symbolType
    self.m_csbPath=ccbName..".csb"
    self.m_csbNode,self.m_csbAct=util_csbCreate(self.m_csbPath)
    self.m_csbAct:retain()
    self:addChild(self.m_csbNode)
end

--获取动画播放时间线
function SlotsAnimNode:getCsbAct(isReset)
    if isReset then
        self.m_csbNode:stopAction(self.m_csbAct)
        self.m_csbNode:runAction(self.m_csbAct)
    end
    return self.m_csbAct
end

function SlotsAnimNode:getCurAnimRunTimes()
    return util_csbGetDuration(self:getCsbAct())
end

function SlotsAnimNode:getCcbProperty(propName)
    local node = util_getChildByName(self.m_csbNode,propName)
    return node
end

---
-- 播放动画
-- @return 返回是否播放Anim成功
function SlotsAnimNode:runAnim(animName,loop,func)
    util_csbPlayForKey(self:getCsbAct(true),animName,loop,func)
    return true
end

function SlotsAnimNode:getCurrentFrame()
    local csbAct=self:getCsbAct()
    local curIndex=csbAct:getCurrentFrame()
    return curIndex
end

function SlotsAnimNode:runFrameForIndex(index)
    local csbAct=self:getCsbAct(true)
    util_csbPlayForKey(csbAct,"actionframe",false,nil)
    csbAct:setCurrentFrame(index)
    return true
end

---
-- 获取动画持续时间
--
function SlotsAnimNode:getAnimDurationTime(animName)
    if animName == nil then
        return 0
    end
    -- printInfo("获取时间名字 %s",animName)
    local time=util_csbGetAnimTimes(self:getCsbAct(),animName)
    return time
end
function SlotsAnimNode:clear()
    if not tolua.isnull(self.m_csbAct) then
        self.m_csbNode = nil
        self.m_csbAct:release()
        self.m_csbAct = nil
    end
    
end

--[[
    重置时间线
]]
function SlotsAnimNode:resetTimeLine()
    if tolua.isnull(self.m_csbAct) then
        return
    end
    util_resetCsbAction(self.m_csbAct)
end

return SlotsAnimNode