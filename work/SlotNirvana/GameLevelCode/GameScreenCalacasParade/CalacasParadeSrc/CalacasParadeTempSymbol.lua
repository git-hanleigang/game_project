-- 临时图标效果
local CalacasParadeTempSymbol = class("CalacasParadeTempSymbol", cc.Node)

-- 构造函数
function CalacasParadeTempSymbol:ctor()
    -- 不能用 p_symbolType CT释放节点时有变量名层判断
    self.m_symbolType  = -1
    self.m_ccbName     = ""
    self.m_animNode    = nil
    self.m_currAnimName = ""
    self.m_slotAnimaLoop = nil
    self.m_isLastSymbol = true
end

function CalacasParadeTempSymbol:initData_(_initData)
    --初始化一些属性
    --[[
        _initData = {
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

function CalacasParadeTempSymbol:removeTempSlotsNode()
    -- 防止在spine回调接口内执行移除逻辑时闪退问题
    self:setVisible(false)
    performWithDelay(self,function()
        self:removeFromParent()
    end,0)
end

function CalacasParadeTempSymbol:changeSymbolCcb(_symbolType)
    self.m_symbolType = _symbolType
    self:registerAniamCallBackFun(nil)
    self:upDateAnimNode()
end
--[[
    动画节点(spine|cocos)创建刷新
]]
function CalacasParadeTempSymbol:createAnimNode()
    if not self.m_animNode then
        local mainClass = self.m_machine
        local spineSymbolData = mainClass.m_configData:getSpineSymbol(self.m_symbolType)
        self.m_ccbName = mainClass:getSymbolCCBNameByType(mainClass, self.m_symbolType)
        -- 区分 spine 和 cocos
        if nil ~= spineSymbolData then
            self.m_animNode = util_spineCreate(self.m_ccbName, true, true)
        else
            self.m_animNode = util_createAnimation( string.format("%s.csb", self.m_ccbName) )
        end
        self:addChild(self.m_animNode)
    end
end
function CalacasParadeTempSymbol:upDateAnimNode()
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
function CalacasParadeTempSymbol:checkLoadCCbNode()
    self:createAnimNode()
    return self.m_animNode
end
function CalacasParadeTempSymbol:getCCBNode()
    return self.m_animNode
end
--[[
    时间线相关
]]
--执行混合动作
function CalacasParadeTempSymbol:runMixAni(aniName,loop,func,curAniName,time)
    if nil ~= self.m_machine.m_configData:getSpineSymbol(self.m_symbolType) then
        local curAniName = curAniName or self.m_currAnimName
        local time       = time or 0.2
        util_spineMix(self.m_animNode,curAniName,aniName,time)
    end
    self:runAnim(aniName,loop,func)
end
function CalacasParadeTempSymbol:runAnim(animName,loop,func)
    self:createAnimNode()
    if not self.m_animNode then
        if func ~= nil then
            func()
        end
        local sMsg = strnig.format("[CalacasParadeTempSymbol:runAnim] m_symbolType=(%d)", self.m_symbolType)
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
function CalacasParadeTempSymbol:registerAniamCallBackFun(_fun)
    self.m_fnRunAnimCallBack = _fun
end
--[[
    获取动画节点上面的子节点
]]
function CalacasParadeTempSymbol:getCcbProperty(propName)
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
function CalacasParadeTempSymbol:getAniamDurationByName(_animName)
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

return CalacasParadeTempSymbol