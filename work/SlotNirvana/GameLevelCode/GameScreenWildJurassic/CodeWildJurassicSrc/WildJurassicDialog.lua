---
--xcyy
--2018年5月23日
--FruitFarmView.lua

local WildJurassicDialog = class("WildJurassicDialog",util_require("Levels.BaseDialog"))

WildJurassicDialog.m_tanbanOverSound = nil

--初始化界面machine-游戏主layer  dialog_type-ccb名字 func-回调 autoType 自动消失使用,mulIndex-多个时间线时使用
function WildJurassicDialog:initViewData(machine, dialog_type, func, autoType, mulIndex, fps)
    self.m_overRuncallfunc = nil
    self.m_btnClickFunc = nil
    self.m_status = self.STATUS_NONE
    self.m_type_name = dialog_type
    self.m_machine = machine
    self.m_callfunc = func
    self.m_allowClick = true
    self.m_btnTouchSound = SOUND_ENUM.MUSIC_BTN_CLICK
    -- 是否是自定义坐标
    self.m_isUserDefPos = false

    self:initConfig(mulIndex, autoType)
    self:initNode()

    -- 添加spine
    self:initNodeSpine(dialog_type)

    self:openDialog()

    local _isPortrait = globalData.slotRunData.isPortrait
    local _isPortraitMachine = globalData.slotRunData:isMachinePortrait()
    if _isPortrait ~= _isPortraitMachine then
        gLobalNoticManager:addObserver(
            self,
            function(self)
                local csbNodeName = self.m_csbNode:getName()
                if csbNodeName == "Layer" then
                    self:changeVisibleSize(display.size)
                else
                    if not self.m_isUserDefPos then
                        -- 使用的屏幕大小换算的坐标
                        local posX, posY = self:getPosition()
                        self:setPosition(cc.p(posY, posX))
                    end
                end
            end,
            ViewEventType.NOTIFY_RESET_SCREEN
        )
    end
end

--弹板上添加 spine
function WildJurassicDialog:initNodeSpine(_name)
    if _name == "FreeSpinStart" or _name == "FreeSpinMore" or _name == "FreeSpinOver" then
        self.m_DialogSpine = util_spineCreate("WildJurassic_tb", true, true)
        self:findChild("spine"):addChild(self.m_DialogSpine)
        if _name == "FreeSpinOver" then
            self.m_DialogSpine:setSkin("c")
        else
            self.m_DialogSpine:setSkin("d")
        end
    end
end

--开始ccb中配置 暂时屏蔽
function WildJurassicDialog:showStart()
    self.m_status = self.STATUS_START
    self:runCsbAction(self.m_start_name)

    --播放spine
    if self.m_DialogSpine then
        util_spinePlay(self.m_DialogSpine,"start",false)
    end

    local time = self:getAnimTime(self.m_start_name)
    if not time or time <= 0 then
        time = self.m_startTime
    end

    performWithDelay(
        self,
        function()
            self:showidle()
            --播放spine
            if self.m_DialogSpine then
                util_spinePlay(self.m_DialogSpine,"idle",true)
            end
        end,
        time
    )
end

--结束
function WildJurassicDialog:showOver(name)
    if self.isShowOver then
        return
    end
    self.isShowOver = true

    --播放spine
    if self.m_DialogSpine then
        util_spinePlay(self.m_DialogSpine,"over",false)
    end

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

return WildJurassicDialog