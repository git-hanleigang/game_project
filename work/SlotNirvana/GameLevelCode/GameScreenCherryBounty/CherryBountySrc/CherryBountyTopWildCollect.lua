--[[
    wild收集栏
]]
local CherryBountyTopWildCollect = class("CherryBountyTopWildCollect", cc.Node)
local PublicConfig = require "CherryBountyPublicConfig"

function CherryBountyTopWildCollect:initData_(_data)
    self.m_data = _data
    self:initUI()
end
function CherryBountyTopWildCollect:initUI(_machine)
    self.m_machine  = _machine
    self.m_curLevel = 1
    self.m_maxLevel = 6


    self.m_spine = util_spineCreate("CherryBounty_xinxiqu_shoujiqu", true, true)
    self:addChild(self.m_spine)
end

function CherryBountyTopWildCollect:setCurLevel(_level)
    self.m_curLevel = _level
end
function CherryBountyTopWildCollect:getCurLevel()
    return self.m_curLevel
end


--时间线
function CherryBountyTopWildCollect:playSpineAnim(_name, _bLoop, _fun)
    util_spinePlay(self.m_spine, _name, _bLoop)
    if _fun then
        util_spineEndCallFunc(self.m_spine,  _name, _fun)
    end
end
--时间线-idle
function CherryBountyTopWildCollect:playIdleAnim(_level)
    local level = _level or self.m_curLevel
    local animName = string.format("idle%d", level)
    self:playSpineAnim(animName, true)
end
--时间线-收集
function CherryBountyTopWildCollect:playCollectAnim(_level, _fun)
    local level = _level or self.m_curLevel
    local animName = string.format("shouji%d", level)
    self:playSpineAnim(animName, false, function()
        self:playIdleAnim(level)
        _fun()
    end)
end
--时间线-升级
function CherryBountyTopWildCollect:playUpGradeAnim(_level, _fun)
    local level     = _level or self.m_curLevel
    local lastLevel = level-1
    local animName = string.format("shengji%dto%d", lastLevel, level)
    self:playSpineAnim(animName, false, function()
        self:playIdleAnim(level)
        _fun()
    end)
end
--时间线-触发特殊选择
function CherryBountyTopWildCollect:playTriggerAnim(_level, _fun)
    local level    = _level or self.m_curLevel
    local maxLevel = 6 
    local triggerAnim = "actionframe"
    if level >= maxLevel then
        self:playSpineAnim(triggerAnim, false, function()
            self:playIdleAnim(level)
            _fun()
        end)
    else
        local animName = string.format("shengji%dto%d", level, maxLevel)
        self:playSpineAnim(animName, false, function()
            self:playTriggerAnim(maxLevel, _fun)
        end)
    end
end


return CherryBountyTopWildCollect