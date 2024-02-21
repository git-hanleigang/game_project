
local DragonParadeRespinBoardView = class("DragonParadeRespinBoardView",util_require("Levels.BaseLevelDialog"))


function DragonParadeRespinBoardView:initUI(machine, data)
    self.m_machine = machine

    --移动的点位
    self.m_board_pos1Y = data.board_pos1Y
    self.m_board_pos2Y = data.board_pos2Y
    self.m_board_posUpY = data.board_posUpY
    self:createCsbNode("DragonParade_ReSpin_qipan_0.csb")
    self.m_clipParentNode = self:findChild("Node_sp_reel")

    -- self:runCsbAction("actionframe") -- 播放时间线
    -- self:findChild("xxxx") -- 获得子节点
    -- self:addClick("xxx") -- 非按钮节点得手动绑定监听


    -- performWithDelay(节点（必须传入）, function ()
	    -- 延时函数
	    -- xxx 对应延时时间
    -- end, xxx)

    -- schedule(view,function ()
        -- 定时器
    	-- xxx 对应定时器调用时间间隔
    -- end,xxxx)

    self.m_bonus2TotalWinBar = util_createAnimation("DragonParade_Bonus2ui.csb")
    self:findChild("Node_Bonus2ui"):addChild(self.m_bonus2TotalWinBar)
    self.m_bonus2TotalWinLabel = self.m_bonus2TotalWinBar:findChild("m_lb_coins")

    self.m_bonus3TotalWinBar = util_createAnimation("DragonParade_Bonus3ui.csb")
    self:findChild("Node_Bonus3ui"):addChild(self.m_bonus3TotalWinBar)
    self.m_bonus3TotalWinLabel = self.m_bonus3TotalWinBar:findChild("m_lb_coins")

    self.m_bonusTotalCountBar = util_createAnimation("DragonParade_ReSpin_mid.csb")
    self:findChild("Node_ReSpin_mid"):addChild(self.m_bonusTotalCountBar)
    self.m_bonusTotalCountLabel = self.m_bonusTotalCountBar:findChild("m_lb_num")

    self.m_respinBar = util_createView("CodeDragonParadeSrc.DragonParadeRespinBarView")
    self:findChild("Node_bar"):addChild(self.m_respinBar)

    self:setRespinBarType( "change" )

    self:setTimesBarOrderNormal(true)

    --双倍特效csb
    self.m_doubleEdgeEffect = util_createAnimation("DragonParade_qipan_effect.csb")
    self:findChild("Node_qipan"):addChild(self.m_doubleEdgeEffect)
    self.m_doubleEdgeEffect:setVisible(false)

    --压黑
    self.m_innerEdgeDark = util_createAnimation("DragonParade_Respin_shuzi_0.csb")
    self:findChild("respin_win_num"):addChild(self.m_innerEdgeDark)
    self.m_innerEdgeDark:setVisible(false)

    --压黑上spine特效
    self.m_edgeSpineEffect = util_spineCreate("Socre_DragonParade_guochang2", true, true)
    self.m_innerEdgeDark:findChild("Node_respin"):addChild(self.m_edgeSpineEffect)
    self.m_edgeSpineEffect:setVisible(false)
end

function DragonParadeRespinBoardView:setTimesBarOrderNormal(isNormal)
    if isNormal then
        --压暗在上
        self:findChild("Node_bar"):setLocalZOrder(10)
        self:findChild("yaan"):setLocalZOrder(20)
    else
        --finish 压暗在下
        self:findChild("Node_bar"):setLocalZOrder(20)
        self:findChild("yaan"):setLocalZOrder(10)
    end
end

function DragonParadeRespinBoardView:onEnter()
    DragonParadeRespinBoardView.super.onEnter(self)
end

function DragonParadeRespinBoardView:onExit()
    DragonParadeRespinBoardView.super.onExit(self)
end

function DragonParadeRespinBoardView:getClipParentNode()
    return self.m_clipParentNode
end

--[[
    up
    1
    2
]]
function DragonParadeRespinBoardView:runMove_pos1ToUp(time, func)
    self:setPositionY(self.m_board_pos1Y)
    local actionList={}
    actionList[#actionList+1] = cc.MoveTo:create(time, cc.p(0, self.m_board_posUpY))
    local seq=cc.Sequence:create(actionList)
    self:runAction(seq)

    performWithDelay(self, function()
        self:setPosition(cc.p(0, self.m_board_posUpY))
        if func then
            func()
        end
    end, time)
end

function DragonParadeRespinBoardView:runMove_posUpTo1(time, func)
    self:setPositionY(self.m_board_posUpY)
    local actionList={}
    actionList[#actionList+1] = cc.MoveTo:create(time, cc.p(0, self.m_board_pos1Y))
    local seq=cc.Sequence:create(actionList)
    self:runAction(seq)

    performWithDelay(self, function()
        self:setPosition(cc.p(0, self.m_board_pos1Y))
        if func then
            func()
        end
    end, time)
end

function DragonParadeRespinBoardView:runMove_pos2To1(time, func)
    self:setPositionY(self.m_board_pos2Y)
    local actionList={}
    actionList[#actionList+1] = cc.MoveTo:create(time, cc.p(0, self.m_board_pos1Y))
    local seq=cc.Sequence:create(actionList)
    self:runAction(seq)

    performWithDelay(self, function()
        self:setPosition(cc.p(0, self.m_board_pos1Y))
        if func then
            func()
        end
    end, time)
end

function DragonParadeRespinBoardView:runMove_pos2ToUp(time, func)
    self:setPositionY(self.m_board_pos2Y)
    local actionList={}
    actionList[#actionList+1] = cc.MoveTo:create(time, cc.p(0, self.m_board_posUpY))
    local seq=cc.Sequence:create(actionList)
    self:runAction(seq)

    performWithDelay(self, function()
        self:setPosition(cc.p(0, self.m_board_posUpY))
        if func then
            func()
        end
    end, time)
end

function DragonParadeRespinBoardView:runMove_posUpTo2(time, func)
    self:setPositionY(self.m_board_posUpY)
    local actionList={}
    actionList[#actionList+1] = cc.MoveTo:create(time, cc.p(0, self.m_board_pos2Y))
    local seq=cc.Sequence:create(actionList)
    self:runAction(seq)

    performWithDelay(self, function()
        self:setPosition(cc.p(0, self.m_board_pos2Y))
        if func then
            func()
        end
    end, time)
end

function DragonParadeRespinBoardView:setFrontOrder(  )
    self:setLocalZOrder(20)
end

function DragonParadeRespinBoardView:setBackOrder(  )
    self:setLocalZOrder(10)
end

function DragonParadeRespinBoardView:setPos1(  )
    self:setPosition(cc.p(0, self.m_board_pos1Y))
end

function DragonParadeRespinBoardView:setPos2(  )
    self:setPosition(cc.p(0, self.m_board_pos2Y))
end

function DragonParadeRespinBoardView:setPosUp(  )
    self:setPosition(cc.p(0, self.m_board_posUpY))
end
--设置bonus2 总值
function DragonParadeRespinBoardView:setBonus2TotalWinNum( num )
    self.m_bonus2TotalWinLabel:setString(num)
    self:updateLabelSize({label=self.m_bonus2TotalWinLabel,sx=0.8,sy=0.8}, 185)
end
--设置bonus3 总值
function DragonParadeRespinBoardView:setBonus3TotalWinNum( num , isAnim)
    if isAnim then
        self.m_bonus3TotalWinBar:runCsbAction("actionframe", false)

        gLobalSoundManager:playSound("DragonParadeSounds/sound_DragonParade_respin_bonus3_numchange.mp3")
    end

    self.m_bonus3TotalWinLabel:setString(num)
    self:updateLabelSize({label=self.m_bonus3TotalWinLabel,sx=0.8,sy=0.8}, 185)
end
--设置bonus 总个数
function DragonParadeRespinBoardView:setbonusTotalCount( num , isAnim)
    if isAnim then
        self.m_bonusTotalCountBar:runCsbAction("actionframe", false)
    end
    self.m_bonusTotalCountLabel:setString(num)
    self:updateLabelSize({label=self.m_bonusTotalCountLabel,sx=0.8,sy=0.8}, 182)
end
--全满总数动画
function DragonParadeRespinBoardView:showMidActionFrame()
    self.m_bonusTotalCountBar:runCsbAction("actionframe", false)
end

function DragonParadeRespinBoardView:changeRespinTimes( times, isinit )
    self.m_respinBar:changeRespinTimes(times, isinit)
end

function DragonParadeRespinBoardView:setRespinBarType( type )
    if type == "isFinish" then
        self.m_respinBar:setCompleteType()

        self:setTimesBarOrderNormal(false)
    else
        self.m_respinBar:setChangeType()
        self:setTimesBarOrderNormal(true)
    end
end

function DragonParadeRespinBoardView:showDark(  )
    self:runCsbAction("yaan_start", false)
end

function DragonParadeRespinBoardView:hideDark(  )
    self:runCsbAction("yaan_over", false)
end

function DragonParadeRespinBoardView:dark(  )
    self:runCsbAction("idle1", true)
end

function DragonParadeRespinBoardView:idle(  )
    self:runCsbAction("idle", true)
end
--双倍时触发
function DragonParadeRespinBoardView:doubleEdgeEffectTriggerAnim(  )
    self.m_doubleEdgeEffect:setVisible(true)
    for i=1,16 do
        local particle = self.m_doubleEdgeEffect:findChild("Particle_a_" .. i)
        particle:resetSystem()
    end
    
    self.m_doubleEdgeEffect:findChild("Node_qipan_chufa_root"):setVisible(true)
    self.m_doubleEdgeEffect:findChild("Node_yugao_effect_root"):setVisible(false)
    self.m_doubleEdgeEffect:findChild("Node_daying_effect_root"):setVisible(false)

    self.m_doubleEdgeEffect:runCsbAction("actionframe", false, function()
        self.m_doubleEdgeEffect:setVisible(false)

        for i=1,16 do
            local particle = self.m_doubleEdgeEffect:findChild("Particle_a_" .. i)
            particle:stopSystem()
        end
    end)
end

function DragonParadeRespinBoardView:runEdgeDark()
    self.m_innerEdgeDark:setVisible(true)
    self.m_innerEdgeDark:runCsbAction("actionframe", false, function()
        self.m_innerEdgeDark:setVisible(false)
    end)

    -- performWithDelay(self, function()
        self.m_edgeSpineEffect:setVisible(true)
        util_spinePlay(self.m_edgeSpineEffect, "actionframe_respin", false)
        local spineEndCallFunc = function()
            self.m_edgeSpineEffect:setVisible(false)
        end
        util_spineEndCallFunc(self.m_edgeSpineEffect, "actionframe_respin", spineEndCallFunc)
    -- end, 50/60)
    
end
--设置bar 是否是上面
function DragonParadeRespinBoardView:setRespinBarPos(isUp)
    if isUp then
        self.m_respinBar:setPositionY(128)
    else
        self.m_respinBar:setPositionY(0)
    end
    
end

return DragonParadeRespinBoardView