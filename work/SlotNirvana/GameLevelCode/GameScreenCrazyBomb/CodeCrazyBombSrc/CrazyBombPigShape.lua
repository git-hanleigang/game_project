---
--island
--2018年6月5日
--CrazyBombPigShape.lua
local CrazyBombPigShape = class("CrazyBombPigShape", util_require("base.BaseView"))

CrazyBombPigShape.m_press = nil
CrazyBombPigShape.m_bg = nil
CrazyBombPigShape.m_data = nil
CrazyBombPigShape.m_vecBrick = nil
CrazyBombPigShape.m_result = nil
CrazyBombPigShape.shape = nil
CrazyBombPigShape.m_spineNode = nil
CrazyBombPigShape.m_rect = nil

function CrazyBombPigShape:initUI(data)

   
    
    -- self.m_bg = self:findChild("CrazyBomb_Bonus_BG_1")
    self.m_data = data
    self.shape = string.sub(data.csbName, 21, 23)

    self.m_machine = data.m_machine

    local spineName =  "CrazyBomb_Spine_chip"  
    local width, height = 0, 0
    local scaleWidth, scaleHeight = 0, 0
    if self.shape == "1x2" then
        width = 240
        height = 316
        spineName =  "CrazyBomb_Spine_chip2" 
        scaleWidth, scaleHeight = 1, 1
    elseif self.shape == "1x3" then
        width = 193
        height = 502
        spineName =  "CrazyBomb_Spine_chip3" 
        scaleWidth, scaleHeight = 1, 1
    elseif self.shape == "2x2" then
        width = 389
        height = 241
        spineName =  "CrazyBomb_Spine_chip4" 
        scaleWidth, scaleHeight = width/880, height/545
    elseif self.shape == "2x3" then
        width = 409
        height = 254
        spineName =  "CrazyBomb_Spine_chip4" 
        scaleWidth, scaleHeight = width/880, height/545
    elseif self.shape == "3x2" then
        width = 491
        height = 304
        spineName =  "CrazyBomb_Spine_chip4" 
        scaleWidth, scaleHeight = width/880, height/545
    elseif self.shape == "3x3" then
        width = 589
        height = 366
        spineName =  "CrazyBomb_Spine_chip4" 
        scaleWidth, scaleHeight = width/880, height/545
    elseif self.shape == "4x2" then
        width = 506
        height = 313
        spineName =  "CrazyBomb_Spine_chip4" 
        scaleWidth, scaleHeight = width/880, height/545
    elseif self.shape == "4x3" then
        width = 785
        height = 486
        spineName =  "CrazyBomb_Spine_chip4" 
        scaleWidth, scaleHeight = width/880, height/545
    elseif self.shape == "5x2" then
        width = 604
        height = 375
        spineName =  "CrazyBomb_Spine_chip4" 
        scaleWidth, scaleHeight = width/880, height/545
    
    elseif self.shape == "5x3" then
        width = 880
        height = 545
        spineName =  "CrazyBomb_Spine_chip4" 
        scaleWidth, scaleHeight = 1, 1
    end

    self.m_spineNode = util_spineCreateDifferentPath(spineName, "CrazyBomb_Spine_chip", true, true)
    self:addChild(self.m_spineNode)
    self.m_spineNode:setScaleX(scaleWidth)
    self.m_spineNode:setScaleY(scaleHeight)

    local gold_width, gold_height = 0, 0

    if self.shape == "1x2" then
        gold_width = 194
        gold_height = 316
    elseif self.shape == "1x3" then
        gold_width = 194
        gold_height = 474
    elseif self.shape == "2x2" then
        gold_width = 388
        gold_height = 316
    elseif self.shape == "2x3" then
        gold_width = 388
        gold_height = 474
    elseif self.shape == "3x2" then
        gold_width = 582
        gold_height = 316

    elseif self.shape == "3x3" then
        gold_width = 582
        gold_height = 474
 
    elseif self.shape == "4x2" then
        gold_width = 776
        gold_height = 316

    elseif self.shape == "4x3" then
        gold_width = 776
        gold_height = 474

    elseif self.shape == "5x2" then
        gold_width = 970
        gold_height = 316
    elseif self.shape == "5x3" then
        gold_width = 970
        gold_height = 474
    end

    if self.m_rect == nil then
        self.m_rect = {}
    end
    self.m_rect.x = -gold_width * 0.5
    self.m_rect.y = -gold_height * 0.5
    self.m_rect.width = gold_width
    self.m_rect.height = gold_height

    local info = {}
    info.width = gold_width 
    info.height = gold_height 
    info.shape = string.sub(data.csbName, 21, 23)
    local bg = util_createView("CodeCrazyBombSrc.CrazyBombBombBg")
    bg:setVisible(false)
    bg:changeImage(info)
    self:addChild(bg,-1)
    bg:setName("bg")

end


function CrazyBombPigShape:onEnter()
    
end

function CrazyBombPigShape:onExit()
    
end

function CrazyBombPigShape:runAnim(animName,loop,func)
    util_spinePlay(self.m_spineNode, animName, loop)
    if func ~= nil then
          util_spineEndCallFunc(self.m_spineNode, animName, func)
    end

end

function CrazyBombPigShape:initWithTouchEvent()

    local function onTouchBegan_callback(touch, event)
        
        local pos = self:convertToNodeSpaceAR(touch:getLocation())  
        if cc.rectContainsPoint(self.m_rect, pos) then
            return true
        end
        return false
    end

    local function onTouchMoved_callback(touch, event)
    end

    local function onTouchEnded_callback(touch, event)
        local pos = self:convertToNodeSpaceAR(touch:getLocation()) 
        if cc.rectContainsPoint(self.m_rect, pos) then
            self:clickFunc()
        end
    end
    
    local listener = cc.EventListenerTouchOneByOne:create()
    listener:setSwallowTouches(false)
    listener:registerScriptHandler(onTouchBegan_callback,cc.Handler.EVENT_TOUCH_BEGAN )
    listener:registerScriptHandler(onTouchMoved_callback,cc.Handler.EVENT_TOUCH_MOVED )
    listener:registerScriptHandler(onTouchEnded_callback,cc.Handler.EVENT_TOUCH_ENDED )
    local eventDispatcher = self:getEventDispatcher()    
    eventDispatcher:addEventListenerWithSceneGraphPriority(listener, self)
end

function CrazyBombPigShape:addPress(vecBrick, result)
    local act = nil
    self.m_press, act = util_csbCreate("Socre_CrazyBomb_pass.csb")
    self:getParent():addChild(self.m_press, 100000)
    self.m_press:setPosition(self:getPosition())
    util_csbPlayForKey(act, "idle", true)
    local bg = self.m_press:getChildByName("pressBtn")
    -- self.m_press:setScaleX(self.m_rect.width / bg:getContentSize().width)
    -- self.m_press:setScaleY(self.m_rect.height / bg:getContentSize().height)
    self.m_vecBrick = vecBrick
    self.m_result = result
    self:initWithTouchEvent()

    local scale = nil
    if self.shape == "2x2" or self.shape == "2x3" then
        scale = 0.66 
    elseif self.shape == "3x2" or self.shape == "3x3" or self.shape == "4x2" then
        scale = 0.9
    elseif self.shape == "4x3" then
        scale = 1.18
    elseif self.shape == "5x2" then
        scale = 0.97
    elseif self.shape == "5x3" then
        scale = 1.41
    end
    self.m_press:setScale(scale)
end

function CrazyBombPigShape:clickFunc()
    gLobalSoundManager:playSound("CrazyBombSounds/sound_CrazyBomb_pree.mp3") 
    self.m_press:removeFromParent()
    local eventDispatcher = self:getEventDispatcher()
    eventDispatcher:removeEventListenersForTarget(self,true)
    gLobalSoundManager:playSound("CrazyBombSounds/sound_CrazyBomb_pig_break.mp3")

    self:runAnim("over")

    self.m_spineNode:registerSpineEventHandler(function(event)    --通过registerSpineEventHandler这个方法注册

        if event.animation == "over" then  --根据动作名来区分
            
            if event.eventData.name == "show" then  --根据帧事件来区分
                -- gLobalSoundManager:pauseBgMusic()
                local data = {}
                data.width = self.m_rect.width
                data.height = self.m_rect.height
                data.vecBrick = self.m_vecBrick 
                data.num = self.m_result
                data.shape = self.shape
                data.pos = {x = self:getPositionX(), y = self:getPositionY()}
                self:setVisible(false)
                gLobalSoundManager:playSound("CrazyBombSounds/sound_CrazyBomb_brick_run.mp3")
                local golden = util_createView("CodeCrazyBombSrc.CrazyBombBrickView")
                golden:initFeatureUI(data)
                self:getParent():addChild(golden,REEL_SYMBOL_ORDER.REEL_ORDER_2)
                golden:setPosition(self:getPosition()) 
                golden:setOverCallBackFun(
                    function()
                        gLobalNoticManager:postNotification("breakBiggerPigShape", data.num)
                    end
                )
                local brick = {}
                brick.node = golden
                brick.width = self.m_data.width
                golden:retain()
                brick.cloumnIndex = self.m_data.cloumnIndex
                brick.rowIndex = self.m_data.rowIndex
                self.m_data.vecCrazyBombBrick[#self.m_data.vecCrazyBombBrick + 1] = brick
            end
            if event.eventData.name == "boom" then
                self.m_machine.m_BreakTu:setVisible(true)
                self.m_machine.m_BreakTu:runCsbAction("actionframe1",false,function(  )
                    self.m_machine.m_BreakTu:setVisible(false)
                end)
                self.m_machine:runCsbAction("doudong1")
                gLobalSoundManager:playSound("CrazyBombSounds/sound_CrazyBomb_brick_stop.mp3")
            end
        end
    end,sp.EventType.ANIMATION_EVENT) 

end


return CrazyBombPigShape