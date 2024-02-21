local MiningManiaSymbol = class("MiningManiaSymbol",util_require("Levels.BaseLevelDialog"))


-- 构造函数
function MiningManiaSymbol:ctor()
    MiningManiaSymbol.super.ctor(self)

    self.m_symbolType = -1
    self.m_ccbName    = ""
    self.m_animNode   = nil
end

function MiningManiaSymbol:initDatas(_m_machine)
    self.m_machine   = _m_machine
end

function MiningManiaSymbol:changeSymbolCcb(_symbolType)
    self.m_symbolType = _symbolType
    self:upDateAnimNode()
end
--[[
    动画节点(spine|cocos)创建刷新
]]
function MiningManiaSymbol:createAnimNode()
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
function MiningManiaSymbol:upDateAnimNode()
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

function MiningManiaSymbol:runAnim(animName,loop,func)
    self:createAnimNode()

    local mainClass = self.m_machine
    local spineSymbolData = mainClass.m_configData:getSpineSymbol(self.m_symbolType)

    if nil ~= spineSymbolData then
        util_spinePlay(self.m_animNode, animName, loop)
        if func ~= nil then
            util_spineEndCallFunc(self.m_animNode, animName, func)
        end
    else
        util_csbPlayForKey(self.m_animNode.m_csbAct, animName, loop, func)
    end
end

function MiningManiaSymbol:getNodeSpine()
    return self.m_animNode
end

function MiningManiaSymbol:getCcbProperty(propName)
    local node = util_getChildByName(self.m_animNode,propName)
    return node
end

---
-- 获取动画持续时间
--
function MiningManiaSymbol:getAnimDurationTime(animName)
    if animName == nil then
        return 0
    end
    -- printInfo("获取时间名字 %s",animName)
    local time=self.m_animNode:getAnimationDurationTime(animName)
    return time
end

return MiningManiaSymbol
