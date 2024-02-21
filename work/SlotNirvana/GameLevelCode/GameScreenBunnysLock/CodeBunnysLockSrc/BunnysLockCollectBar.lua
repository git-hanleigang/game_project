---
--xcyy
--2018年5月23日
--BunnysLockCollectBar.lua

local BunnysLockCollectBar = class("BunnysLockCollectBar",util_require("Levels.BaseLevelDialog"))

local BTN_TAG_TIP       =       1001    --提示说明
local BTN_TAG_SHOW_MAP  =       1002    --显示地图
local START_WIDTH       =       70
local MAX_WIDTH         =       749


function BunnysLockCollectBar:initUI(params)
    self.m_machine = params.machine
    self:createCsbNode("BunysLock_loadingBar.csb")

    self.m_process = util_createAnimation("BunysLock_jindutiao.csb")
    self.m_machine:findChild("Node_jindutiao"):addChild(self.m_process)
    self.m_curPercent = 0
    self.m_process:findChild("Sprite_1"):setPositionX(-MAX_WIDTH + START_WIDTH)

    self:findChild("Button_1"):setTag(BTN_TAG_TIP)
    self:findChild("btn_feature"):setTag(BTN_TAG_SHOW_MAP)
    self:addClick(self:findChild("btn_feature"))

    self.m_process:findChild("Panel_1"):setTag(BTN_TAG_SHOW_MAP)
    self:addClick(self.m_process:findChild("Panel_1"))

    self:runCsbAction("idleframe",true)

    self.m_tip = util_createAnimation("BunysLock_loadingBar_tanban.csb")
    self.m_machine.m_rootNode:addChild(self.m_tip,SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER)
    
    self.m_tip:setVisible(false)
end

function BunnysLockCollectBar:onEnter()
    BunnysLockCollectBar.super.onEnter(self)
    local pos = util_convertToNodeSpace(self:findChild("tanban"),self.m_machine.m_rootNode)
    self.m_tip:setPosition(pos) 
end

function BunnysLockCollectBar:initProcess()
    local curPercent = self.m_machine:getCurCollectPercent()
    local endPosX = (-MAX_WIDTH + START_WIDTH) + (MAX_WIDTH - START_WIDTH) * (curPercent / 100)
    self.m_process:findChild("Sprite_1"):setPositionX(endPosX)
    self.m_curPercent = curPercent
end

function BunnysLockCollectBar:updateProcess(curPercent,func)
    if curPercent < 100 then
        if type(func) == "function" then
            func()
        end
    end

    self:runCollectAni(function()
        if self.m_curPercent == 100 then
            --集满动画
            self:collectFullAni(function()
                if type(func) == "function" then
                    func()
                end
            end)
        end
    end)

    local endPosX = (-MAX_WIDTH + START_WIDTH) + (MAX_WIDTH - START_WIDTH) * (curPercent / 100)
    local seq = cc.Sequence:create({
        cc.MoveTo:create(75 / 60,cc.p(endPosX,self.m_process:findChild("Sprite_1"):getPositionY()))
    })
    self.m_process:findChild("Sprite_1"):stopAllActions()
    self.m_process:findChild("Sprite_1"):runAction(seq)

    self.m_curPercent = curPercent
end

function BunnysLockCollectBar:getPercent()
    return self.m_curPercent
end

--默认按钮监听回调
function BunnysLockCollectBar:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()
    if tag == BTN_TAG_TIP then      --显示提示
        self:clickHelp()
    elseif tag == BTN_TAG_SHOW_MAP then     --  显示地图
        if globalData.slotRunData.m_isAutoSpinAction or self.m_machine.m_mapView:isVisible() or self.m_machine.m_isRunningEffect or self.m_machine:getGameSpinStage( ) > IDLE then
            return
        end
        gLobalSoundManager:playSound("BunnysLockSounds/sound_BunnysLock_click_btn.mp3")
        self.m_machine:showMapView(false)
    end
end

--[[
    显示提示
]]
function BunnysLockCollectBar:clickHelp()
    if self.m_isWaitting or self.m_machine:getGameSpinStage( ) > IDLE or self.m_machine.m_isShowBonus then
        return
    end
    gLobalSoundManager:playSound("BunnysLockSounds/sound_BunnysLock_click_btn.mp3")
    self.m_isWaitting = true
    if self.m_tip:isVisible() then
        self:hideTip()
    else
        self.m_tip:setVisible(true)
        self.m_tip:runCsbAction("start",false,function()
            self.m_isWaitting = false
        end)
    end
end

function BunnysLockCollectBar:hideTip()
    if self.m_tip:isVisible() then
        self.m_tip:runCsbAction("over",false,function()
            self.m_isWaitting = false
            self.m_tip:setVisible(false)
        end)
    end
end

--[[
    收集动画
]]
function BunnysLockCollectBar:runCollectAni(func)
    self.m_process:runCsbAction("actionframe",false,function()
        self.m_process:runCsbAction("idleframe",true)
        if type(func) == "function" then
            func()
        end
    end)
end

--[[
    集满动画
]]
function BunnysLockCollectBar:collectFullAni(func)
    local pos = util_convertToNodeSpace(self,self.m_machine.m_rootNode)
    util_changeNodeParent(self.m_machine.m_rootNode,self,SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER)
    self:setPosition(pos)
    self:stopAllActions()
    gLobalSoundManager:playSound("BunnysLockSounds/sound_BunnysLock_collect_bar_trigger.mp3")
    self:runCsbAction("jiman",false,function()
        util_changeNodeParent(self.m_machine:findChild("Node_loadingBar"),self,SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER)
        self:setPosition(cc.p(0,0))
        self:runCsbAction("idleframe",true)
        if type(func) == "function" then
            func()
        end
    end)
end

--播放动画
function BunnysLockCollectBar:runCsbAction(key, loop, func, fps)
    if not self.m_csbAct or not key then
        if type(func) == "function" then
            func()
        end
        return
    end

    if loop then
        loop = true
    else
        loop = false
    end

    if util_csbActionExists(self.m_csbAct, key, self.__cname) then
        self.m_csbAct:play(key, loop)
    end

    if func then
        local time = util_csbGetAnimTimes(self.m_csbAct, key, fps)
        if time > 0 then
            util_performWithDelay(self, func, time)
        else
            if func then
                func()
            end
        end
    end

end

function BunnysLockCollectBar:showBarView()
    self:setVisible(true)
    self.m_process:setVisible(true)
end

function BunnysLockCollectBar:hideBarView()
    self:setVisible(false)
    self.m_process:setVisible(false)
end

return BunnysLockCollectBar