---
--xcyy
--2018年5月23日
--LeprechaunsCrockPickJackPotBarView.lua

local LeprechaunsCrockPickJackPotBarView = class("LeprechaunsCrockPickJackPotBarView",util_require("Levels.BaseLevelDialog"))

local GrandName = "m_lb_coins_1"
local MegaName = "m_lb_coins_2"
local MajorName = "m_lb_coins_3"
local MinorName = "m_lb_coins_4"
local MiniName = "m_lb_coins_5" 

local nodeName = {"Node_grand", "Node_mega", "Node_major", "Node_minor", "Node_mini"}
function LeprechaunsCrockPickJackPotBarView:initUI()

    self.m_pickCollectNode = {}
    self.m_pickCollectDarkNode = {}
    self.m_pickCollectShengJiNode = {}
    self:createCsbNode("LeprechaunsCrock_jackpot_dfdc.csb")

    for i=1,5 do
        self.m_pickCollectNode[i] = util_createAnimation("LeprechaunsCrock_jackpot_dfdc_0.csb")
        self:findChild("Node_"..i):addChild(self.m_pickCollectNode[i])
        for _, _name in ipairs(nodeName) do
            self.m_pickCollectNode[i]:findChild(_name):setVisible(false)
        end
        self.m_pickCollectNode[i]:findChild(nodeName[i]):setVisible(true)
        self.m_pickCollectNode[i]:runCsbAction("idle")

        -- 三个计数槽压暗
        self.m_pickCollectNode[i].m_darkNode = util_createAnimation("LeprechaunsCrock_dfdc_dark2.csb")
        self.m_pickCollectNode[i]:findChild("Node_dark"):addChild(self.m_pickCollectNode[i].m_darkNode)
        self.m_pickCollectNode[i].m_darkNode:setVisible(false)

        self.m_pickCollectDarkNode[i] = util_createAnimation("LeprechaunsCrock_jackpot_dfdc_dark.csb")
        self:findChild("Node_dark"..i):addChild(self.m_pickCollectDarkNode[i])
        self.m_pickCollectDarkNode[i]:setVisible(false)

        self.m_pickCollectShengJiNode[i] = util_createAnimation("LeprechaunsCrock_dfdc_jiaqiantx.csb")
        self:findChild("Node_shengji"..i):addChild(self.m_pickCollectShengJiNode[i])
        self.m_pickCollectShengJiNode[i]:setVisible(false)
    end

    --remove node mini
    self.m_removeLevelMiniNode = util_createAnimation("LeprechaunsCrock_jackpot_removed.csb")
    self:findChild("Node_mini_removed"):addChild(self.m_removeLevelMiniNode)
    self.m_removeLevelMiniNode:setVisible(false)

    --remove node minor
    self.m_removeLevelMinorNode = util_createAnimation("LeprechaunsCrock_jackpot_removed.csb")
    self:findChild("Node_minor_removed"):addChild(self.m_removeLevelMinorNode)
    self.m_removeLevelMinorNode:setVisible(false)

    --remove node major
    self.m_removeLevelMajorNode = util_createAnimation("LeprechaunsCrock_jackpot_removed.csb")
    self:findChild("Node_major_removed"):addChild(self.m_removeLevelMajorNode)
    self.m_removeLevelMajorNode:setVisible(false)

    self:runCsbAction("idleframe",true)

end

function LeprechaunsCrockPickJackPotBarView:onEnter()

    LeprechaunsCrockPickJackPotBarView.super.onEnter(self)

    util_setCascadeOpacityEnabledRescursion(self,true)
    schedule(self,function()
        self:updateJackpotInfo()
    end,0.08)
end

function LeprechaunsCrockPickJackPotBarView:onExit()
    LeprechaunsCrockPickJackPotBarView.super.onExit(self)
end

function LeprechaunsCrockPickJackPotBarView:initMachine(machine)
    self.m_machine = machine
end



-- 更新jackpot 数值信息
--
function LeprechaunsCrockPickJackPotBarView:updateJackpotInfo()
    if not self.m_machine then
        return
    end
    local data=self.m_csbOwner

    self:changeNode(self:findChild(GrandName),1,true)
    self:changeNode(self:findChild(MegaName),2,true)
    self:changeNode(self:findChild(MajorName),3)
    self:changeNode(self:findChild(MinorName),4)
    self:changeNode(self:findChild(MiniName),5)

    self:updateSize()
end

function LeprechaunsCrockPickJackPotBarView:updateSize()

    local label1=self.m_csbOwner[GrandName]
    local label2=self.m_csbOwner[MegaName]
    local info1={label=label1,sx=0.85,sy=1}
    local info2={label=label2,sx=0.81,sy=1}
    local label3=self.m_csbOwner[MajorName]
    local info3={label=label3,sx=0.81,sy=1}
    local label4=self.m_csbOwner[MinorName]
    local info4={label=label4,sx=0.81,sy=1}
    local label5=self.m_csbOwner[MiniName]
    local info5={label=label5,sx=0.81,sy=1}
    self:updateLabelSize(info1,221)
    self:updateLabelSize(info2,221)
    self:updateLabelSize(info3,221)
    self:updateLabelSize(info4,221)
    self:updateLabelSize(info5,221)
end

function LeprechaunsCrockPickJackPotBarView:changeNode(label,index,isJump)
    local value=self.m_machine:BaseMania_updateJackpotScore(index)
    label:setString(util_formatCoins(value,20,nil,nil,true))
end

--[[
    重置UI
]]
function LeprechaunsCrockPickJackPotBarView:resetUi()
    for i=1,5 do
        self.m_pickCollectNode[i]:runCsbAction("idle")
        self.m_pickCollectDarkNode[i]:setVisible(false)
        self.m_pickCollectShengJiNode[i]:setVisible(false)
        self.m_pickCollectNode[i].m_darkNode:setVisible(false)

        -- 5中jackpot的 收集位置 显示一些效果
        self.m_pickCollectNode[i]:findChild("tishi"):setVisible(true)
        self.m_pickCollectNode[i]:findChild("tishi_0"):setVisible(true)
    end 
    self:runCsbAction("idleframe",true)

    self.m_removeLevelMiniNode:setVisible(false)
    self.m_removeLevelMinorNode:setVisible(false)
    self.m_removeLevelMajorNode:setVisible(false)
end

-- 收集事件
function LeprechaunsCrockPickJackPotBarView:getProgressFlyEndPos(_jpIndex, _progressValue)
    _progressValue = math.min(3, _progressValue)

    local progressCsb = self.m_pickCollectNode[_jpIndex]
    local node = progressCsb:findChild(string.format("di_%d", _progressValue))
    local worldPos = node:getParent():convertToWorldSpace(cc.p(node:getPosition()))

    return worldPos
end

-- 飞行完毕
function LeprechaunsCrockPickJackPotBarView:playProgressFlyEndAnim(_jpIndex, _progressValue)
    local pointCsb = self.m_pickCollectNode[_jpIndex]
    gLobalSoundManager:playSound(self.m_machine.m_publicConfig.SoundConfig.sound_LeprechaunsCrock_pick_jackpot_fly_over)

    pointCsb:runCsbAction("actionframe".._progressValue, false, function()
        pointCsb:runCsbAction("idle".._progressValue, true)
    end)
end

--[[
    jackpot中奖
]]
function LeprechaunsCrockPickJackPotBarView:playJackpotWinEffect(_jackpotIndex)
    for _, _name in ipairs(nodeName) do
        self:findChild(_name):setVisible(false)
    end
    self:findChild(nodeName[_jackpotIndex]):setVisible(true)
    self:runCsbAction("actionframe", true)
    gLobalSoundManager:playSound(self.m_machine.m_publicConfig.SoundConfig.sound_LeprechaunsCrock_pick_jackpot_shanshuo)
    
    -- 其他四个未中奖的jackpot 压暗
    for _jIndex = 1, 5 do
        if _jIndex ~= _jackpotIndex then
            self.m_pickCollectDarkNode[_jIndex]:setVisible(true)
            self.m_pickCollectDarkNode[_jIndex]:runCsbAction("dark", false)
            self:playJackpotCollectDarkEffect(_jIndex)
        end
    end

    -- 5中jackpot的 收集位置 隐藏一些效果
    for _index = 1, 5 do
        self.m_pickCollectNode[_index]:findChild("tishi"):setVisible(false)
        self.m_pickCollectNode[_index]:findChild("tishi_0"):setVisible(false)
    end
    
end

--[[
    获取赢钱的jackpot 节点 父节点
]]
function LeprechaunsCrockPickJackPotBarView:getWinJackpotParentNode(_jpIndex)
    return self:findChild("m_lb_coins_".._jpIndex):getParent()
end

--[[
    获取赢钱的jackpot 节点
]]
function LeprechaunsCrockPickJackPotBarView:getWinJackpotNode(_jpIndex)
    return self:findChild("m_lb_coins_".._jpIndex)
end

--[[
    播放jackpot赢钱 升级效果
]]
function LeprechaunsCrockPickJackPotBarView:playJackpotShengJiEffect(_jpIndex)
    self.m_pickCollectShengJiNode[_jpIndex]:setVisible(true)
    self.m_pickCollectShengJiNode[_jpIndex]:runCsbAction("add", false)
end

--[[
    播放jackpot removeLevel
]]
function LeprechaunsCrockPickJackPotBarView:playJackpotRemoveLevelEffect(_index)
    gLobalSoundManager:playSound(self.m_machine.m_publicConfig.SoundConfig.sound_LeprechaunsCrock_pick_remove_fly_fankui)

    local jIndex = 5
    if _index == 1 then
        self.m_removeLevelMiniNode:setVisible(true)
        self.m_removeLevelMiniNode:runCsbAction("dark1")
        jIndex = 5
    elseif _index == 2 then
        self.m_removeLevelMinorNode:setVisible(true)
        self.m_removeLevelMinorNode:runCsbAction("dark2")
        jIndex = 4
    elseif _index == 3 then
        self.m_removeLevelMajorNode:setVisible(true)
        self.m_removeLevelMajorNode:runCsbAction("dark3")
        jIndex = 3
    end
    self:playJackpotCollectDarkEffect(jIndex)
end

--[[
    三个计数槽压暗
]]
function LeprechaunsCrockPickJackPotBarView:playJackpotCollectDarkEffect(_jpIndex)
    self.m_pickCollectNode[_jpIndex].m_darkNode:setVisible(true)
    self.m_pickCollectNode[_jpIndex].m_darkNode:runCsbAction("dark")

    self.m_pickCollectNode[_jpIndex]:findChild("tishi"):setVisible(false)
    self.m_pickCollectNode[_jpIndex]:findChild("tishi_0"):setVisible(false)
end

return LeprechaunsCrockPickJackPotBarView