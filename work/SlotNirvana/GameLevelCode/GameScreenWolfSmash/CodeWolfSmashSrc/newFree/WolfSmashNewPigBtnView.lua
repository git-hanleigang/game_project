---
--xcyy
--2018年5月23日
--WolfSmashNewPigBtnView.lua

local WolfSmashNewPigBtnView = class("WolfSmashNewPigBtnView",util_require("Levels.BaseLevelDialog"))
local PublicConfig = require "WolfSmashPublicConfig"

function WolfSmashNewPigBtnView:initUI(params)
    self.m_machine = params.machine
    self.m_pigIndex = params.index
    self.m_isFreeStart = params.isFreeStart
    self:createCsbNode("Socre_WolfSmash_xiugai_piggy.csb")
    self.m_Click = true
    self.m_auto = false
    self.m_actName = nil
    
    self:findChild("X1"):setVisible(params.index == 1)
    self:findChild("X2"):setVisible(params.index == 2)
    self:findChild("X3"):setVisible(params.index == 3)
    self:findChild("X4"):setVisible(params.index == 4)

    self:addCompletePig(params.index)
    self:addSmashPig(params.index)

    if not params.isFreeStart then
        self:addClick(self:findChild("Panel_click")) -- 非按钮节点得手动绑定监听
    end
    
end

--完整的小猪
function WolfSmashNewPigBtnView:addCompletePig(index)
    local pigSpine = util_spineCreate("Socre_WolfSmash_Bonus",true,true)
    self:findChild("Node_spine"):addChild(pigSpine,10)
    
    if index == 4 then
        pigSpine:setSkin("gold")
    else
        pigSpine:setSkin("red")
    end
    pigSpine:setVisible(true)
    self.m_pigSpine = pigSpine
end

--砸碎的小猪
function WolfSmashNewPigBtnView:addSmashPig(index)
    local smashPigSpine = util_spineCreate("Socre_WolfSmash_zkz",true,true)
    self:findChild("Node_spine"):addChild(smashPigSpine,1)
    if index == 4 then
        smashPigSpine:setSkin("gold")
    else
        smashPigSpine:setSkin("red")
    end
    smashPigSpine:setVisible(false)
    self.m_smashpigSpine = smashPigSpine
end

function WolfSmashNewPigBtnView:showSmashPigAct()
    if not tolua.isnull(self.m_pigSpine) and not tolua.isnull(self.m_smashpigSpine) then
        self.m_pigSpine:setVisible(false)
        self.m_smashpigSpine:setVisible(true)
        util_spinePlay(self.m_smashpigSpine, "jida", false)
    end
end

function WolfSmashNewPigBtnView:hideSmashPigAct()
    if not tolua.isnull(self.m_pigSpine) and not tolua.isnull(self.m_smashpigSpine) then
        self.m_pigSpine:setVisible(true)
        self.m_smashpigSpine:setVisible(false)
        self:runCsbAction("idleframe2_2",true)
        self.m_actName = "idleframe2_2"
        util_spinePlay(self.m_pigSpine, "start",false)
        util_spineEndCallFunc(self.m_pigSpine, "start",function()
            util_spinePlay(self.m_pigSpine, "idleframe2_2",true)
        end)
        
    end
end

function WolfSmashNewPigBtnView:hideSmashPigAct2()
    if not tolua.isnull(self.m_pigSpine) and not tolua.isnull(self.m_smashpigSpine) then
        self.m_pigSpine:setVisible(true)
        self.m_smashpigSpine:setVisible(false)
        self.m_actName = "darkidle"
        self:runCsbAction("darkidle")
        util_spinePlay(self.m_pigSpine, "darkidle",true)
    end
end

--对应猪播反馈
function WolfSmashNewPigBtnView:showPigFankui()
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_WolfSmash_Click_Pig_V2)
    util_spinePlay(self.m_pigSpine, "actionframe_fk",false)
end

function WolfSmashNewPigBtnView:showDarkForPig()
    if self.m_actName == "darkidle" then
        return
    end
    self.m_actName = "darkstart"
    self:runCsbAction("darkstart",false,function ()
        self.m_actName = "darkidle"
        self:runCsbAction("darkidle")
        util_spinePlay(self.m_pigSpine, "darkidle",true)
    end)
end

function WolfSmashNewPigBtnView:hideDarkForPig()
    if self.m_actName == "idleframe2_2" then
        return
    end
    self.m_actName = "darkover"
    self:runCsbAction("darkover",false,function ()
        self.m_actName = "idleframe2_2"
        self:runCsbAction("idleframe2_2")
        util_spinePlay(self.m_pigSpine, "idleframe2_2",true)
    end)
end

--[[
    自动时：点击效果完全屏蔽。非自动时：点击之后不允许点击
    @desc: 不可点击：自动时、点击后。可以点击：非自动时、下一轮spin开始前
    author:{author}
    time:2023-10-16 17:04:41
    --@isClick: 
    @return:
]]
function WolfSmashNewPigBtnView:setIsClick(isClick)
    -- if self.m_auto then
    --     self.m_Click = false
    --     return
    -- end
    self.m_Click = isClick
end

function WolfSmashNewPigBtnView:setIsAuto(isAuto)
    self.m_auto = isAuto
end

--默认按钮监听回调
function WolfSmashNewPigBtnView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()
    if not self.m_Click then
        return
    end
    self:setIsClick(false)
    -- gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_WolfSmash_click)
    if name == "Panel_click" then       --选中
        self:showPigFankui()
        self.m_actName = "idleframe2_3"
        self:runCsbAction("idleframe2_3",false,function ()
            self.m_actName = "idleframe2_2"
            self:runCsbAction("idleframe2_2",true)
        end)
        self.m_machine:setPigNodeClick(false)
        self.m_machine:stopUpdate()     --停止调度器
        self.m_machine.daojishi:runCsbAction("over",false,function ()
            self.m_machine.daojishi:setVisible(false)
        end)
        self.m_machine:setChoosePigIndex(self.m_pigIndex)   --选中下标赋值
        self.m_machine:setChooseIndexForABTest()            --主类选中的下标赋值
        self.m_machine:hideDarkAct()                        --隐藏压暗
        self.m_machine:setChooseIndexForFree(1)
        self.m_machine:setWolfNodePosition(false)           --狼移动
    end
end


--[[
    延迟回调
]]
function WolfSmashNewPigBtnView:delayCallBack(time, func)
    local waitNode = cc.Node:create()
    self:addChild(waitNode)
    performWithDelay(
        waitNode,
        function()
            waitNode:removeFromParent(true)
            waitNode = nil
            if type(func) == "function" then
                func()
            end
        end,
        time
    )

    return waitNode
end

return WolfSmashNewPigBtnView