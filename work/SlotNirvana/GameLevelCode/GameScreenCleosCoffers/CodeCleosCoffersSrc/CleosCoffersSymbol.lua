local CleosCoffersSymbol = class("CleosCoffersSymbol",util_require("Levels.BaseLevelDialog"))

-- 构造函数
function CleosCoffersSymbol:ctor()
    CleosCoffersSymbol.super.ctor(self)

    self.p_symbolType = -1
    self.m_ccbName    = ""
    self.m_animNode   = nil
end

function CleosCoffersSymbol:initDatas(_m_machine)
    self.m_machine = _m_machine
end

function CleosCoffersSymbol:changeSymbolCcb(_symbolType)
    self.p_symbolType = _symbolType
    self:upDateAnimNode()
end
--[[
    动画节点(spine|cocos)创建刷新
]]
function CleosCoffersSymbol:createAnimNode()
    if not self.m_animNode then
        local mainClass = self.m_machine
        local spineSymbolData = mainClass.m_configData:getSpineSymbol(self.p_symbolType)
        self.m_ccbName = mainClass:getSymbolCCBNameByType(mainClass, self.p_symbolType)
        -- 区分 spine 和 cocos
        if nil ~= spineSymbolData then
            self.m_animNode = util_spineCreate(self.m_ccbName,true,true)
        else
            self.m_animNode = util_createAnimation( string.format("%s.csb", self.m_ccbName) )
        end
        self:addChild(self.m_animNode)
    end
end

function CleosCoffersSymbol:upDateAnimNode()
    if self.m_animNode then
        local ccbName = self.m_machine:getSymbolCCBNameByType(self.m_machine, self.p_symbolType)
        if ccbName ~=  self.m_ccbName then
            self.m_animNode:removeFromParent()
            self.m_animNode = nil

            self:createAnimNode()
        end 
    else
        self:createAnimNode()
    end
end

function CleosCoffersSymbol:runAnim(animName,loop,func)
    self:createAnimNode()

    local mainClass = self.m_machine
    local spineSymbolData = mainClass.m_configData:getSpineSymbol(self.p_symbolType)

    if nil ~= spineSymbolData then
        util_spinePlay(self.m_animNode, animName, loop)
        if func ~= nil then
            util_spineEndCallFunc(self.m_animNode, animName, func)
        end
    else
        util_csbPlayForKey(self.m_animNode.m_csbAct, animName, loop, func)
    end
end

function CleosCoffersSymbol:getNodeSpine()
    return self.m_animNode
end

-- 播放动画
-- @return 返回是否播放Anim成功
function CleosCoffersSymbol:runAnim(animName,loop,func)
    self:createAnimNode()

    local mainClass = self.m_machine
    local spineSymbolData = mainClass.m_configData:getSpineSymbol(self.p_symbolType)

    if nil ~= spineSymbolData then
        util_spinePlay(self.m_animNode, animName, loop)
        if func ~= nil then
            util_spineEndCallFunc(self.m_animNode, animName, func)
        end
    else
        util_csbPlayForKey(self.m_animNode.m_csbAct, animName, loop, func)
    end
end

---
-- 获取动画持续时间
--
function CleosCoffersSymbol:getAnimDurationTime(animName)
    if animName == nil then
        return 0
    end
    -- printInfo("获取时间名字 %s",animName)
    local time=self.m_animNode:getAnimationDurationTime(animName)
    return time
end

-- 设置bonus上的钱
function CleosCoffersSymbol:setSymbolNodeBonusCoins( _curCoins)
    local curCoins = _curCoins

    local csbName = "Socre_CleosCoffers_Bonus_Coins.csb"

    local nodeScore = util_createAnimation(csbName)
    util_spinePushBindNode(self.m_animNode, "shuzi", nodeScore)

    nodeScore:runCsbAction("over", false)

    local sScore = util_formatCoinsLN(curCoins, 3)

    nodeScore:findChild("m_lb_coins"):setString(sScore)
    self:updateLabelSize({label=nodeScore:findChild("m_lb_coins"),sx=1.0,sy=1.0},142)
end

return CleosCoffersSymbol
