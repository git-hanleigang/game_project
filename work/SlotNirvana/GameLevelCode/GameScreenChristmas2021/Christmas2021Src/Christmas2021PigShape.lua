---
--island
--2018年6月5日
--Christmas2021PigShape.lua
local Christmas2021PigShape = class("Christmas2021PigShape", util_require("base.BaseView"))

Christmas2021PigShape.m_press = nil
Christmas2021PigShape.m_bg = nil
Christmas2021PigShape.m_data = nil
Christmas2021PigShape.m_vecBrick = nil
Christmas2021PigShape.m_result = nil
Christmas2021PigShape.shape = nil
Christmas2021PigShape.m_spineNode = nil
Christmas2021PigShape.m_rect = nil

function Christmas2021PigShape:initUI(data)
    self.m_data = data
    self.shape = data.shape

    self.m_machine = data.m_machine

    local spineName =  "Socre_Christmas2021_bonus_1x1"  
    local width, height = 0, 0
    if self.shape == "2x1" then
        width = 240
        height = 316
        spineName =  "Socre_Christmas2021_bonus_2x1" 
    elseif self.shape == "3x1" then
        width = 193
        height = 538
        spineName =  "Socre_Christmas2021_bonus_3x1" 
    elseif self.shape == "2x2" then
        width = 427
        height = 379
        spineName =  "Socre_Christmas2021_bonus_2x2" 
    elseif self.shape == "3x2" then
        width = 469
        height = 327
        spineName =  "Socre_Christmas2021_bonus_3x2" 
    elseif self.shape == "2x3" then
        width = 549
        height = 384
        spineName =  "Socre_Christmas2021_bonus_2x3" 
    elseif self.shape == "3x3" then
        width = 687
        height = 480
        spineName =  "Socre_Christmas2021_bonus_3x3" 
    elseif self.shape == "2x4" then
        width = 549
        height = 384
        spineName =  "Socre_Christmas2021_bonus_2x4" 
    elseif self.shape == "3x4" then
        width = 769
        height = 538
        spineName =  "Socre_Christmas2021_bonus_3x4" 
    elseif self.shape == "2x5" then
        width = 947
        height = 394
        spineName =  "Socre_Christmas2021_bonus_2x5" 
    elseif self.shape == "3x5" then
        width = 769
        height = 538
        spineName =  "Socre_Christmas2021_bonus_3x5" 
    end

    -- 创建大的合图
    self.m_spineNode = util_spineCreate(spineName, true, true)
    self:addChild(self.m_spineNode)

    local gold_width, gold_height = 0, 0

    if self.shape == "2x1" then
        gold_width = 220
        gold_height = 320
    elseif self.shape == "3x1" then
        gold_width = 220
        gold_height = 480
    elseif self.shape == "2x2" then
        gold_width = 442
        gold_height = 320
    elseif self.shape == "3x2" then
        gold_width = 442
        gold_height = 480
    elseif self.shape == "2x3" then
        gold_width = 664
        gold_height = 320

    elseif self.shape == "3x3" then
        gold_width = 664
        gold_height = 480
 
    elseif self.shape == "2x4" then
        gold_width = 886
        gold_height = 320

    elseif self.shape == "3x4" then
        gold_width = 886
        gold_height = 480

    elseif self.shape == "2x5" then
        gold_width = 1108
        gold_height = 320
    elseif self.shape == "3x5" then
        gold_width = 1108
        gold_height = 480
    end

    if self.m_rect == nil then
        self.m_rect = {}
    end
    self.m_rect.x = -gold_width * 0.5
    self.m_rect.y = -gold_height * 0.5
    self.m_rect.width = gold_width
    self.m_rect.height = gold_height

    local info = {}
    info.shape = data.shape
    local bg = util_createView("Christmas2021Src.Christmas2021BombBg")
    bg:setVisible(false)
    bg:changeImage(info)
    self:addChild(bg,-1)
    bg:setName("bg")

end


function Christmas2021PigShape:onEnter()
    
end

function Christmas2021PigShape:onExit()
    
end

--[[
    时间线
]]
function Christmas2021PigShape:runAnim(animName,loop,func)
    util_spinePlay(self.m_spineNode, animName, loop)
    if func ~= nil then
          util_spineEndCallFunc(self.m_spineNode, animName, func)
    end

end

--[[
    2x2以上的合图结算的时候 回滚动
]]
function Christmas2021PigShape:addPress(vecBrick, result)

    self.m_vecBrick = vecBrick
    self.m_result = result
    self:clickFunc()
end

function Christmas2021PigShape:clickFunc()

    local eventDispatcher = self:getEventDispatcher()
    eventDispatcher:removeEventListenersForTarget(self,true)
    gLobalSoundManager:playSound("Christmas2021Sounds/sound_Christmas2021_brick_open.mp3")

    self:runAnim("actionframe1", false, function()
        self:setVisible(false)
    end)

    self.m_spineNode:registerSpineEventHandler(function(event)    --通过registerSpineEventHandler这个方法注册

        if event.animation == "actionframe1" then  --根据动作名来区分
            
            if event.eventData.name == "show" then  --根据帧事件来区分
                -- gLobalSoundManager:pauseBgMusic()
                local data = {}
                data.width = self.m_rect.width
                data.height = self.m_rect.height
                data.vecBrick = self.m_vecBrick 
                data.num = self.m_result
                data.shape = self.shape
                data.pos = {x = self:getPositionX(), y = self:getPositionY()}
                gLobalSoundManager:playSound("Christmas2021Sounds/sound_Christmas2021_brick_run.mp3")
                local golden = util_createView("Christmas2021Src.Christmas2021BrickView")

                golden:initFeatureUI(data, self.m_machine)
                self:getParent():addChild(golden,REEL_SYMBOL_ORDER.REEL_ORDER_2)
                golden:setPosition(self:getPosition()) 
                golden:setOverCallBackFun(
                    function()
                        gLobalNoticManager:postNotification("breakBiggerPigShape", data.num)
                    end
                )

                util_csbPlayForKey(golden.m_goldenAct,"actionframe",false)
                local brick = {}
                brick.node = golden
                brick.width = self.m_data.width
                brick.cloumnIndex = self.m_data.cloumnIndex
                brick.rowIndex = self.m_data.rowIndex
                brick.data = data
                brick.data.isMulti = true
                -- brick.data.num = data.num * globalData.slotRunData:getCurTotalBet()
                self.m_data.vecCrazyBombBrick[#self.m_data.vecCrazyBombBrick + 1] = brick
                if self:getChildByName("bg") then
                    self:getChildByName("bg"):removeFromParent()
                end
            end

        end
    end,sp.EventType.ANIMATION_EVENT) 
end

return Christmas2021PigShape