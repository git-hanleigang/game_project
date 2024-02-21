local FlamingPompeiiTempSymbol = class("FlamingPompeiiTempSymbol", cc.Node)


-- 构造函数
function FlamingPompeiiTempSymbol:ctor()
    self.m_symbolType  = -1
    self.m_ccbName     = ""
    self.m_animNode    = nil
    self.m_curAnimName = ""
    self.m_curAnimLoop = nil
end

function FlamingPompeiiTempSymbol:initData_(_params)
    self.m_machine  = _params[1]
end

function FlamingPompeiiTempSymbol:removeTempSlotsNode()
    -- 防止在spine回调接口内执行移除逻辑时闪退问题
    self:setVisible(false)
    performWithDelay(self,function()
        self:removeFromParent()
    end,0)
end

function FlamingPompeiiTempSymbol:changeSymbolCcb(_symbolType)
    self.m_symbolType = _symbolType
    self:upDateAnimNode()
end
--[[
    动画节点(spine|cocos)创建刷新
]]
function FlamingPompeiiTempSymbol:createAnimNode()
    if not self.m_animNode then
        local mainClass = self.m_machine
        local spineSymbolData = mainClass.m_configData:getSpineSymbol(self.m_symbolType)
        self.m_ccbName = mainClass:getSymbolCCBNameByType(mainClass, self.m_symbolType)
        -- 区分 spine 和 cocos
        if nil ~= spineSymbolData then
            self.m_animNode = util_spineCreate(self.m_ccbName,true,true)
        else
            self.m_animNode = util_createAnimation( string.format("%s.csb", self.m_ccbName) )
        end
        self:addChild(self.m_animNode)
    end
end
function FlamingPompeiiTempSymbol:upDateAnimNode()
    if self.m_animNode then
        local ccbName = self.m_machine:getSymbolCCBNameByType(self.m_machine, self.m_symbolType)
        if ccbName ~=  self.m_ccbName then
            self.m_animNode:removeFromParent()
            self.m_animNode = nil

            self:createAnimNode()
        end 
    else
        self:createAnimNode()
    end
end
--[[
    获得动画节点
]]
function FlamingPompeiiTempSymbol:checkLoadCCbNode()
    self:createAnimNode()
    return self.m_animNode
end
function FlamingPompeiiTempSymbol:getCCBNode()
    return self.m_animNode
end
--[[
    时间线相关
]]
function FlamingPompeiiTempSymbol:runLineAnim()
    local animName = self:getLineAnimName()
    self:runAnim(animName, true)
end
function FlamingPompeiiTempSymbol:getLineAnimName()
    if self.m_lineAnimName ~= nil then
        return self.m_lineAnimName
    else
        return "actionframe"
    end
end
function FlamingPompeiiTempSymbol:runIdleAnim()
    if nil == self.m_idleAnimName then
        self:runAnim("idleframe", false)
    else
        self:runAnim(self.m_lineAnimName, false)
    end
end
function FlamingPompeiiTempSymbol:runAnim(animName,loop,func)
    self:createAnimNode()
    if not self.m_animNode then
        if func ~= nil then
            func()
        end
        local sMsg = strnig.format("[FlamingPompeiiTempSymbol:runAnim] m_symbolType=(%d)", self.m_symbolType)
        error(sMsg)
        return
    end
    
    local mainClass = self.m_machine
    local spineSymbolData = mainClass.m_configData:getSpineSymbol(self.m_symbolType)

    self.m_curAnimName = animName
    self.m_curAnimLoop = loop
    if nil ~= spineSymbolData then
        util_spinePlay(self.m_animNode, animName, loop)
        if func ~= nil then
            util_spineEndCallFunc(self.m_animNode, animName, func)
        end
    else
        util_csbPlayForKey(self.m_animNode.m_csbAct, animName, loop, func)
    end
end

--[[
    获取动画节点上面的子节点
]]
function FlamingPompeiiTempSymbol:getCcbProperty(propName)
    if self.m_animNode == nil then
        return nil
    end

    if "function" == type(self.m_animNode.findChild) then
        return self.m_animNode:findChild(propName)
    end

    return nil
end
--[[
    获取时间线的长度
]]
function FlamingPompeiiTempSymbol:getAniamDurationByName(_animName)
    local mainClass = self.m_machine
    local spineSymbolData = mainClass.m_configData:getSpineSymbol(self.m_symbolType)

    local time = 0
    if nil ~= spineSymbolData then
        time = 0
    else
        time = util_csbGetAnimTimes(self.m_animNode.m_csbAct, _animName)
    end

    return time
end

return FlamingPompeiiTempSymbol