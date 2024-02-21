-- 袋鼠角色
local KangaPocketsRoleSpine = class("KangaPocketsRoleSpine", cc.Node)
local KangaPocketsPublicConfig = require "KangaPocketsPublicConfig"

function KangaPocketsRoleSpine:initData_(_params)
    self.m_data = _params

    self:initUI()
end
function KangaPocketsRoleSpine:initUI()
    self.m_spine = util_spineCreate("KangaPockets_juese",true,true)
    self:addChild(self.m_spine)
end
--常态
function KangaPocketsRoleSpine:playIdleAnim(_lastIdleName)
    local defaultName = "idleframe"
    local idleName    = defaultName
    if _lastIdleName == defaultName then
        idleName    = (1 == math.random(1, 2)) and "idleframe2" or "idleframe3"
    end
    util_spinePlay(self.m_spine, idleName, false)
    util_spineEndCallFunc(self.m_spine, idleName, function()
        self:playIdleAnim(idleName)
    end)
end

--预告
function KangaPocketsRoleSpine:playYuGaoAnim()
    local animName = "actionframe_yugao"
    util_spinePlay(self.m_spine, animName, false)
    util_spineEndCallFunc(self.m_spine, animName, function()
        self:playIdleAnim("")
    end)
end

--收集特殊BONUS之前播放
function KangaPocketsRoleSpine:playCollectBonusYuGaoAnim(_fun)
    local animName = "actionframe_yugao2"
    util_spinePlay(self.m_spine, animName, false)
    util_spineEndCallFunc(self.m_spine, animName, function()
        self:playIdleAnim("")
        if "function" == type(_fun) then
            _fun()
        end
    end)
end

--base或者free界面收集金币到袋鼠口袋 等金币csb播放到21帧时 开始播放这个时间线
function KangaPocketsRoleSpine:playCollectBonusSymbolStartAnim(_fun)
    performWithDelay(self,function()
        util_spinePlay(self.m_spine, "actionframe_shouji", false)
        util_spineEndCallFunc(self.m_spine, "actionframe_shouji", function()
            self:playIdleAnim("")
            if "function" == type(_fun) then
                _fun()
            end
        end)
    end, 21/60)
end

--[[
    freeStart弹板相关
]]
-- 主界面角色离场
function KangaPocketsRoleSpine:playFreeStartLeaveAnim(_fun)
    gLobalSoundManager:playSound(KangaPocketsPublicConfig.sound_KangaPockets_RoleSpine_FreeStartLeave)
    local animName = "over"
    util_spinePlay(self.m_spine, animName, false)
    util_spineEndCallFunc(self.m_spine, animName, function()
        if "function" == type(_fun) then
            _fun()
        end
    end)
end
function KangaPocketsRoleSpine:playFreeStartCollectStartAnim(_fun)
    util_spinePlay(self.m_spine, "actionframe_guochang", false)
    util_spineEndCallFunc(self.m_spine, "actionframe_guochang", function()
        util_spinePlay(self.m_spine, "idleframe", true)
        if "function" == type(_fun) then
            _fun()
        end
    end)
end
function KangaPocketsRoleSpine:playFreeStartCollectAnim(_fun)
    util_spinePlay(self.m_spine, "actionframe_shouji2", false)
    util_spineEndCallFunc(self.m_spine, "actionframe_shouji2", function()
        self:playIdleAnim("")
        if "function" == type(_fun) then
            _fun()
        end
    end)
end
function KangaPocketsRoleSpine:playFreeStartCollectOverAnim(_fun, _fun2)
    local animName = "over"
    util_spinePlay(self.m_spine, animName, false)
    performWithDelay(self, _fun, 27/30)
    util_spineEndCallFunc(self.m_spine, animName, function()
        _fun2()
    end)
end
function KangaPocketsRoleSpine:playFreeStartBackAnim(_fun)
    gLobalSoundManager:playSound(KangaPocketsPublicConfig.sound_KangaPockets_RoleSpine_FreeStartBack)
    local animName = "start_bace"
    util_spinePlay(self.m_spine, animName, false)
    util_spineEndCallFunc(self.m_spine, animName, function()
        self:playIdleAnim("")
        if "function" == type(_fun) then
            _fun()
        end
    end)
end


--jackpot弹板
function KangaPocketsRoleSpine:playJackpotViewStartAnim()
    util_spinePlay(self.m_spine, "start", false)
    util_spineEndCallFunc(self.m_spine, "start", function()
        util_spinePlay(self.m_spine, "idle", true)
    end)
end

--大赢动画
function KangaPocketsRoleSpine:playBigWinAnim()
    local animName = "actionframe_yugao3"
    util_spinePlay(self.m_spine, animName, false)
    util_spineEndCallFunc(self.m_spine, animName, function()
        self:playIdleAnim("")
    end)
end

--多个bonus落地
function KangaPocketsRoleSpine:playBonusBulingAnim(_fun)
    gLobalSoundManager:playSound(KangaPocketsPublicConfig.sound_KangaPockets_RoleSpine_BonusBuling)
    local animName = "actionframe_yugao3"
    util_spinePlay(self.m_spine, animName, false)
    util_spineEndCallFunc(self.m_spine, animName, function()
        self:playIdleAnim("")
        _fun()
    end)
end

return KangaPocketsRoleSpine