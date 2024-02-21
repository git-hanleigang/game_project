---
--xcyy
--2018年5月23日
--PalaceWishCollectBar.lua

local PalaceWishCollectBar = class("PalaceWishCollectBar",util_require("Levels.BaseLevelDialog"))

local BTN_TAG_UNLOCK     =  1001    --bet解锁
local BTN_TAG_MAP        =  1002    --显示地图   

local PROGRESS_WIDTH = 590

function PalaceWishCollectBar:initUI(params)
    self.m_machine = params.machine
    self:createCsbNode("PalaceWish_jindutiao.csb")

    self.m_isUpAnimPlaying = false --上涨动画是否播放

    self.m_coinIcon = util_spineCreate("Socre_PalaceWish_Bonus", true, true)
    self:findChild("coins"):addChild(self.m_coinIcon)
    

    self.m_mapIcon = util_createAnimation("PalaceWish_jindutiao_map.csb")
    self:findChild("Node_map"):addChild(self.m_mapIcon)

    self.m_progress = self:findChild("Node_1")
    self.m_progress:setPositionX(0)

    local layout = self:findChild("clickToUnLock")
    layout:setTag(BTN_TAG_UNLOCK)
    self:addClick(layout)

    self:findChild("Button_1"):setTag(BTN_TAG_MAP)

    self:addClick(self:findChild("Panel_map"))
    self:addClick(self:findChild("Panel_bonus"))

    self.m_scheduleNode = cc.Node:create()
    self:addChild(self.m_scheduleNode)

    self:collectIdle()
    self:mapIdle()

end

--[[
    刷新收集进度
]]
function PalaceWishCollectBar:updateProgress(callback)
    local curPercent = self.m_machine:getCurCollectPercent()
    if curPercent > 1 then
        curPercent = 1
    end

    -- local oldPercent = self.m_progress:getPositionX() / PROGRESS_WIDTH * 100
    local oldPercent = self.m_progress:getPositionX() / PROGRESS_WIDTH

    local addPercent = curPercent - oldPercent

    --(40/60) 进度条特效时间     按此时间增长
    local perAdd = addPercent * 0.016 /(40/60)
    

    if self.m_percentAction ~= nil then
        self.m_scheduleNode:stopAction(self.m_percentAction)
        self.m_percentAction = nil
    end
    
    if self.m_isUpAnimPlaying == false then
        self.m_isUpAnimPlaying = true
        self:runCsbAction("actionframe", false, function (  )
            self:runCsbAction("idle", true)
            self.m_isUpAnimPlaying = false
        end)
    end
    

    self.m_percentAction = schedule(self.m_scheduleNode, function()
        oldPercent = oldPercent + perAdd
        if oldPercent >= curPercent then

            self.m_scheduleNode:stopAction(self.m_percentAction)
            self.m_percentAction = nil

            if callback then
                callback()
            end
            oldPercent = curPercent
        end
        
        self:progressEffect(oldPercent)
    end, 0.016)

end

function PalaceWishCollectBar:progressEffect(percent)
    -- self.m_progress:setPositionX(percent * 0.01 * PROGRESS_WIDTH)
    self.m_progress:setPositionX(percent * PROGRESS_WIDTH)
    -- self.m_progress:setPositionX(300)
end

function PalaceWishCollectBar:setPercent(percent)
    self:progressEffect(percent)
end

--[[
    重置收集进度
]]
function PalaceWishCollectBar:resetProgress( )
    if self.m_percentAction ~= nil then
        self.m_scheduleNode:stopAction(self.m_percentAction)
        self.m_percentAction = nil
    end

    self.m_progress:setPositionX(0)

    
end

--[[
    加锁动画
]]
function PalaceWishCollectBar:lockAni(_isInit)
    -- if type(func) == "function" then
    --     func()
    -- end
    
    self.m_machine:resetAct(self)

    if _isInit then
        self:runCsbAction("idle_lock", true)
    else
        gLobalSoundManager:playSound("PalaceWishSounds/sound_PalaceWish_base_bet_lock.mp3")
        self:runCsbAction("lock", false, function (  )
            self:runCsbAction("idle_lock", true)
        end)
    end
    
end

--[[
    解锁动画
]]
function PalaceWishCollectBar:unlockAni(_isInit)
    -- if type(func) == "function" then
    --     func()
    -- end
    
    
    self.m_machine:resetAct(self)

    if _isInit then
        self:runCsbAction("idle", true)
    else
        gLobalSoundManager:playSound("PalaceWishSounds/sound_PalaceWish_base_bet_unlock.mp3")
        self:runCsbAction("unlock", false, function (  )
            self:runCsbAction("idle", true)
        end)
    end
    
end

--左图标收集动画
function PalaceWishCollectBar:collectStart()
    util_spinePlay(self.m_coinIcon, "actionframe_shouji", false)
    local spineEndCallFunc = function()
        self:collectIdle()
    end
    util_spineEndCallFunc(self.m_coinIcon, "actionframe_shouji", spineEndCallFunc)
end

--左图标收集idle
function PalaceWishCollectBar:collectIdle()
    util_spinePlay(self.m_coinIcon, "idle_shouji", true)
end

--地图idle
function PalaceWishCollectBar:mapIdle()
    self.m_mapIcon:runCsbAction("idle", true)
end

--地图集满
function PalaceWishCollectBar:mapFull()
    self.m_mapIcon:runCsbAction("actionframe", false, function (  )
        self.m_mapIcon:runCsbAction("idle2", true)
    end)
end

--收集条集满动画
function PalaceWishCollectBar:collectFull(func)
    self.m_machine:resetAct(self)
    self:runCsbAction("actionframe2", false, function (  )
        self:runCsbAction("idle", true)
    end)

    self:mapFull()

    local rand = math.random(0, 100)
    if rand < 50 then
        gLobalSoundManager:playSound("PalaceWishSounds/sound_PalaceWish_base_collect_full_trigger1.mp3")
    else
        gLobalSoundManager:playSound("PalaceWishSounds/sound_PalaceWish_base_collect_full_trigger2.mp3")
    end
    

    performWithDelay(self, function (  )
        if func then
            func()
        end
    end, 110/60)
end

--默认按钮监听回调
function PalaceWishCollectBar:clickFunc(sender)
    local tag = sender:getTag()
    local name = sender:getName()

    local mapClick = function()
        if self.m_machine.m_nodePos then
            self.m_machine.m_MapView:updateLittleUINodeAct( self.m_machine.m_nodePos,self.m_machine.m_bonusPath )
            self.m_machine.m_MapView:showMap()
            self.m_machine.m_MapView:setCanClick(true)
        end
    end

    if tag == BTN_TAG_UNLOCK or name == "Panel_map" or name == "Panel_bonus" then
        if self.m_machine.m_iBetLevel ~= 1 then
            if self.m_machine:collectBarClickEnabled() then
                gLobalSoundManager:playSound("PalaceWishSounds/sound_PalaceWish_click.mp3")
                self.m_machine:changeBetToHighLevel()
            end
            
        else
            if self.m_machine:collectBarClickEnabled() then
                gLobalSoundManager:playSound("PalaceWishSounds/sound_PalaceWish_click.mp3")
                mapClick()
            end
            
        end
    -- elseif name == "Panel_map" or name == "Panel_bonus" then
        -- if self.m_machine.m_iBetLevel ~= 1 then
        -- else
        --     if self.m_machine:collectBarClickEnabled() then
        --         mapClick()
        --     end
        -- end
        
    elseif tag == BTN_TAG_MAP then
        if self.m_machine:collectBarClickEnabled() then
            gLobalSoundManager:playSound("PalaceWishSounds/sound_PalaceWish_click.mp3")
            self.m_machine.m_FAQ:TipClick()
        end
        
    end
    
end


return PalaceWishCollectBar