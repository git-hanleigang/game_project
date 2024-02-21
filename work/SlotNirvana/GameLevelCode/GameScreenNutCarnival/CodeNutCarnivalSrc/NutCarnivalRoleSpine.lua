--[[
    角色时间线处理
]]
local NutCarnivalRoleSpine = class("NutCarnivalRoleSpine", cc.Node)

function NutCarnivalRoleSpine:initData_(_params)
    --[[
        _params = {
        }
    ]]
    self.m_data = _params

    self:initUI()
end
function NutCarnivalRoleSpine:initUI()
    local spineName = "Socre_NutCarnival_Wild"
    self.m_spine    = util_spineCreate(spineName,true,true)
    self:addChild(self.m_spine)
end

--多幅多彩玩法结束-过场
function NutCarnivalRoleSpine:playBonusGameOverGuoChangAnim(_fun1, _fun2)
    self:setVisible(true)
    local animName = "guochang"
    util_spinePlay(self.m_spine, animName, false)
    performWithDelay(self,function()
        _fun1()
        performWithDelay(self,function()
            self:setVisible(false)
            _fun2()
        end, 42/30)
    end, 30/30)
end
--reSpin-触发过场
function NutCarnivalRoleSpine:playReSpinGuoChangAnim(_fun1, _fun2)
    self:setVisible(true)
    -- 0~78
    local animName = "guochang2"
    util_spinePlay(self.m_spine, animName, false)
    performWithDelay(self,function()
        _fun1()
        performWithDelay(self,function()
            self:setVisible(false)
            _fun2()
        end, 36/30)
    end, 42/30)
end

--reSpin-转盘出现
function NutCarnivalRoleSpine:playWheelStartAnim(_fun)
    local animName = "zhuanpan_start"
    util_spinePlay(self.m_spine, animName, false)
    util_spineEndCallFunc(self.m_spine, animName, _fun)
end
--reSpin-转盘在没触发时的idle
function NutCarnivalRoleSpine:playWheelIdleAnim()
    local animName = "zhuanpan_idle"
    util_spinePlay(self.m_spine, animName, true)
end
--reSpin-转盘开始旋转-角色消失
function NutCarnivalRoleSpine:playWheelBeginRotateAnim(_fun)
    -- local animName = "zhuanpan_idle2"
    local animName = "zhuanpan_idle3"
    util_spinePlay(self.m_spine, animName, false)
    util_spineEndCallFunc(self.m_spine, animName, function()
        self:playWheelRoleOverAnim()
    end)
end
--reSpin-转盘中奖 出现+庆祝+消失
function NutCarnivalRoleSpine:playWheelActionframeAnim(_fun)
    --出现
    local animName = "zhuanpan_start2"
    util_spinePlay(self.m_spine, animName, false)
    util_spineEndCallFunc(self.m_spine, animName, function()
        --庆祝
        animName = "zhuanpan_qingzhu"
        util_spinePlay(self.m_spine, animName, false)
        util_spineEndCallFunc(self.m_spine, animName, function()
            --idle
            animName = "zhuanpan_qingzhu2"
            util_spinePlay(self.m_spine, animName, false)
            util_spineEndCallFunc(self.m_spine, animName, function()
                --over
                self:playWheelRoleOverAnim(_fun)
            end)
        end)
    end)
end
--reSpin-从转盘上下潜消失
function NutCarnivalRoleSpine:playWheelRoleOverAnim(_fun)
    local animName = "zhuanpan_over"
    util_spinePlay(self.m_spine, animName, false)
    if nil ~= _fun then
        util_spineEndCallFunc(self.m_spine, animName, _fun)
    end
end

--reSpinMore
function NutCarnivalRoleSpine:playReSpinMoreAnim()
    local animName = "idle_tanban_respin"
    util_spinePlay(self.m_spine, animName, true)
end
--reSpin-全满过场
function NutCarnivalRoleSpine:playReSpinFullAnim(_fun)
    self:setVisible(true)
    util_spinePlay(self.m_spine, "yugao2", false)
    performWithDelay(self,function()
        self:setVisible(false)
        _fun()
    end, 60/30)
end
--reSpin-结束过场
function NutCarnivalRoleSpine:playReSpinOverGuoChangAnim(_fun1, _fun2)
    self:playBonusGameOverGuoChangAnim(_fun1, _fun2)
end


--jackpot弹板
function NutCarnivalRoleSpine:playJackpotViewAnim()
    local animName = "idle_tanban_jackpot"
    util_spinePlay(self.m_spine, animName, true)
end


--free
function NutCarnivalRoleSpine:playFreeStartAnim()
    local animName = "idle_tanban_freestart"
    util_spinePlay(self.m_spine, animName, true)
end
function NutCarnivalRoleSpine:playFreeStartGuoChang(_fun1, _fun2)
    self:setVisible(true)
    util_spinePlay(self.m_spine, "guochang3", false)

    performWithDelay(self,function()
        _fun1()
        performWithDelay(self,function()
            self:setVisible(false)
            _fun2()
        end, 21/30)
    end, 45/30)
end
--free结束两个层级
function NutCarnivalRoleSpine:playFreeOverUpAnim()
    local animName = "idle_tanban_free_qian"
    util_spinePlay(self.m_spine, animName, true)
end
function NutCarnivalRoleSpine:playFreeOverDownAnim()
    local animName = "idle_tanban_free_hou"
    util_spinePlay(self.m_spine, animName, true)
end
--free-结束过场
function NutCarnivalRoleSpine:playFreeOverGuoChangAnim(_fun1, _fun2)
    self:playBonusGameOverGuoChangAnim(_fun1, _fun2)
end

return NutCarnivalRoleSpine