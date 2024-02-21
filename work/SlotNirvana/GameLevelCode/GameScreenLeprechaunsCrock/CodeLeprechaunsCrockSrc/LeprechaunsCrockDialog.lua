---
--xcyy
--2018年5月23日
--FruitFarmView.lua

local LeprechaunsCrockDialog = class("LeprechaunsCrockDialog",util_require("Levels.BaseDialog"))

LeprechaunsCrockDialog.m_tanbanOverSound = nil

--初始化界面machine-游戏主layer  dialog_type-ccb名字 func-回调 autoType 自动消失使用,mulIndex-多个时间线时使用
function LeprechaunsCrockDialog:initViewData(machine, dialog_type, func, autoType, mulIndex, fps)
    LeprechaunsCrockDialog.super.initViewData(self,machine, dialog_type, func, autoType, mulIndex, fps) 

    if LeprechaunsCrockDialog.DIALOG_TYPE_FREESPIN_START == dialog_type then
        self:showFreeStartView()
    end

    if self.m_type_name == "FreeSpinStart" or self.m_type_name == "FreeSpinOver" then
        for i=1,2 do
            self:findChild("Particle_"..i):setVisible(false)
        end
    end
end

--[[
    free开始弹板
    分为普通 和 加强 
    播放动画和显示 都不一样
]]
function LeprechaunsCrockDialog:showFreeStartView( )
    local selfData = self.m_machine.m_runSpinResultData.p_selfMakeData or {}
    self.m_playBuffCount = selfData.playBuffCount or 0 -- 判断是否为加强的 分为 1 2 3
    if self.m_playBuffCount == 0 then --显示普通的
        self:findChild("Node_zengqiang"):setVisible(false)
    else--显示加强
        self:findChild("Node_putong"):setVisible(false)
        self:findChild("m_lb_nums"):setString(self.m_playBuffCount)
        for i=1,3 do
            self:findChild("Node_zengqiang"..i):setVisible(false)
        end
        self:findChild("Node_zengqiang"..self.m_playBuffCount):setVisible(true)

        self.m_baoZhaEffect = {}
        for effectIndex = 1, self.m_playBuffCount do
            self.m_baoZhaEffect[effectIndex] = util_createAnimation("LeprechaunsCrock_tb_symbol_tx.csb")
            self:findChild("Node_symbol_bd0".. self.m_playBuffCount .."_"..effectIndex):addChild(self.m_baoZhaEffect[effectIndex])
        end

    end
end

--[[
    点击按钮之后 先播放动画 之后在播over时间线
]]
function LeprechaunsCrockDialog:playFreeStartViewEffect(_func)
    if self.m_playBuffCount then
        if self.m_playBuffCount == 0 then
            self:runCsbAction("actionframe", false, function()
                if _func then
                    _func()
                end
            end)
            self.m_machine:waitWithDelay(20/60, function()
                if not tolua.isnull(self) then
                    self:findChild("Node_putong"):setVisible(false)
                end
            end)
        else
            self:playSymbolRemoveEffect(_func)
        end

        -- 快速置灰 渐隐
        self:findChild("Button"):setBright(true)
        util_nodeFadeIn(self:findChild("Button"), 0.3, 255, 0, nil, nil)
        util_nodeFadeIn(self:findChild("sg"), 0.3, 255, 0, nil, nil)
    else
        if _func then
            _func()
        end
    end
end

--[[
    free 玩法有加强的时候 上面的小图标需要依次消除
]]
function LeprechaunsCrockDialog:playSymbolRemoveEffect(_func)
    for i, _node in ipairs(self.m_baoZhaEffect) do
        self.m_machine:waitWithDelay(0.2 * (i - 1), function()
            gLobalSoundManager:playSound(self.m_machine.m_publicConfig.SoundConfig.sound_LeprechaunsCrock_freeStartView_boost_remove)
            
            _node:runCsbAction("actionframe", false)
            self.m_machine:waitWithDelay(15/60, function()
                self:findChild("Node_symbol".. self.m_playBuffCount .."_"..i):setVisible(false)
            end)
        end)
    end

    local delayTime = 0.2 * (self.m_playBuffCount - 1) + 45/60
    self.m_machine:waitWithDelay( delayTime, function()
        self:findChild("Node_putong"):setVisible(true)
        self:runCsbAction("switch", false, function()
            self:findChild("Node_zengqiang"):setVisible(false)
            self:runCsbAction("actionframe", false, function()
                if _func then
                    _func()
                end
            end)
            
            self.m_machine:waitWithDelay(20/60, function()
                if not tolua.isnull(self) then
                    self:findChild("Node_putong"):setVisible(false)
                end
            end)
        end)
    end)
end

function LeprechaunsCrockDialog:clickFunc(sender)
    if not self.m_allowClick then
        return
    end

    local name
    if sender then
        name = sender:getName()
    end
    gLobalSoundManager:playSound(self.m_btnTouchSound)
    if self.m_tanbanOverSound then
        gLobalSoundManager:playSound(self.m_tanbanOverSound)
    end

    -- gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
    if sender and sender.setTouchEnabled then
        sender:setTouchEnabled(false)
    end
    if self.m_status == self.STATUS_START or self.m_status == self.STATUS_IDLE or self.m_status == self.STATUS_AUTO then
        self:playFreeStartViewEffect(function()
            self:showOver(name)
        end)
    end
end

--结束
function LeprechaunsCrockDialog:showOver(name)
    if self.isShowOver then
        return
    end
    self.isShowOver = true

    if self.m_btnClickFunc then
        self.m_btnClickFunc()
        self.m_btnClickFunc = nil
    end

    local time
    if self.m_status == self.STATUS_IDLE then
        time = self:getAnimTime(self.m_over_name)
        self:runCsbAction(self.m_over_name)
    else
        self.m_status = self.STATUS_OVER

        if self.m_overRuncallfunc then
            self.m_overRuncallfunc()
            self.m_overRuncallfunc = nil
        end

        if self.m_callfunc then
            self.m_callfunc()
            self.m_callfunc = nil
        end
        self:removeFromParent()
        return
    end
    self.m_status = self.STATUS_OVER
    if not time or time <= 0 or time > 100 then
        time = self.m_overTime
    end
    
    -- free弹板需要特殊处理
    if self.m_type_name == "FreeSpinStart" or self.m_type_name == "FreeSpinOver" then
        performWithDelay(self,
        function()
            for i=1,2 do
                self:findChild("Particle_"..i):setVisible(true)
                self:findChild("Particle_"..i):resetSystem()
            end
        end,
        0.4)

        performWithDelay(self,
        function()
            if self.m_callfunc then
                self.m_callfunc()
                self.m_callfunc = nil
            end
        end,
        40/60)

        performWithDelay(
        self,
        function()
            self:removeFromParent()
        end,
        time
    )
    else
        performWithDelay(
        self,
        function()
            if self.m_overRuncallfunc then
                self.m_overRuncallfunc()
                self.m_overRuncallfunc = nil
            end

            if self.m_callfunc then
                self.m_callfunc()
                self.m_callfunc = nil
            end
            self:removeFromParent()
        end,
        time
    )
    end
end

return LeprechaunsCrockDialog