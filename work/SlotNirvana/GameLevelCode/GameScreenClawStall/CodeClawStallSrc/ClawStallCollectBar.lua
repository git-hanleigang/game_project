---
--xcyy
--2018年5月23日
--ClawStallCollectBar.lua
local PublicConfig = require "ClawStallPublicConfig"
local ClawStallCollectBar = class("ClawStallCollectBar",util_require("Levels.BaseLevelDialog"))

local BTN_TAG_SHOW_MAP      =       1001        --显示地图
local BTN_TAG_SHOW_TIP      =       1002        --显示提示

function ClawStallCollectBar:initUI(params)
    self.m_machine = params.machine
    self.m_isClickMap = false
    self.m_isClickTip = false
    self.m_lockStatus = false
    self:createCsbNode("ClawStall_Base_Progress.csb")

    --当前收集进度
    self.m_curPercent = 0

    --光效
    self.m_lightAni = util_createAnimation("ClawStall_jindutiao.csb")
    self:findChild("jindutiao"):addChild(self.m_lightAni)
    self.m_lightAni:runCsbAction("idle",true)

    --收集光效
    self.m_collectAni = util_createAnimation("ClawStall_jindutiao.csb")
    self:findChild("jindutiao2"):addChild(self.m_collectAni)
    self.m_collectAni:setVisible(false)

    --提示
    self.m_tip = util_createAnimation("ClawStall_Base_CollectionTips.csb")
    self.m_machine:findChild("Node_CollectionTips"):addChild(self.m_tip)
    self.m_tip:setVisible(false)

    --点击区域
    self:findChild("Button_info"):setTag(BTN_TAG_SHOW_TIP)
    local layout = self:findChild("layout")
    layout:setTag(BTN_TAG_SHOW_MAP)
    self:addClick(layout)

    --金币点击区域
    local coinLayout = ccui.Layout:create()  
    coinLayout:setAnchorPoint(0.5,0.5)
    coinLayout:setContentSize(CCSizeMake(120,120))
    coinLayout:setTouchEnabled(true)
    coinLayout:setPosition( cc.p(0,0) )
    coinLayout:setTag(BTN_TAG_SHOW_MAP)
    self:findChild("Node_Jinbi"):addChild( coinLayout )
    self:addClick( coinLayout )
end

--[[
    更新进度
]]
function ClawStallCollectBar:updateProcess(isInit)
    local collectProcess = self.m_machine.m_collectProcess
    local selfData = self.m_machine.m_runSpinResultData.p_selfMakeData

    local loadingBar = self:findChild("loadingBar")
    local size = loadingBar:getContentSize()
    local percent = collectProcess.collect / collectProcess.target
    if not isInit and selfData.type then
        percent = 1
    end

    loadingBar:stopAllActions()

    local posX = size.width / 2 - size.width * (1 - percent)
    if isInit or percent <= self.m_curPercent then
        loadingBar:setPositionX(posX)
        self.m_collectAni:setVisible(false)
    elseif percent > self.m_curPercent then
        local seq = cc.Sequence:create({
            cc.MoveTo:create(40 / 60,cc.p(posX,loadingBar:getPositionY())),
            cc.CallFunc:create(function()
                
                if percent == 1 then
                    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_ClawStall_collect_full)
                    self.m_collectAni:runCsbAction("actionframe2",true)
                    self:runCsbAction("actionframe",false,function(  )
                        self:runCsbAction("idle")
                    end)
                else
                    self.m_collectAni:setVisible(false)
                end
            end)
        })
        loadingBar:runAction(seq)
        self.m_collectAni:setVisible(true)
        self.m_collectAni:runCsbAction("actionframe",true)
        -- 
    end
    

    self.m_curPercent = percent
end

--[[
    设置锁定状态
]]
function ClawStallCollectBar:setLockStatus(isLock)
    if isLock then
        self:runCsbAction("suoding")
    else
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_ClawStall_unlock)
        self:runCsbAction("jiesuo")
    end

    self.m_lockStatus = isLock
end


--默认按钮监听回调
function ClawStallCollectBar:clickFunc(sender)
    
    if not self.m_machine:collectBarClickEnabled() then
        return
    end

    local name = sender:getName()
    local tag = sender:getTag()
    if tag == BTN_TAG_SHOW_MAP then
        if self.m_lockStatus then
            self.m_machine.m_bottomUI:changeBetCoinNumToHight()
            return
        end
        if self.m_isClickMap then
            return
        end
        self.m_isClickMap = true
        self.m_machine:showMapView(function(  )
            self.m_isClickMap = false
        end)
    else
        if self.m_tip:isVisible() then
            self:hideTip()
        else
            self:showTip()
        end
    end
    
end

--[[
    显示提示
]]
function ClawStallCollectBar:showTip(func)
    if self.m_isClickTip then
        return
    end
    self.m_isClickTip = true
    self.m_tip:setVisible(true)
    self.m_tip:runCsbAction("start",false,function(  )
        self.m_isClickTip = false
        if type(func) == "function" then
             func()
        end
    end)
    performWithDelay(self.m_tip,function(  )
        self:hideTip()
    end,4)
end

--[[
    隐藏提示
]]
function ClawStallCollectBar:hideTip(func)
    if self.m_isClickTip then
        return
    end
    self.m_isClickTip = true
    self.m_tip:stopAllActions()
    self.m_tip:runCsbAction("over",false,function(  )
        self.m_tip:setVisible(false)
        self.m_isClickTip = false
        if type(func) == "function" then
             func()
        end
    end)
end

return ClawStallCollectBar