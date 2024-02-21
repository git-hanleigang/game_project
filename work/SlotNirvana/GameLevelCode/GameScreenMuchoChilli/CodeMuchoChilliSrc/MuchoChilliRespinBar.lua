---
--xcyy
--2018年5月23日
--MuchoChilliRespinBar.lua
local MuchoChilliRespinBar = class("MuchoChilliRespinBar",util_require("Levels.BaseLevelDialog"))
local PublicConfig = require "MuchoChilliPublicConfig"

function MuchoChilliRespinBar:initUI(params)
    self.m_machine = params.machine

    self:createCsbNode("MuchoChilli_RespinTips_DoubleBoard.csb")
    self.m_respinBarNode1 = util_createAnimation("MuchoChilli_RespinBar.csb")
    self:findChild("Node_respinbar1"):addChild(self.m_respinBarNode1)

    -- 爆炸反馈three
    self.m_respinBarThreeBox1 = util_createAnimation("MuchoChilli_fankui.csb")
    self.m_respinBarNode1:findChild("spin3_0"):addChild(self.m_respinBarThreeBox1)
    self.m_respinBarThreeBox1:setVisible(false)
    -- 爆炸反馈four
    self.m_respinBarFourBox1 = util_createAnimation("MuchoChilli_fankui.csb")
    self.m_respinBarNode1:findChild("spin4"):addChild(self.m_respinBarFourBox1)
    self.m_respinBarFourBox1:setVisible(false)

    self.m_respinBarNode2 = util_createAnimation("MuchoChilli_RespinBar.csb")
    self:findChild("Node_respinbar2"):addChild(self.m_respinBarNode2)

    -- 爆炸反馈three
    self.m_respinBarThreeBox2 = util_createAnimation("MuchoChilli_fankui.csb")
    self.m_respinBarNode2:findChild("spin3_0"):addChild(self.m_respinBarThreeBox2)
    self.m_respinBarThreeBox2:setVisible(false)
    -- 爆炸反馈four
    self.m_respinBarFourBox2 = util_createAnimation("MuchoChilli_fankui.csb")
    self.m_respinBarNode2:findChild("spin4"):addChild(self.m_respinBarFourBox2)
    self.m_respinBarFourBox2:setVisible(false)
end

--[[
    刷新当前次数
]]
function MuchoChilliRespinBar:updateRespinCount(curCount, totalCount, _isComeIn)
    if totalCount == 3 then
        for index = 1,3 do
            self.m_respinBarNode1:findChild("active3_"..index):setVisible(curCount == index)
            self.m_respinBarNode2:findChild("active3_"..index):setVisible(curCount == index)
            self.m_respinBarNode1:findChild("dark3_"..index):setVisible(curCount ~= index)
            self.m_respinBarNode2:findChild("dark3_"..index):setVisible(curCount ~= index)
        end
        if curCount == totalCount then
            self:playBoxThreeFanKuiEffect(_isComeIn)
        end
    else
        for index = 1,4 do
            self.m_respinBarNode1:findChild("active4_"..index):setVisible(curCount == index)
            self.m_respinBarNode2:findChild("active4_"..index):setVisible(curCount == index)
            self.m_respinBarNode1:findChild("dark4_"..index):setVisible(curCount ~= index)
            self.m_respinBarNode2:findChild("dark4_"..index):setVisible(curCount ~= index)
        end
        if curCount == totalCount then
            self:playBoxFourFanKuiEffect(_isComeIn)
        end
    end
    self:showTextByNums(curCount)
end

--[[
    显示3次
]]
function MuchoChilliRespinBar:showThreeNumAni()
    self.m_respinBarNode1:findChild("Node_3spin"):setVisible(true)
    self.m_respinBarNode1:findChild("Node_4spin"):setVisible(false)
    self.m_respinBarNode2:findChild("Node_3spin"):setVisible(true)
    self.m_respinBarNode2:findChild("Node_4spin"):setVisible(false)
end

--[[
    显示4次
]]
function MuchoChilliRespinBar:showFourNumAni()
    self.m_respinBarNode1:findChild("Node_3spin"):setVisible(false)
    self.m_respinBarNode1:findChild("Node_4spin"):setVisible(true)
    self.m_respinBarNode2:findChild("Node_3spin"):setVisible(false)
    self.m_respinBarNode2:findChild("Node_4spin"):setVisible(true)
end

--[[
    通过棋盘个数显示不一样的计数条
    双棋盘的话 分上下
]]
function MuchoChilliRespinBar:showBarByReelNums(_reelNums, _isUp)
    if _reelNums == 1 then
        self:findChild("Node_Up"):setVisible(true)
        self:findChild("Node_Down"):setVisible(false)
    else
        if _isUp then
            self:findChild("Node_Up"):setVisible(true)
            self:findChild("Node_Down"):setVisible(false)
        else
            self:findChild("Node_Up"):setVisible(false)
            self:findChild("Node_Down"):setVisible(true)
        end
    end
    self:showThreeNumAni()
    self:showTextByNums(3)
end

--[[
    获取第四个计数位置的节点
]]
function MuchoChilliRespinBar:getFourthNode(_reelNums, _isUp)
    if _reelNums == 1 then
        return self.m_respinBarNode1:findChild("spin4")
    else
        if _isUp then
            return self.m_respinBarNode1:findChild("spin4")
        else
            return self.m_respinBarNode2:findChild("spin4")
        end
    end
end

--[[
    播放爆炸反馈动画three
]]
function MuchoChilliRespinBar:playBoxThreeFanKuiEffect(_isComeIn)
    if not _isComeIn then
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_MuchoChilli_respinNum_Three_reset)
    end

    self.m_respinBarThreeBox1:setVisible(true)
    self.m_respinBarThreeBox2:setVisible(true)
    self.m_respinBarThreeBox1:runCsbAction("csfankui", false, function()
        self.m_respinBarThreeBox1:setVisible(false)
    end)

    self.m_respinBarThreeBox2:runCsbAction("csfankui", false, function()
        self.m_respinBarThreeBox2:setVisible(false)
    end)
end

--[[
    播放爆炸反馈动画four
]]
function MuchoChilliRespinBar:playBoxFourFanKuiEffect(_isComeIn)
    if not _isComeIn then
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_MuchoChilli_respinNum_Four_reset)
    end
    self.m_respinBarFourBox1:setVisible(true)
    self.m_respinBarFourBox2:setVisible(true)
    self.m_respinBarFourBox1:runCsbAction("csfankui", false, function()
        self.m_respinBarFourBox1:setVisible(false)
    end)

    self.m_respinBarFourBox2:runCsbAction("csfankui", false, function()
        self.m_respinBarFourBox2:setVisible(false)
    end)
end

--[[
    根据剩余次数 显示不同的文本
]]
function MuchoChilliRespinBar:showTextByNums(_nums, _isEnd)
    if _isEnd then
        for index = 1, 2 do
            self:findChild("MuchoChilli_respin"..index):setVisible(false)
            self:findChild("spins_"..index):setVisible(false)
            self:findChild("Node_respinbar"..index):setVisible(false)
            self:findChild("Node_completed"..index):setVisible(true)
        end
    else
        for index = 1, 2 do
            self:findChild("MuchoChilli_respin"..index):setVisible(false)
            self:findChild("spins_"..index):setVisible(false)
            self:findChild("Node_respinbar"..index):setVisible(true)
            self:findChild("Node_completed"..index):setVisible(false)
        end
        if _nums == 1 then
            self:findChild("MuchoChilli_respin1"):setVisible(true)
            self:findChild("MuchoChilli_respin2"):setVisible(true)
        else
            self:findChild("spins_1"):setVisible(true)
            self:findChild("spins_2"):setVisible(true)
        end
    end
end

--[[
   单棋盘 双棋盘显示不同的tips
]]
function MuchoChilliRespinBar:showTips(_isDouble)
    self:findChild("text1_double"):setVisible(_isDouble)
    self:findChild("text1_single"):setVisible(not _isDouble)
end

return MuchoChilliRespinBar