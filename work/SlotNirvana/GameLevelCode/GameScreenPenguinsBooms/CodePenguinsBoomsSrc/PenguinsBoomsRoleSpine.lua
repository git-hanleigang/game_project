-- 袋鼠角色
local PenguinsBoomsRoleSpine = class("PenguinsBoomsRoleSpine", cc.Node)
local PublicConfig = require "PenguinsBoomsPublicConfig"

function PenguinsBoomsRoleSpine:initData_(_params)
    --[[
        _params = {
            spineName = "",
        }
    ]]
    self.m_data = _params

    self:initUI()
end
function PenguinsBoomsRoleSpine:initUI()
    local spineName = self.m_data.spineName
    self.m_spine    = util_spineCreate(spineName,true,true)
    self:addChild(self.m_spine)
end

function PenguinsBoomsRoleSpine:resetIdleLoopAnim(_bFree)
    if not _bFree then
        self:playIdleAnim(0, 1)
    else
        self:playFreeIdleAnim(0, 1)
    end
end
--base下的idle循环
function PenguinsBoomsRoleSpine:playIdleAnim(_listIndex, _animIndex)
    -- 播2,3,4,次idle后 2选1播 idle1 or idle 2
    local idleLoopList = {
        {"idleframe", "idleframe", "idleframe1"},
        {"idleframe", "idleframe", "idleframe2"},
        {"idleframe", "idleframe", "idleframe", "idleframe1"},
        {"idleframe", "idleframe", "idleframe", "idleframe2"},
        {"idleframe", "idleframe", "idleframe", "idleframe", "idleframe1"},
        {"idleframe", "idleframe", "idleframe", "idleframe", "idleframe2"},
    }
    
    if not idleLoopList[_listIndex] or _animIndex > #(idleLoopList[_listIndex]) then
        _listIndex = math.random(1, #idleLoopList)
        _animIndex = 1
    end

    local idleName = idleLoopList[_listIndex][_animIndex]
    util_spinePlay(self.m_spine, idleName, false)
    util_spineEndCallFunc(self.m_spine, idleName, function()
        self:playIdleAnim(_listIndex, _animIndex + 1)
    end)
end
--free下的idle循环
function PenguinsBoomsRoleSpine:playFreeIdleAnim(_listIndex, _animIndex)
    -- 播2,3,4,次idle后 2选1播 idle1 or idle 2
    local idleLoopList = {
        {"idleframe", "idleframe", "idleframe2"},
        {"idleframe", "idleframe", "idleframe3"},
        {"idleframe", "idleframe", "idleframe", "idleframe2"},
        {"idleframe", "idleframe", "idleframe", "idleframe3"},
        {"idleframe", "idleframe", "idleframe", "idleframe", "idleframe2"},
        {"idleframe", "idleframe", "idleframe", "idleframe", "idleframe3"},
    }
    
    if not idleLoopList[_listIndex] or _animIndex > #(idleLoopList[_listIndex]) then
        _listIndex = math.random(1, #idleLoopList)
        _animIndex = 1
    end

    local idleName = idleLoopList[_listIndex][_animIndex]
    util_spinePlay(self.m_spine, idleName, false)
    util_spineEndCallFunc(self.m_spine, idleName, function()
        self:playFreeIdleAnim(_listIndex, _animIndex + 1)
    end)
end

function PenguinsBoomsRoleSpine:playClickAnim()
    local animName = "actionframe_dianji"
    util_spinePlay(self.m_spine, animName, false)
    util_spineEndCallFunc(self.m_spine, animName, function()
        self:playIdleAnim(0, 1)
    end)
end

--升行-角色下降
function PenguinsBoomsRoleSpine:playAscendRowAninm(_fun)
    local animName = "actionframe_down"
    -- local animName = "actionframe_huikan_down"    
    util_spinePlay(self.m_spine, animName, false)
    if nil ~= _fun then
        util_spineEndCallFunc(self.m_spine, animName, function()
            _fun()
        end)
    end
end
--降行-角色上升
function PenguinsBoomsRoleSpine:playDownRowAninm(_fun)
    gLobalSoundManager:playSound(PublicConfig.sound_PenguinsBooms_role_up)
    local animName = "actionframe_up"
    util_spinePlay(self.m_spine, animName, false)
    util_spineEndCallFunc(self.m_spine, animName, function()
        _fun()
    end)
end

--预告中奖
function PenguinsBoomsRoleSpine:playYuGaoAnim()
    local animName = "actionframe_yugao"
    util_spinePlay(self.m_spine, animName, false)
    util_spineEndCallFunc(self.m_spine, animName, function()
        self:playIdleAnim(0, 1)
    end)
end

--jackpot弹板
function PenguinsBoomsRoleSpine:playJackpotViewAnim()
    local startName = "start_tanban"
    local idleName  = "idle_tanban"
    util_spinePlay(self.m_spine, startName, false)
    util_spineEndCallFunc(self.m_spine, startName, function()
        util_spinePlay(self.m_spine, idleName, true)
    end)
end

--大赢
function PenguinsBoomsRoleSpine:playBigWinAnim(_fun)
    local animName = "actionframe_bigwin"
    util_spinePlay(self.m_spine, animName, false)
    util_spineEndCallFunc(self.m_spine, animName, function()
        _fun()
    end)
end

--过场时间线
function PenguinsBoomsRoleSpine:playGuoChangAnim(_fun)
    local animName = "actionframe_guochang"
    util_spinePlay(self.m_spine, animName, false)
    util_spineEndCallFunc(self.m_spine, animName, function()
        _fun()
    end)
end

--scatter触发
function PenguinsBoomsRoleSpine:playScatterAnim()
    local animName = "actionframe_bigwin"
    util_spinePlay(self.m_spine, animName, false)
    util_spineEndCallFunc(self.m_spine, animName, function()
        self:playIdleAnim(0, 1)
    end)
end
--角色丢下炸弹
function PenguinsBoomsRoleSpine:playAddBonusAnim(_fun)
    local animName = "actionframe"
    util_spinePlay(self.m_spine, animName, false)
    util_spineEndCallFunc(self.m_spine, animName, function()
        _fun()
    end)
end
return PenguinsBoomsRoleSpine