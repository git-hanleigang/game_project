---
--xcyy
--2018年5月23日
--TreasureToadJackPotBarView.lua

local TreasureToadJackPotBarView = class("TreasureToadJackPotBarView",util_require("Levels.BaseLevelDialog"))
local PublicConfig = require "TreasureToadPublicConfig"

local GrandName = "m_lb_grand"
local MajorName = "m_lb_major"
local MinorName = "m_lb_minor"
local MiniName = "m_lb_mini" 

local sprite_name = {
    "Sprite_mini",
    "Sprite_minor",
    "Sprite_major",
    "Sprite_grand"
}

function TreasureToadJackPotBarView:initUI()

    self:createCsbNode("TreasureToad_JackPotBar.csb")
    self:resetCurRefreshTime()
    self.m_lockStatus = false
    self:addIdleSpine()
    self:addLockSpine()
    self:findChild("Node_3"):setVisible(false)

    
    --创建点击区域
    local layout = ccui.Layout:create() 
    self:findChild("root"):addChild(layout)    
    layout:setAnchorPoint(0.5,0.5)
    local pos = util_convertToNodeSpace(self:findChild("Image_7"),self:findChild("root"))
    layout:setPosition(pos)
    layout:setContentSize(CCSizeMake(384,83))
    layout:setTouchEnabled(true)
    self:addClick(layout,1000)

    self.lightList = {}
    self:addLightingNode()
end

function TreasureToadJackPotBarView:addIdleSpine()
    self.grandAct = util_spineCreate("TreasureToad_JackPotBar", true, true)
    local majorAct = util_spineCreate("TreasureToad_JackPotBar", true, true)
    local minorAct = util_spineCreate("TreasureToad_JackPotBar", true, true)
    local miniAct = util_spineCreate("TreasureToad_JackPotBar", true, true)
    self:findChild("idle_grand"):addChild(self.grandAct)
    self:findChild("idle_major"):addChild(majorAct)
    self:findChild("idle_minor"):addChild(minorAct)
    self:findChild("idle_mini"):addChild(miniAct)
    util_spinePlay(self.grandAct,"idle_grand",true)
    util_spinePlay(majorAct,"idle_major",true)
    util_spinePlay(minorAct,"idle_minor",true)
    util_spinePlay(miniAct,"idle_mini",true)
end


function TreasureToadJackPotBarView:addLockSpine()
    self.lockSpine = util_spineCreate("TreasureToad_JackPotBar", true, true)
    self:findChild("lock_unlock"):addChild(self.lockSpine)
end

--lock_grand    lock_idle   unlock_grand
function TreasureToadJackPotBarView:showLockAct(isInit,isLock)
    if isLock then
        if not isInit then
            gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_TreasureToad_betLock)
        end
        util_spinePlay(self.lockSpine,"lock_grand")
        self.m_lockStatus = true
    else
        if not isInit then
            gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_TreasureToad_betUnLock)
        end
        util_spinePlay(self.lockSpine,"unlock_grand")
        local particle = self:findChild("Particle_1")
        if particle then
            particle:resetSystem()
        end
        self.m_lockStatus = false
    end
end

function TreasureToadJackPotBarView:triggerJackpotBar(index)
    self:showLightingNode(index)
end

function TreasureToadJackPotBarView:addLightingNode()
    for i,v in ipairs(sprite_name) do
        local light = util_createAnimation("TreasureToad_JackPotBar_tx.csb")  
        self:findChild(sprite_name[i]):addChild(light)
        light:setVisible(false)
        self.lightList[#self.lightList + 1] = light
    end
end

function TreasureToadJackPotBarView:showLightingNode(index)
    if index then
        for i,v in ipairs(self.lightList) do
            if self.lightList[i] then
                if index == i then
                    self.lightList[i]:setVisible(true)
                    self.lightList[i]:runCsbAction("actionframe",true)
                else
                    self.lightList[i]:setVisible(false)
                end
            end
            
            
        end
    else
        for i,v in ipairs(self.lightList) do
            if self.lightList[i] then
                self.lightList[i]:setVisible(false)
            end
            
            
        end
    end
end

function TreasureToadJackPotBarView:initMachine(machine)
    self.m_machine = machine
end

function TreasureToadJackPotBarView:onEnter()

    TreasureToadJackPotBarView.super.onEnter(self)

    util_setCascadeOpacityEnabledRescursion(self,true)
    schedule(self,function()
        self:updateJackpotInfo()
    end,0.08)
end

function TreasureToadJackPotBarView:onExit()
    TreasureToadJackPotBarView.super.onExit(self)
end

-- 更新jackpot 数值信息
--
function TreasureToadJackPotBarView:updateJackpotInfo()
    if not self.m_machine then
        return
    end
    local data=self.m_csbOwner

    --公共jackpot
    --获取当前jackpot状态
    local status = self.m_machine.m_jackpot_status
    if status == "Normal" then
        self:changeNode(self:findChild(GrandName),1,true)
    else
        self.m_curTime = self.m_curTime + 0.08

        local time     = math.min(120, self.m_curTime)
        local addTimes = time/0.08 
        local jackpotValue = self.m_machine:getCommonJackpotValue(status, addTimes)
        local ml_b_coins_grand = self:findChild(GrandName)
        ml_b_coins_grand:setString(util_formatCoins(jackpotValue,50))
    end

    self:changeNode(self:findChild(MajorName),2,true)
    self:changeNode(self:findChild(MinorName),3)
    self:changeNode(self:findChild(MiniName),4)

    self:updateSize()
end

function TreasureToadJackPotBarView:updateSize()

    local label1=self.m_csbOwner[GrandName]
    local label2=self.m_csbOwner[MajorName]
    local info1={label=label1,sx=1,sy=1}
    local info2={label=label2,sx=1,sy=1}
    local label3=self.m_csbOwner[MinorName]
    local info3={label=label3,sx=1,sy=1}
    local label4=self.m_csbOwner[MiniName]
    local info4={label=label4,sx=1,sy=1}
    self:updateLabelSize(info1,264)
    self:updateLabelSize(info2,277)
    self:updateLabelSize(info3,211)
    self:updateLabelSize(info4,211)
end

function TreasureToadJackPotBarView:changeNode(label,index,isJump)
    local value=self.m_machine:BaseMania_updateJackpotScore(index)
    label:setString(util_formatCoins(value,20,nil,nil,true))
end

--默认按钮监听回调
function TreasureToadJackPotBarView:clickFunc(sender)
    if self.m_lockStatus then
        gLobalNoticManager:postNotification("SHOW_BONUS_MAP")
    end
end

--------------------------------公共jackpot-------------------------------------------------
--[[
    重置刷新时间
]]
function TreasureToadJackPotBarView:resetCurRefreshTime()
    self.m_curTime = 0
end

function TreasureToadJackPotBarView:updateMegaShow()
    local icon_super = self:findChild("BaitEmUp_Super_zi")
    local icon_mega = self:findChild("BaitEmUp_Mega_zi")
    local icon_grand = self:findChild("BaitEmUp_Grand_zi")
    -- --获取当前jackpot状态
    local status = self.m_machine.m_jackpot_status
    icon_super:setVisible(status == "Super")
    icon_mega:setVisible(status == "Mega")
    icon_grand:setVisible(status == "Normal")

    if self.m_curStatus and self.m_curStatus ~= status and (status == "Mega" or status == "Super") then
        self:runCsbAction("switch",false,function()
            -- self:runCsbAction("idle2",true)
        end)
    else
        if status ~= "Normal" then
            self:runCsbAction("idle2",true)
        else
            self:runCsbAction("idle",true)
        end
    end
    

    self.m_curStatus = status
    
end

return TreasureToadJackPotBarView