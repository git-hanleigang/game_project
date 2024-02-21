local PenguinsBoomsTempSymbol = class("PenguinsBoomsTempSymbol", cc.Node)


-- 构造函数
function PenguinsBoomsTempSymbol:ctor()
    -- 不能用 p_symbolType
    self.m_symbolType  = -1
    self.m_ccbName     = ""
    self.m_animNode    = nil
    self.m_currAnimName = ""
    self.m_slotAnimaLoop = nil
    self.m_isLastSymbol = true
end

function PenguinsBoomsTempSymbol:initData_(_initData)
    --初始化一些属性
    --[[
        _initData = {
			symbolType = 0,   --不能使用该数据参与任何逻辑, 用 m_symbolType  
            iCol       = 1,
            iRow       = 1,
			machine    = self,
        }
    ]]
    self.m_machine  = _initData.machine
    if nil ~= _initData.iCol then
        self.p_cloumnIndex = _initData.iCol
    end
    if nil ~= _initData.iRow then
        self.p_rowIndex = _initData.iRow
    end
        
end

function PenguinsBoomsTempSymbol:removeTempSlotsNode()
    -- 防止在spine回调接口内执行移除逻辑时闪退问题
    self:setVisible(false)
    performWithDelay(self,function()
        self:removeFromParent()
    end,0)
end

function PenguinsBoomsTempSymbol:changeSymbolCcb(_symbolType)
    self.m_symbolType = _symbolType
    self:registerAniamCallBackFun(nil)
    self:upDateAnimNode()
end
--[[
    动画节点(spine|cocos)创建刷新
]]
function PenguinsBoomsTempSymbol:createAnimNode()
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
function PenguinsBoomsTempSymbol:upDateAnimNode()
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
function PenguinsBoomsTempSymbol:checkLoadCCbNode()
    self:createAnimNode()
    return self.m_animNode
end
function PenguinsBoomsTempSymbol:getCCBNode()
    return self.m_animNode
end
--[[
    时间线相关
]]
function PenguinsBoomsTempSymbol:runLineAnim()
    local animName = self:getLineAnimName()
    self:runAnim(animName, true)
end
function PenguinsBoomsTempSymbol:getLineAnimName()
    if self.m_lineAnimName ~= nil then
        return self.m_lineAnimName
    else
        return "actionframe"
    end
end
function PenguinsBoomsTempSymbol:runIdleAnim()
    if nil == self.m_idleAnimName then
        self:runAnim("idleframe", false)
    else
        self:runAnim(self.m_lineAnimName, false)
    end
end
function PenguinsBoomsTempSymbol:runAnim(animName,loop,func)
    self:createAnimNode()
    if not self.m_animNode then
        if func ~= nil then
            func()
        end
        local sMsg = strnig.format("[PenguinsBoomsTempSymbol:runAnim] m_symbolType=(%d)", self.m_symbolType)
        error(sMsg)
        return
    end
    
    local mainClass = self.m_machine
    local spineSymbolData = mainClass.m_configData:getSpineSymbol(self.m_symbolType)

    self.m_currAnimName = animName
    self.m_slotAnimaLoop = loop
    if nil ~= spineSymbolData then
        util_spinePlay(self.m_animNode, animName, loop)
        if func ~= nil then
            util_spineEndCallFunc(self.m_animNode, animName, func)
        end
    else
        util_csbPlayForKey(self.m_animNode.m_csbAct, animName, loop, func)
    end
    if self.m_fnRunAnimCallBack then
        self.m_fnRunAnimCallBack(self)
    end
end
function PenguinsBoomsTempSymbol:registerAniamCallBackFun(_fun)
    self.m_fnRunAnimCallBack = _fun
end
--[[
    获取动画节点上面的子节点
]]
function PenguinsBoomsTempSymbol:getCcbProperty(propName)
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
function PenguinsBoomsTempSymbol:getAniamDurationByName(_animName)
    local mainClass = self.m_machine
    local spineSymbolData = mainClass.m_configData:getSpineSymbol(self.m_symbolType)

    local time = 0
    if nil ~= spineSymbolData then
        time = self.m_animNode:getAnimationDurationTime(_animName)
    else
        time = util_csbGetAnimTimes(self.m_animNode.m_csbAct, _animName)
    end

    return time
end

return PenguinsBoomsTempSymbol