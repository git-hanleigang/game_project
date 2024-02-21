local CookieCrunchRightBar = class("CookieCrunchRightBar",util_require("Levels.BaseLevelDialog"))

CookieCrunchRightBar.MODEL = {
    BASE = "base",
    FREE = "free",
}
--[[
    _data = {
        barIndex = 1,     -- 右边栏从下到上的索引
        jpIndex  = 0,     -- <=0 : 非jackpot, >0 : jackpot

    }
]]
function CookieCrunchRightBar:initDatas(_machine, _data)
    self.m_machine  = _machine
    self.m_initData = _data
    -- 完成状态 是否已满足进度 可以高亮
    self.m_finishState = false
    -- 模式
    self.m_model    = self.MODEL.BASE
end

function CookieCrunchRightBar:resetShow()
    self:setFinishState(false)
    self:setModel(self.MODEL.BASE)

    self:upDateFinishStateAnim(false)
    self:upDateModelAnim(false)
end
--[[
    状态相关
]]
function CookieCrunchRightBar:setFinishState(_bool)
    self.m_finishState = _bool
end
function CookieCrunchRightBar:upDateFinishStateAnim(_playAnim)
    
end
--[[
    模式相关
]]
function CookieCrunchRightBar:setModel(_sModel)
    self.m_model    = _sModel
end
function CookieCrunchRightBar:upDateModelAnim(_playAnim)
    
end


return CookieCrunchRightBar