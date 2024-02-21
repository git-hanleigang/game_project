local CookieCrunchLoadingBar = class("CookieCrunchLoadingBar",util_require("CodeCookieCrunchSrc.CookieCrunchRightBar"))

--[[
    _data = {
        parent  = cc.Node,       --父节点
        jpIndex = 0,             --奖池索引    
    }
]]
function CookieCrunchLoadingBar:initUI()
    self:createCsbNode("CookieCrunch_LoadingBar.csb")
end

--[[
    状态相关
]]
function CookieCrunchLoadingBar:upDateFinishStateAnim(_playAnim)
    -- 模式 + (播动画:[liang, mie]  不播:[idle1, idle2])
    local isFree = self.m_model == self.MODEL.FREE

    local animPrefix = isFree and "free_" or "base_"
    if _playAnim then
        local animState = self.m_finishState and "liang" or "mie"
        local animName = string.format("%s%s", animPrefix, animState)
        self:runCsbAction(animName, false)
    else
        local animState = self.m_finishState and "idle2" or "idle1"
        local animName = string.format("%s%s", animPrefix, animState)
        self:runCsbAction(animName, false)
    end
end
--[[
    模式相关
]]
function CookieCrunchLoadingBar:upDateModelAnim(_playAnim)
    local isFree = self.m_model == self.MODEL.FREE

    if _playAnim then
        local animName = isFree and "base_free" or "free_base"
        self:runCsbAction(animName, false)
    else
        local animName = isFree and "free_idle1" or "base_idle1"
        self:runCsbAction(animName, false)
    end
end
return CookieCrunchLoadingBar