--[[
    临时图标 
        用于播放一些在小块时间线内的临时效果,使用完毕后 调用 removeSymbolAniNode 直接删除
        方法名称和参数尽量和小块保持一致方便使用
        创建方法:
            local tempSymbol = util_createView("Levels.SlotsNode", {machine = self})
	        tempSymbol:changeSymbolCcb(TAG_SYMBOL_TYPE.SYMBOL_SCATTER, "Socre_tempLevel_Scatter", true)
]]
local SymbolAniNode = class("SymbolAniNode", cc.Node)

-- 构造函数
function SymbolAniNode:ctor()
    -- 不能用 p_symbolType 关卡底层清理释放小块时有变量名称判断
    self.m_symbolType    = -1
    self.m_ccbName       = ""
    self.m_bSpine        = false
    self.m_animNode      = nil
    self.m_currAnimName  = ""
    self.m_slotAnimaLoop = nil
end

function SymbolAniNode:removeSymbolAniNode()
    -- 防止在spine回调接口内执行移除逻辑时闪退问题
    self:setVisible(false)
    performWithDelay(self,function()
        self:removeFromParent()
    end,0)
end

function SymbolAniNode:changeSymbolCcb(_symbolType, _ccbName, _bSpine)
    self.m_symbolType = _symbolType
    self.m_bSpine =_bSpine

    self:registerAniamCallBackFun(nil)
    self:upDateAnimNode(_ccbName)
end
--[[
    动画节点(spine|cocos)创建刷新
]]
function SymbolAniNode:createAnimNode(_ccbName)
    if not self.m_animNode then
        self.m_ccbName = _ccbName
        -- 区分 spine 和 cocos
        if self.m_bSpine then
            self.m_animNode = util_spineCreate(self.m_ccbName, true, true)
        else
            self.m_animNode = util_createAnimation(string.format("%s.csb", self.m_ccbName))
        end
        self:addChild(self.m_animNode)
    end
end
function SymbolAniNode:upDateAnimNode(_ccbName)
    if self.m_animNode then
        if _ccbName ~=  self.m_ccbName then
            self.m_animNode:removeFromParent()
            self.m_animNode = nil
            self:createAnimNode(_ccbName)
        end 
    else
        self:createAnimNode(_ccbName)
    end
end
--[[
    获得节点
]]
function SymbolAniNode:checkLoadCCbNode()
    return self:getCCBNode()
end
function SymbolAniNode:getCCBNode()
    return self.m_animNode
end
--获取动画节点上面的子节点
function SymbolAniNode:getCcbProperty(propName)
    if self.m_animNode == nil then
        return nil
    end

    if "function" == type(self.m_animNode.findChild) then
        return self.m_animNode:findChild(propName)
    end

    return nil
end

--[[
    时间线相关
]]
function SymbolAniNode:runAnim(animName,loop,func)
    if not self.m_animNode then
        if func ~= nil then
            func()
        end
        local sMsg = strnig.format("[SymbolAniNode:runAnim] m_symbolType=(%d)", self.m_symbolType)
        error(sMsg)
        return
    end

    self.m_currAnimName = animName
    self.m_slotAnimaLoop = loop
    if self.m_bSpine then
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
--获取时间线的长度
function SymbolAniNode:getAniamDurationByName(_animName)
    local time = 0
    if self.m_bSpine then
        time = self.m_animNode:getAnimationDurationTime(_animName)
    else
        time = util_csbGetAnimTimes(self.m_animNode.m_csbAct, _animName)
    end

    return time
end

--[[
    注册回调
]]
function SymbolAniNode:registerAniamCallBackFun(_fun)
    self.m_fnRunAnimCallBack = _fun
end

function SymbolAniNode:resetTimeAnim()
    if self.m_bSpine then
        self.m_animNode:resetAnimation()
    else
        util_resetCsbAction(self.m_animNode.m_csbAct)
    end
    
end
return SymbolAniNode