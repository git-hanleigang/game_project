---
--smy
--2018年4月26日
--BaseDialog.lua
--fix ios 0312
local BaseDialog = class("BaseDialog", util_require("base.BaseView"))

BaseDialog.DIALOG_TYPE_FREESPIN_START = "FreeSpinStart"
BaseDialog.DIALOG_TYPE_FREESPIN_MORE = "FreeSpinMore"
BaseDialog.DIALOG_TYPE_FREESPIN_OVER = "FreeSpinOver"
BaseDialog.DIALOG_TYPE_RESPIN_START = "ReSpinStart"
BaseDialog.DIALOG_TYPE_RESPIN_OVER = "ReSpinOver"
BaseDialog.DIALOG_TYPE_BONUS_START = "BonusStart"
BaseDialog.DIALOG_TYPE_BONUS_OVER = "BonusOver"
BaseDialog.DIALOG_TYPE_JACKPOT = "Jackpot"
BaseDialog.DIALOG_TYPE_OTHER = "Other"

BaseDialog.m_type_name = nil
BaseDialog.m_csb_name = nil --ccbi and jsController name
BaseDialog.m_machine = nil
BaseDialog.m_callfunc = nil
BaseDialog.m_overRuncallfunc = nil
BaseDialog.m_btnClickFunc = nil

BaseDialog.STATUS_NONE = 0
BaseDialog.STATUS_AUTO = 1
BaseDialog.STATUS_START = 2
BaseDialog.STATUS_IDLE = 3
BaseDialog.STATUS_OVER = 4
BaseDialog.STATUS_DIE = 5
BaseDialog.m_status = nil

BaseDialog.AUTO_TYPE_ONLY = 1 --一条时间线
BaseDialog.AUTO_TYPE_NOMAL = 2 --正常3
BaseDialog.m_autoType = nil

BaseDialog.m_index = nil
------------弹版配置-------------
BaseDialog.m_auto_name = "auto"
BaseDialog.m_start_name = "start"
BaseDialog.m_idle_name = "idle"
BaseDialog.m_over_name = "over"
BaseDialog.m_startTime = 1.0
BaseDialog.m_overTime = 0.5
BaseDialog.m_autoTime = 1.5
BaseDialog.m_idleTime = 1.5
BaseDialog.m_btnTouchSound = SOUND_ENUM.MUSIC_BTN_CLICK

BaseDialog.m_allowClick = true

--初始化界面machine-游戏主layer  dialog_type-ccb名字 func-回调 autoType 自动消失使用,mulIndex-多个时间线时使用
function BaseDialog:initViewData(machine, dialog_type, func, autoType, mulIndex, fps)
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

-- 设置是否是自定义坐标
function BaseDialog:setIsUserDefPos(isTrue)
    self.m_isUserDefPos = isTrue or false
end

function BaseDialog:setBtnClickFunc(func)
    self.m_btnClickFunc = func
end

function BaseDialog:setOverAniRunFunc(func)
    self.m_overRuncallfunc = func
end

--配置
function BaseDialog:initConfig(mulIndex, autoType)
    self.m_autoType = autoType
    self.m_index = mulIndex
    if mulIndex then
        self.m_auto_name = "auto" .. mulIndex
        self.m_start_name = "start" .. mulIndex
        self.m_idle_name = "idle" .. mulIndex
        self.m_over_name = "over" .. mulIndex
    else
        self.m_auto_name = "auto"
        self.m_start_name = "start"
        self.m_idle_name = "idle"
        self.m_over_name = "over"
    end
end

--初始化ccbi
function BaseDialog:initNode()
    self.m_csb_name = self.m_machine:getModuleName() .. "/" .. self.m_type_name .. ".csb"
    self:createCsbNode(self.m_csb_name, false)
end

--开始弹框
function BaseDialog:openDialog()
    if self.m_autoType and self.m_autoType == BaseDialog.AUTO_TYPE_ONLY then
        --弹出自动弹版
        self:showAuto()
    else
        --正常弹出开始弹版
        self:showStart()
    end
end

--自动弹窗 ccb中配置 暂时屏蔽
function BaseDialog:showAuto()
    self.m_status = self.STATUS_AUTO
    self:runCsbAction(self.m_auto_name)
    local time = self:getAnimTime(self.m_auto_name)

    if not time or time <= 0 then
        time = self.m_autoTime
    end

    performWithDelay(
        self,
        function()
            self:clickFunc()
            self:removeFromParent()
        end,
        time
    )
end
--开始ccb中配置 暂时屏蔽
function BaseDialog:showStart()
    self.m_status = self.STATUS_START
    self:runCsbAction(self.m_start_name)
    local time = self:getAnimTime(self.m_start_name)
    if not time or time <= 0 then
        time = self.m_startTime
    end

    performWithDelay(
        self,
        function()
            self:showidle()
        end,
        time
    )
end
---

--待机ccb中配置暂时屏蔽
function BaseDialog:showidle()
    self.m_status = self.STATUS_IDLE
    --auto 2
    if self.m_autoType and self.m_autoType == BaseDialog.AUTO_TYPE_NOMAL then
        self:runCsbAction(self.m_idle_name)
        local time = self:getAnimTime(self.m_idle_name)
        if not time or time <= 0 then
            time = self.m_idleTime
        end
        performWithDelay(
            self,
            function()
                self:showOver()
            end,
            time
        )
        return
    elseif globalData.slotRunData.m_isNewAutoSpin and globalData.slotRunData.m_isAutoSpinAction then
        performWithDelay(
            self,
            function()
                self:showOver()
            end,
            8
        )
    end

    --循环播放
    self:runCsbAction(self.m_idle_name, true)
end

function BaseDialog:clickFunc(sender)
    if not self.m_allowClick then
        return
    end

    local name
    if sender then
        name = sender:getName()
    end
    gLobalSoundManager:playSound(self.m_btnTouchSound)

    -- gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
    if sender and sender.setTouchEnabled then
        sender:setTouchEnabled(false)
    end
    if self.m_status == self.STATUS_START or self.m_status == self.STATUS_IDLE or self.m_status == self.STATUS_AUTO then
        self:showOver(name)
    end
end

--结束
function BaseDialog:showOver(name)
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
            self.m_overRuncallfunc(name)
            self.m_overRuncallfunc = nil
        end

        if self.m_callfunc then
            self.m_callfunc(name)
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
                self.m_overRuncallfunc(name)
                self.m_overRuncallfunc = nil
            end

            if self.m_callfunc then
                self.m_callfunc(name)
                self.m_callfunc = nil
            end
            self:removeFromParent()
        end,
        time
    )
end

function BaseDialog:onKeyBack()
end

function BaseDialog:getAnimTime(animName)
    if animName == nil then
        return 0
    end
    return util_csbGetAnimTimes(self.m_csbAct, animName)
end
--------------------------- Class Base CCB Functions  END---------------------------

return BaseDialog
