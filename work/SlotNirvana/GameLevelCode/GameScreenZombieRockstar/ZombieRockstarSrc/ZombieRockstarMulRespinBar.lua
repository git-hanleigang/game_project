---
--xcyy
--2018年5月23日
--ZombieRockstarMulRespinBar.lua
local ZombieRockstarMulRespinBar = class("ZombieRockstarMulRespinBar",util_require("Levels.BaseLevelDialog"))
local ZombieRockstarPublicConfig = require "ZombieRockstarPublicConfig"

function ZombieRockstarMulRespinBar:initUI(params)
    self.m_machine = params
    self:createCsbNode("ZombieRockstar_respin_right.csb")

    self.m_curMulNums = 0
    self.m_mulNodeList = {}
    for index = 1, 8 do
        self.m_mulNodeList[index] = util_createAnimation("ZombieRockstar_respin_num.csb")
        self:findChild("m_lb_num_"..index):addChild(self.m_mulNodeList[index])
        self.m_mulNodeList[index]:runCsbAction("idle", true)
    end
    self:playMulEffect(nil, true)
end

--[[
    滚动的时候 没出现一个锁定图标 切换一次
]]
function ZombieRockstarMulRespinBar:playMulEffect(_index, _isBuff1Tri)
    if _isBuff1Tri then
        for index = 1, 8 do
            self.m_mulNodeList[index]:runCsbAction("idle", true)
            self.m_mulNodeList[index]:findChild("m_lb_num_1"):setVisible(true)
            self.m_mulNodeList[index]:findChild("m_lb_num_2"):setVisible(false)
            self.m_mulNodeList[index]:findChild("tx"):setVisible(false)
            self.m_mulNodeList[index]:getParent():setZOrder(1)
        end
    else
        for index = 1, 8 do
            self.m_mulNodeList[index]:runCsbAction("idle", true)
            self.m_mulNodeList[index]:findChild("m_lb_num_1"):setVisible(false)
            self.m_mulNodeList[index]:findChild("m_lb_num_2"):setVisible(false)
            if index == _index then
                self.m_mulNodeList[index]:findChild("m_lb_num_2"):setVisible(true)
                self.m_mulNodeList[index]:getParent():setZOrder(100)
                self.m_mulNodeList[index]:findChild("tx"):setVisible(true)
                self.m_curMulNums = _index
            else
                self.m_mulNodeList[index]:findChild("m_lb_num_1"):setVisible(true)
                self.m_mulNodeList[index]:getParent():setZOrder(1)
                self.m_mulNodeList[index]:findChild("tx"):setVisible(false)
            end
        end
    end
end

--[[
    增长动画
]]
function ZombieRockstarMulRespinBar:playAddMulEffect(_index, _func)
    gLobalSoundManager:playSound(ZombieRockstarPublicConfig.SoundConfig.sound_ZombieRockstar_respin_jishu_move)
    for curIndex = self.m_curMulNums + 1, _index do
        performWithDelay(self, function()
            for index = 1, 8 do
                self.m_mulNodeList[index]:runCsbAction("idle", true)
                self.m_mulNodeList[index]:findChild("m_lb_num_1"):setVisible(false)
                self.m_mulNodeList[index]:findChild("m_lb_num_2"):setVisible(false)
                if index == curIndex then
                    self.m_mulNodeList[index]:findChild("m_lb_num_2"):setVisible(true)
                    self.m_mulNodeList[index]:getParent():setZOrder(100)
                    self.m_mulNodeList[index]:findChild("tx"):setVisible(true)
                else
                    self.m_mulNodeList[index]:findChild("m_lb_num_1"):setVisible(true)
                    self.m_mulNodeList[index]:getParent():setZOrder(1)
                    self.m_mulNodeList[index]:findChild("tx"):setVisible(false)
                end
            end
        end, 10/60 * (curIndex - self.m_curMulNums - 1))
    end

    local delayTime = 10/60 * (_index - self.m_curMulNums)
    performWithDelay(self, function()
        self.m_curMulNums = _index
        if _func then
            _func()
        end
    end, delayTime)
end

--[[
    中奖 播放动画
]]
function ZombieRockstarMulRespinBar:playWinMulEffect(_index, _func)
    for index = 1, 8 do
        if index == _index then
            self.m_mulNodeList[index]:getParent():setZOrder(100)
            gLobalSoundManager:playSound(ZombieRockstarPublicConfig.SoundConfig.sound_ZombieRockstar_respin_jeisuan_shanshuo)
            self.m_mulNodeList[index]:runCsbAction("idle2", false, function()
                self.m_mulNodeList[index]:runCsbAction("idle", true)
                self.m_mulNodeList[index]:getParent():setZOrder(1)
                if _func then
                    _func()
                end
            end)
            self.m_mulNodeList[index]:findChild("m_lb_num_1"):setVisible(false)
            self.m_mulNodeList[index]:findChild("m_lb_num_2"):setVisible(true)
            self.m_mulNodeList[index]:findChild("tx"):setVisible(true)
        else
            self.m_mulNodeList[index]:runCsbAction("idle", true)
            self.m_mulNodeList[index]:findChild("m_lb_num_1"):setVisible(true)
            self.m_mulNodeList[index]:findChild("m_lb_num_2"):setVisible(false)
            self.m_mulNodeList[index]:findChild("tx"):setVisible(false)
        end
    end
end

--[[
    进入respin玩法 刷新倍数赢钱显示
]]
function ZombieRockstarMulRespinBar:updateMulCoins(_symbol)
    local betValue = globalData.slotRunData:getCurTotalBet()
    local mulList = self.m_machine.m_respinMulList[tostring(_symbol)]
    for index = 1, 8 do
        self.m_mulNodeList[index]:findChild("m_lb_num_1"):setString(util_formatCoins(betValue * mulList[index], 3))
        self.m_mulNodeList[index]:findChild("m_lb_num_2"):setString(util_formatCoins(betValue * mulList[index], 3))
        self:updateLabelSize({label=self.m_mulNodeList[index]:findChild("m_lb_num_1"),sx=1,sy=1},125)
        self:updateLabelSize({label=self.m_mulNodeList[index]:findChild("m_lb_num_2"),sx=1,sy=1},125)
    end
end

--[[
    进入respin玩法 刷新倍数赢钱显示
]]
function ZombieRockstarMulRespinBar:getMulNodeByNums(_num)
    for index = 1, 8 do
        if index == _num then
            return self.m_mulNodeList[index]
        end
    end
    return self.m_mulNodeList[1]
end

--[[
    集齐15个之后 播触发动画
]]
function ZombieRockstarMulRespinBar:playTrigggerEffect(_func)
    gLobalSoundManager:playSound(ZombieRockstarPublicConfig.SoundConfig.sound_ZombieRockstar_respin_mul_trigger)
    self:runCsbAction("actionframe", false, function()
        self:runCsbAction("idle", true)
        if _func then
            _func()
        end
    end)
    self.m_machine.m_respinbar:runCsbAction("switch", false, function()
        self.m_machine.m_respinbar:showOrHideWenZi(false)
    end)
end

return ZombieRockstarMulRespinBar