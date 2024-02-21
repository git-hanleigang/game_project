---
--island
--2018年6月5日
--GoldenPigPigShape.lua
local GoldenPigPigShape = class("GoldenPigPigShape", util_require("base.BaseView"))

GoldenPigPigShape.m_press = nil
GoldenPigPigShape.m_bg = nil
GoldenPigPigShape.m_data = nil
GoldenPigPigShape.m_vecBrick = nil
GoldenPigPigShape.m_result = nil
GoldenPigPigShape.shape = nil
GoldenPigPigShape.m_spineNode = nil
GoldenPigPigShape.m_rect = nil

function GoldenPigPigShape:initUI(data)

    -- self.m_spineNode = util_spineCreateDifferentPath(data.csbName, "goldpig_bg", true, true)
    self.m_spineNode = util_spineCreate(data.csbName, true, true)
    
    -- self.m_bg = self:findChild("GoldenPig_Bonus_BG_1")
    self.m_data = data
    self.shape = string.sub(data.csbName, 19, 21)
    
    self:addChild(self.m_spineNode)
    local width, height = 0, 0

    if self.shape == "1x2" then
        width = 168
        height = 288
    elseif self.shape == "1x3" then
        width = 168
        height = 432
    elseif self.shape == "2x2" then
        width = 340
        height = 288
    elseif self.shape == "2x3" then
        width = 340
        height = 432
    elseif self.shape == "3x2" then
        width = 512
        height = 288
    elseif self.shape == "3x3" then
        width = 512
        height = 432
    elseif self.shape == "4x2" then
        width = 684
        height = 288
    elseif self.shape == "5x2" then
        width = 856
        height = 288
    elseif self.shape == "4x3" then
        width = 684
        height = 432
    elseif self.shape == "5x3" then
        width = 856
        height = 432
    end

    if self.m_rect == nil then
        self.m_rect = {}
    end
    self.m_rect.x = -width * 0.5
    self.m_rect.y = -height * 0.5
    self.m_rect.width = width
    self.m_rect.height = height
end

function GoldenPigPigShape:onEnter()
    
end

function GoldenPigPigShape:onExit()
    
end

function GoldenPigPigShape:runAnim(animName,loop,func)
    util_spinePlay(self.m_spineNode, animName, loop)
    if func ~= nil then
          util_spineEndCallFunc(self.m_spineNode, animName, func)
    end
end

function GoldenPigPigShape:runAnimFrame(animName,loop,frameName,func, funcEnd)

    util_spinePlay(self.m_spineNode, animName, loop)
    if func ~= nil then
          util_spineFrameCallFunc(self.m_spineNode, animName, frameName, func, funcEnd)
    end
    return true
end

function GoldenPigPigShape:initWithTouchEvent()

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

function GoldenPigPigShape:addPress(vecBrick, result)
    self.m_press, self.m_act = util_csbCreate("Socre_GoldenPig_pass.csb")
    self:getParent():addChild(self.m_press, 100000)
    self.m_press:setPosition(self:getPosition())
    util_csbPlayForKey(self.m_act, "idle", true)
    local bg = self.m_press:getChildByName("GoldenPig_pressplay_light_4")
    self.m_press:setScaleX(self.m_rect.width / (bg:getContentSize().width * bg:getScaleX()))
    self.m_press:setScaleY(self.m_rect.height / (bg:getContentSize().height * bg:getScaleY()))
    self.m_vecBrick = vecBrick
    self.m_result = result
    self:initWithTouchEvent()
end

function GoldenPigPigShape:clickFunc()
    gLobalSoundManager:playSound("GoldenPigSounds/sound_GoldenPig_pree.mp3") 
    self.m_press:removeFromParent()
    local eventDispatcher = self:getEventDispatcher()
    eventDispatcher:removeEventListenersForTarget(self,true)
    gLobalSoundManager:playSound("GoldenPigSounds/sound_GoldenPig_pig_break.mp3")

    self:runAnimFrame("over", false , "show", function()
        -- gLobalSoundManager:pauseBgMusic()
        local data = {}
        data.width = self.m_rect.width
        data.height = self.m_rect.height
        data.vecBrick = self.m_vecBrick 
        data.num = self.m_result
        data.shape = self.shape
        data.pos = {x = self:getPositionX(), y = self:getPositionY()}

        gLobalSoundManager:playSound("GoldenPigSounds/sound_GoldenPig_brick_run.mp3")
        local golden = util_createView("CodeGoldenPigSrc.GoldenBrickView")
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
        self.m_data.vecGoldenBrick[#self.m_data.vecGoldenBrick + 1] = brick
        
    end, function()
        self:setVisible(false)
    end)
end
-- 如果本界面需要添加touch 事件，则从BaseView 获取

return GoldenPigPigShape