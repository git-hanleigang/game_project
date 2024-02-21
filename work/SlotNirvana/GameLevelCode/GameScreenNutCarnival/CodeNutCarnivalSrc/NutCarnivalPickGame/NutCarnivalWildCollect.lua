--[[
    花生堆
    处理收集数量和等级
]]
local NutCarnivalWildCollect = class("NutCarnivalWildCollect", cc.Node)
local PublicConfig = require "NutCarnivalPublicConfig"

NutCarnivalWildCollect.Order = {
    Peanut   = 50,
    FeedBack = 60,
}

function NutCarnivalWildCollect:initData_(_machine)
    self.m_machine = _machine

    self:initUI()
end
function NutCarnivalWildCollect:initUI(_machine)
    self.m_collectCfg = {0, 25, 50}
    self.m_collectCount = 0

    local spineName = "NutCarnival_pick_shouji"
    self.m_spine    = util_spineCreate(spineName, true, true)
    self:addChild(self.m_spine, self.Order.Peanut)

    -- self.m_feedbackAnim = util_createAnimation("NutCarnival_fankui.csb")
    -- self:addChild(self.m_feedbackAnim, self.Order.FeedBack)
    -- self.m_feedbackAnim:setVisible(false)

    self.m_upGradeAnim = util_createAnimation("NutCarnival_fankui.csb")
    self:addChild(self.m_upGradeAnim, self.Order.FeedBack)
    self.m_upGradeAnim:setVisible(false)
end
function NutCarnivalWildCollect:initFeedbackAnim(_feedbackAnim)
    self.m_feedbackAnim = _feedbackAnim
end

function NutCarnivalWildCollect:setCollectCount(_newCount)
    self.m_collectCount = _newCount
end

--[[
    时间线
]]
function NutCarnivalWildCollect:playIdleAnim()
    local curLevel = self:getCollectLevel(self.m_collectCount)
    local animName = string.format("idleframe%d", curLevel)
    util_spinePlay(self.m_spine, animName, true)
end
function NutCarnivalWildCollect:playCollectAnim(_fun)
    --爆点
    self.m_feedbackAnim:setVisible(true)
    self.m_feedbackAnim:runCsbAction("fankui1", false, function()
        self.m_feedbackAnim:setVisible(false)
    end)
    --花生堆抖动
    local curLevel = self:getCollectLevel(self.m_collectCount)
    local animName = string.format("fankui%d", curLevel)
    util_spinePlay(self.m_spine, animName, false)
    self.m_machine:levelPerformWithDelay(self, 12/30, function()
        _fun()
    end)
end

--升级
function NutCarnivalWildCollect:playUpGradeAnim(_startLevel, _finalLevel, _fun)
    local offsetLevel = _finalLevel - _startLevel
    if offsetLevel <= 0 then
    	_fun()
    	return
    end
    --爆点
    self.m_upGradeAnim:setVisible(true)
    self.m_upGradeAnim:runCsbAction("shengji", false, function()
        self.m_upGradeAnim:setVisible(false)
    end)
    --花生堆变大
    local animName = string.format("switch%d", _finalLevel-1)
    if offsetLevel > 1 then
        animName = string.format("switch3")
    end
    util_spinePlay(self.m_spine, animName, false)
    self.m_machine:levelPerformWithDelay(self, 15/30, function()
        _fun()
    end)
    local soundKey  = string.format("sound_NutCarnival_wild_collectUpGrade_%d_%d", _startLevel, _finalLevel)
    local soundName = PublicConfig[soundKey]
    gLobalSoundManager:playSound(soundName)
end

function NutCarnivalWildCollect:playSwitchAnim(_fun)
    local curLevel = self:getCollectLevel(self.m_collectCount)
    local animName = string.format("switch%d", curLevel-1)
    util_spinePlay(self.m_spine, animName, false)
    self.m_machine:levelPerformWithDelay(self, 15/30, function()
        _fun()
    end)
end

--[[
    收集数据
]]
function NutCarnivalWildCollect:initCollectData(_data)
    self.m_collectCfg = _data
end
function NutCarnivalWildCollect:getCollectLevel(_count)
    local collectLevel = 1
    for _level,_collectCount in ipairs(self.m_collectCfg) do
        if _count >= _collectCount then
            collectLevel = _level
        else
            break
        end
    end
    return collectLevel
end
function NutCarnivalWildCollect:getCollectCountByLevel(_collectLevel)
    local count = 0
    for _level,_collectCount in ipairs(self.m_collectCfg) do
        if _collectLevel >= _level then
            count = _collectCount
        else
            break
        end
    end
    return count
end

return NutCarnivalWildCollect