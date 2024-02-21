---
--xcyy
--2018年5月23日
--FrogPrinceWheelViewBg.lua

local FrogPrinceWheelViewBg = class("FrogPrinceWheelViewBg", util_require("base.BaseView"))

FrogPrinceWheelViewBg.reelGameData = {2, 4, 3, 2, 4, 3, 2, 3} --轮盘数量
FrogPrinceWheelViewBg.lockReelData = {0, 1, 2, 3, 4, 5, 6, 7} --锁定列数的类型
FrogPrinceWheelViewBg.extraFreeSpinData = {5, 1, 3, 0, 5, 1, 3, 0} --附加freespin 次数
FrogPrinceWheelViewBg.lockReelDataNum = {2, 3, 2, 2, 2, 1, 4, 2} --锁定列数的类型对应的固定列数
--"01010-150;11100-15;01001-260;10001-250;00011-260;00001-1;01111-4;10100-60"
function FrogPrinceWheelViewBg:initUI()
    self:createCsbNode("FrogPrince/GameScreenFrogPrince_wheel.csb")

    local WheelData = {}
    WheelData.m_BigWheelData = self.lockReelData
    WheelData.m_SmallWheelData = self.reelGameData
    self.m_ReelGameWheel = util_createView("CodeFrogPrinceSrc.FrogPrinceReelGameWheelView", WheelData)
    self:findChild("OZ_wheel"):addChild(self.m_ReelGameWheel)
    self.m_ReelGameWheel:setParent(self)

    local WheelData = {}
    WheelData.m_wheelData = self.extraFreeSpinData
    self.m_ExtraFreeSpinWheel = util_createView("CodeFrogPrinceSrc.FrogPrinceExtraFreeSpinWheelView", WheelData)
    self:findChild("OZ_wheel_0"):addChild(self.m_ExtraFreeSpinWheel)
    self.m_ExtraFreeSpinWheel:setVisible(false)

    self.m_ReelGameWheel:initBigCallBack(
        function()
            gLobalSoundManager:playSound("FrogPrinceSounds/sound_FrogPrince_wheel_stop.mp3")
            self.m_ReelGameWheel:runCsbAction(
                "actionframe",
                false,
                function()
                    self.m_ExtraFreeSpinWheel:setVisible(true)
                    gLobalSoundManager:playSound("FrogPrinceSounds/sound_FrogPrince_big_wheel_start.mp3")
                    self.m_ExtraFreeSpinWheel:runCsbAction(
                        "open",
                        false,
                        function()
                            performWithDelay(
                                self,
                                function()
                                    self:beginExtraFreeSpinWheelViewAction()
                                end,
                                1.5
                            )
                        end
                    )
                end
            )
        end
    )

    self.m_ExtraFreeSpinWheel:initCallBack(
        function()
            gLobalSoundManager:playSound("FrogPrinceSounds/sound_FrogPrince_wheel_stop.mp3")
            self.m_ExtraFreeSpinWheel:runCsbAction(
                "actionframe",
                false,
                function()
                    self.m_machine:showFreeSpinStartView()
                end
            )
        end
    )
end

function FrogPrinceWheelViewBg:initMachine(machine)
    self.m_machine = machine
end

function FrogPrinceWheelViewBg:playOpenAction()
    gLobalSoundManager:playSound("FrogPrinceSounds/sound_FrogPrince_big_wheel_start.mp3")
    self.m_ReelGameWheel:runCsbAction(
        "open",
        false,
        function()
            self.m_ReelGameWheel:runCsbAction("idle", true)
            self.m_ReelGameWheel:createHandEffect()
        end
    ) -- 播放时间线
end
function FrogPrinceWheelViewBg:onEnter()
end

--轮盘个数
function FrogPrinceWheelViewBg:getReelGameWheelEndIndex(type)
    local endIndex = nil
    for k, v in pairs(self.reelGameData) do
        if v == type then
            endIndex = k
            break
        end
    end
    return endIndex
end

--固定wild 列数
function FrogPrinceWheelViewBg:getLockReelWheelEndIndex(type)
    local endIndex = nil

    for k, v in pairs(self.lockReelData) do
        if v == type then
            endIndex = k
            break
        end
    end
    return endIndex
end

--额外freespin次数
function FrogPrinceWheelViewBg:getExtraFreeSpinWheelEndIndex(type)
    local endIndex = nil

    for k, v in pairs(self.extraFreeSpinData) do
        if v == type then
            endIndex = k
            break
        end
    end
    if not endIndex then
        endIndex = 4
    end
    return endIndex
end

--开始旋转
function FrogPrinceWheelViewBg:beginWheelViewAction()
    local selfData = self.m_machine.m_runSpinResultData.p_selfMakeData
    if selfData then
        -- selfData.reelNum = 4
        -- selfData.wildClosIndex = 6

        local endIndex2 = self:getLockReelWheelEndIndex(selfData.wildClosIndex)
        self.m_ReelGameWheel:beginBigWheelAction(endIndex2 + 4)

        local endIndex1 = self:getReelGameWheelEndIndex(selfData.reelNum)
        self.m_ReelGameWheel:beginSmallWheelAction(endIndex1 + 4)
        self.m_ReelGameWheel:runCsbAction("idle2", true)
    end
end

--开始旋转
function FrogPrinceWheelViewBg:beginExtraFreeSpinWheelViewAction()
    local selfData = self.m_machine.m_runSpinResultData.p_selfMakeData
    if selfData then
        local endIndex = self:getExtraFreeSpinWheelEndIndex(selfData.timesExtra)
        self.m_ExtraFreeSpinWheel:beginWheelAction(endIndex)
        self.m_ExtraFreeSpinWheel:runCsbAction("idle2", true)
    end
end

function FrogPrinceWheelViewBg:playWheelOverEffect(_reelNum, _func)
    gLobalSoundManager:playSound("FrogPrinceSounds/sound_FrogPrince_big_wheel_over.mp3")
    if _reelNum == 2 then
        self.m_ExtraFreeSpinWheel:runCsbAction(
            "over",
            false,
            function()
                self.m_ReelGameWheel:runCsbAction("over")
                if _func then
                    _func()
                end
            end
        )
    else
        self.m_ReelGameWheel:runCsbAction("over")
        self.m_ExtraFreeSpinWheel:runCsbAction(
            "over",
            false,
            function()
                if _func then
                    _func()
                end
            end
        )
    end
end

function FrogPrinceWheelViewBg:onExit()
end

return FrogPrinceWheelViewBg
