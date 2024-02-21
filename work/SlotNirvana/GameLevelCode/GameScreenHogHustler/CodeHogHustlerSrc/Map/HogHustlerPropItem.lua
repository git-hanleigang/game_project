---
--xcyy
--2018年5月23日
--HogHustlerPropItem.lua

local HogHustlerPropItem = class("HogHustlerPropItem",util_require("Levels.BaseLevelDialog"))
local HogHustlerMapConfig = require("CodeHogHustlerSrc.HogHustlerMapConfig")
local HogHustlerMusic = util_require("CodeHogHustlerSrc.HogHustlerMusic")

function HogHustlerPropItem:initUI(data, map)
    self.m_propType = data.propType
    self.m_index = data.index
    self.m_zorder = data.zorder
    self.m_map = map
    local csbNameTab = {
        [HogHustlerMapConfig.PropType.Dice] = "HogHustler_Dice.csb",
        [HogHustlerMapConfig.PropType.Box] = "HogHustler_map_Box.csb",
        [HogHustlerMapConfig.PropType.Key] = "HogHustler_map_yaoshi.csb",
        [HogHustlerMapConfig.PropType.Coins] = "HogHustler_map_jinbi.csb",
        [HogHustlerMapConfig.PropType.CoinsBox] = "HogHustler_map_Box.csb",
        [HogHustlerMapConfig.PropType.DiceBox] = "HogHustler_map_Box.csb",
        [HogHustlerMapConfig.PropType.KeyBox] = "HogHustler_map_Box.csb",
        [HogHustlerMapConfig.PropType.BuffBox] = "HogHustler_map_Box.csb",
    }
    assert(csbNameTab[self.m_propType], "!!error,道具类型出错"..self.m_propType)
    self:createCsbNode(csbNameTab[self.m_propType])
    if self:isFixBox() then
        self:findChild("HogHustler_map_BoxL2_jinbi_1"):setVisible(false)
        -- self.m_boxUp = util_spineCreate("HogHustler_Prop_Box1", true, true)
        -- self.m_boxDown = util_spineCreate("HogHustler_Prop_Box2", true, true)
        -- self:findChild("box_up"):addChild(self.m_boxUp)
        -- self:findChild("box_down"):addChild(self.m_boxDown)
        if self.m_propType ~= HogHustlerMapConfig.PropType.Box and  self.m_propType ~= HogHustlerMapConfig.PropType.CoinsBox then
            local propNameTab = {
                [HogHustlerMapConfig.PropType.DiceBox] = "HogHustler_Dice.csb",
                [HogHustlerMapConfig.PropType.KeyBox] = "HogHustler_map_yaoshi.csb",
                [HogHustlerMapConfig.PropType.BuffBox] = "HogHustler_More.csb",
            }
            self.m_prop = util_createAnimation(propNameTab[self.m_propType])
            if self.m_propType == HogHustlerMapConfig.PropType.BuffBox then
                self:findChild("more"):addChild(self.m_prop)
            elseif self.m_propType == HogHustlerMapConfig.PropType.DiceBox then
                self:findChild("dice"):addChild(self.m_prop)
            elseif self.m_propType == HogHustlerMapConfig.PropType.KeyBox then
                self:findChild("yaoshi"):addChild(self.m_prop)
            else
                --理论不会进 防
                self:findChild("Node_dian"):addChild(self.m_prop)
            end
            
            self.m_prop:setVisible(false)
        elseif self.m_propType == HogHustlerMapConfig.PropType.CoinsBox then
            self.m_prop = util_createAnimation("HogHustler_xiaozhu_jinbi_0.csb")
            self.m_prop:setVisible(false)
            -- self.m_label = util_createAnimation("HogHustler_xiaozhu_jinbi_zi.csb")
            -- self.m_label:setVisible(false)
            -- self:findChild("box_prop"):addChild(self.m_label)
            self:findChild("more"):addChild(self.m_prop)
            self:findChild("HogHustler_map_BoxL2_jinbi_1"):setVisible(true)
        end
    elseif self.m_propType == HogHustlerMapConfig.PropType.Coins then
        self.m_prop = util_createAnimation("HogHustler_xiaozhu_jinbi_0.csb")
        self.m_prop:setVisible(false)
        self.m_prop:setScale(0.7)
        -- self.m_label = util_createAnimation("HogHustler_xiaozhu_jinbi_zi.csb")
        -- self.m_label:setVisible(false)
        -- self:addChild(self.m_label)
        self:addChild(self.m_prop)
    end
    self:playIdle()
end

function HogHustlerPropItem:isFixBox()
    local isBox = false
    if self.m_propType == HogHustlerMapConfig.PropType.Box or
       self.m_propType == HogHustlerMapConfig.PropType.CoinsBox or
       self.m_propType == HogHustlerMapConfig.PropType.DiceBox or
       self.m_propType == HogHustlerMapConfig.PropType.KeyBox or
       self.m_propType == HogHustlerMapConfig.PropType.BuffBox  then
        isBox = true
    end
    return isBox
end


function HogHustlerPropItem:onEnter()
    HogHustlerPropItem.super.onEnter(self)
    self:changePropZorder()
    gLobalNoticManager:addObserver(self,function(self,index)
        self:changePropZorder(index)
    end,"PROP_CHANGE_Z_SMELLYRICH")
end

function HogHustlerPropItem:onExit()
    HogHustlerPropItem.super.onExit(self)
    gLobalNoticManager:removeAllObservers(self)

end

--默认按钮监听回调
function HogHustlerPropItem:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

end

function HogHustlerPropItem:changePropZorder(index)
    if index and index == self.m_index then
        self:setLocalZOrder(300)
    else
        self:setLocalZOrder(self.m_zorder)
    end
end

function HogHustlerPropItem:playIdle()
    -- if self.m_propType == HogHustlerMapConfig.PropType.Box then
    --     self:playBoxAni("idle", true)        
    -- else
    --     self:runCsbAction("idle", true)
    -- end

    self:runCsbAction("idle", true)
end

function HogHustlerPropItem:playBoxAni(aniNam, isLoop, endFunc)
    if not aniNam then
        return
    end
    -- util_spinePlay(self.m_boxUp, aniNam, isLoop)
    -- util_spinePlay(self.m_boxDown, aniNam, isLoop)
    if endFunc and type(endFunc) == "function" then
        -- util_spineEndCallFunc(self.m_boxUp, aniNam, endFunc)

        endFunc()
    end
end

--显示道具效果
function HogHustlerPropItem:showEffect(win, isFirst)
    if isFirst then
        if self.m_propType == HogHustlerMapConfig.PropType.Key then
            self:showFirstKeyEffect(win)
        elseif self.m_propType == HogHustlerMapConfig.PropType.Dice then
            self:showFirstDiceEffect(win)
        elseif self.m_propType == HogHustlerMapConfig.PropType.BuffBox then
            self:showBoxEffect(win, isFirst)
        end
    else
        

        if self.m_propType == HogHustlerMapConfig.PropType.Key then
            self:showKeyEffect(win)
            -- self:showFirstKeyEffect(win)
        elseif self.m_propType == HogHustlerMapConfig.PropType.Dice then
            self:showDiceEffect(win)
            -- self:showFirstDiceEffect(win)
        elseif self.m_propType == HogHustlerMapConfig.PropType.Coins then
            self:showCoinsEffect(win)
        elseif self:isFixBox() and self.m_propType ~= HogHustlerMapConfig.PropType.Box and self.m_propType ~= HogHustlerMapConfig.PropType.CoinsBox then
            self:showBoxEffect(win, isFirst)
        elseif self.m_propType == HogHustlerMapConfig.PropType.CoinsBox then
            self:showBoxCoinEffect(win)
        end
    end
end

--显示道具
function HogHustlerPropItem:showProp()
    self:waitWithDelay(0.5, function()
        self:setVisible(true)
        if self.m_propType == HogHustlerMapConfig.PropType.Box then
            self:playBoxAni("start", false, function()
                self:playIdle()
            end)        
        else
            self:runCsbAction("start", false, function()
                self:playIdle()
            end)
        end
    end)
end

function HogHustlerPropItem:hideProp()
    self:setVisible(false)
end

--钥匙
function HogHustlerPropItem:showKeyEffect(win)
    -- self:runCsbAction("shouji")
    -- self:waitWithDelay(1, function()

    --     local endPos = self.m_map:getBoxKeyPos()
    --     local action_list = {}
    --     action_list[#action_list + 1] = cc.MoveTo:create(0.5, endPos)
    --     action_list[#action_list + 1] = cc.CallFunc:create(function()

    --         self:runCsbAction("actionframe", false, function()
    --              self:removeFromParent()
    --         end, 60)
    --         self:waitWithDelay(2/3, function()
    --             self.m_map:showPigEffect(win)
    --         end)
    --     end)
    --     local sq = cc.Sequence:create(action_list)
    --     self:runAction(sq)
    -- end)

    gLobalSoundManager:playSound(HogHustlerMusic.sound_HogHustler_monopoly_props_key_scale2big2fly)
    self:runCsbAction("fly")
    self:waitWithDelay(40/60, function()

        local endPos, keyNode = self.m_map:getBoxKeyWorldPos()

            
        endPos = self:getParent():convertToNodeSpace(endPos)
        endPos = cc.pSub(cc.p(endPos), cc.p(self:findChild("Node_2"):getPosition()))
        local action_list = {}
        action_list[#action_list + 1] = cc.MoveTo:create(30/60, endPos)
        action_list[#action_list + 1] = cc.CallFunc:create(function()

            gLobalSoundManager:playSound(HogHustlerMusic.sound_HogHustler_monopoly_props_key_flyend)
            local wPos1 = self:getParent():convertToWorldSpace(cc.p(self:getPosition()))
            util_changeNodeParent(keyNode, self, 10)
            local nodePos = keyNode:convertToNodeSpace(cc.p(wPos1))
            self:setPosition(cc.p(nodePos))

            -- self:runCsbAction("actionframe", false, function()
            --      self:removeFromParent()
            -- end, 60)
            self.m_map:showPigEffect(win)
            self:waitWithDelay(40/60, function()
                
                self:removeFromParent()
            end)
        end)
        local sq = cc.Sequence:create(action_list)
        self:runAction(sq)
    end)
end
--骰子
function HogHustlerPropItem:showDiceEffect(win)
    -- gLobalSoundManager:playSound("HogHustlerSounds/sound_smellyRich_propDice_action.mp3")
    gLobalSoundManager:playSound(HogHustlerMusic.sound_HogHustler_monopoly_props_dice_scale2big)
    self:runCsbAction("actionframe")
    self:waitWithDelay(1, function()
        self:runCsbAction("fly")

        gLobalSoundManager:playSound(HogHustlerMusic.sound_HogHustler_monopoly_props_dice_fly2spin)
        -- local endPos = self.m_map:getDiceBttonPos()
        local endPos = self.m_map.m_mainMap:getDiceBttonWorldPos()

        endPos = self:getParent():convertToNodeSpace(endPos)

        local action_list = {}
        action_list[#action_list + 1] = cc.MoveTo:create(1/3, endPos)
        action_list[#action_list + 1] = cc.CallFunc:create(function()

            gLobalNoticManager:postNotification("MAP_DICE_NUM_SMELLYRICH")
            -- gLobalSoundManager:playSound("HogHustlerSounds/sound_smellyRich_propDice_fankui.mp3")
            gLobalSoundManager:playSound(HogHustlerMusic.sound_HogHustler_monopoly_props_dice_flyend)

            self:setVisible(false)
            self:waitWithDelay(30/60, function()
                self:propEffectOver()
                
                self:removeFromParent()
        
            end)
            
        end)
        --action_list[#action_list + 1] = cc.DelayTime:create(0.2)
        -- action_list[#action_list + 1] = cc.RemoveSelf:create()
        local sq = cc.Sequence:create(action_list)
        self:runAction(sq)
    end)
end

--金币
function HogHustlerPropItem:showCoinsEffect(win)
    self:runCsbAction("actionframe", false, function()
        self:runCsbAction("idle2", true)
    end)
    self:waitWithDelay(1, function()
        if self.m_prop then
            self.m_prop:setVisible(true)

            gLobalSoundManager:playSound(HogHustlerMusic.sound_HogHustler_monopoly_props_coinsfly2allwin_begin)
            local numLabel = util_createAnimation("HogHustler_xiaozhu_jinbi_4.csb")
            local coinStr = util_formatCoins(win, 3)
            numLabel:findChild("m_lb_coins"):setString(coinStr)
            self:addChild(numLabel, 100)
            numLabel:runCsbAction("actionframe", false, function()
            end)

            self:findChild("jinbidui"):setVisible(false)
            -- self.m_label:setVisible(true)
            -- self:runCsbAction("over")
            self.m_prop:playAction("actionframe")
            -- self.m_label:playAction("actionframe")
            -- self.m_label:findChild("m_lb_coins"):setString(util_formatCoins(win, 3))
            self:waitWithDelay(15/60, function()
                -- gLobalSoundManager:playSound("HogHustlerSounds/sound_smellyRich_coinsBox_fly.mp3")
                local endPos = self.m_map:getAllWinLabelWorldPos()
                endPos = self:convertToNodeSpace(endPos)
                local action_list = {}
                action_list[#action_list + 1] = cc.EaseIn:create(cc.MoveTo:create(0.5, endPos), 7) 
                action_list[#action_list + 1] = cc.CallFunc:create(function()

                    gLobalSoundManager:playSound(HogHustlerMusic.sound_HogHustler_monopoly_props_coinsfly2allwin_end)

                    gLobalNoticManager:postNotification("MAP_ADD_COINS_SMELLYRICH", {win, 30})
                    self:propEffectOver(true)
                    self:removeFromParent()
                end)
                local sq = cc.Sequence:create(action_list)
                self.m_prop:runAction(sq)
            end)
        end
        
    end)

end

function HogHustlerPropItem:showBoxEffect(win, isFirst)

    if self.m_propType == HogHustlerMapConfig.PropType.BuffBox then
        if self.m_prop then
            self.m_prop:findChild("m_lb_num"):setString(win.."%")
        end
    end


    gLobalSoundManager:playSound(HogHustlerMusic.sound_HogHustler_monopoly_props_boxopen)
    self:runCsbAction("actionframe", false, function()
        self:waitWithDelay(0.2, function()
            if self.m_propType == HogHustlerMapConfig.PropType.KeyBox then
                self:showBoxKeyEffect(win)
            elseif self.m_propType == HogHustlerMapConfig.PropType.DiceBox then
                self:showBoxDiceEffect(win)
            elseif self.m_propType == HogHustlerMapConfig.PropType.BuffBox then
                if isFirst then
                    self:showFirstStartEffect(win)
                else
                    self:showBoxStarEffect(win)
                end
                
            end
        end)
        
    end)
    --挂载箱子东西的挂点为Node_dian，在第10帧播放HogHustler_map_yaoshi.csd的start时间线，同时在第20帧把层级调到最上
    self:waitWithDelay(10/60, function()
        if self.m_prop then
            self.m_prop:setVisible(true)
            self.m_prop:playAction("start")

            if isFirst and self.m_propType == HogHustlerMapConfig.PropType.BuffBox then
                gLobalSoundManager:playSound(HogHustlerMusic.sound_HogHustler_monopoly_guide_buff_appear)
            end
        end
    end)
    self:waitWithDelay(20/60, function()
        local propNodes = {"Node_dian", "more", "dice", "yaoshi"}
        for i=1,#propNodes do
            local propNode = self:findChild(propNodes[i])
            if propNode then
                propNode:setLocalZOrder(100)
            end
        end
    end)
    
end

--金币宝箱
function HogHustlerPropItem:showBoxCoinEffect(win)


    gLobalSoundManager:playSound(HogHustlerMusic.sound_HogHustler_monopoly_props_boxopen)
    --宝箱打开，出现钱堆，展示0.2s，随后钱堆分散开，飞到ALL win里
    self:runCsbAction("actionframe", false, function()
        self:waitWithDelay(0.2, function()
            if self.m_prop then
                self.m_prop:setVisible(true)
                self.m_prop:playAction("actionframe")
                self.m_prop:setScale(0.7)

                gLobalSoundManager:playSound(HogHustlerMusic.sound_HogHustler_monopoly_props_coinsfly2allwin_begin)

                local wPos = self.m_prop:getParent():convertToWorldSpace(cc.p(self.m_prop:getPosition()))
                util_changeNodeParent(self:findChild("Node_1"), self.m_prop, 10)
                local nodePos = self:findChild("Node_1"):convertToNodeSpace(cc.p(wPos))
                self.m_prop:setPosition(cc.p(nodePos))

                local numLabel = util_createAnimation("HogHustler_xiaozhu_jinbi_4.csb")
                local coinStr = util_formatCoins(win, 3)
                numLabel:findChild("m_lb_coins"):setString(coinStr)
                self:findChild("more"):addChild(numLabel, 100)
                numLabel:runCsbAction("actionframe", false, function()
                end)

                self:waitWithDelay(15/60, function()
                    -- gLobalSoundManager:playSound("HogHustlerSounds/sound_smellyRich_coinsBox_fly.mp3")

                    if self.m_prop then
                        self:runCsbAction("over", false)
                        local endPos = self.m_map:getAllWinLabelWorldPos()
                        endPos = self:convertToNodeSpace(endPos)
                        local action_list = {}
                        action_list[#action_list + 1] = cc.EaseIn:create(cc.MoveTo:create(0.5, endPos), 7) 
                        action_list[#action_list + 1] = cc.CallFunc:create(function()
                            gLobalSoundManager:playSound(HogHustlerMusic.sound_HogHustler_monopoly_props_coinsfly2allwin_end)

                            gLobalNoticManager:postNotification("MAP_ADD_COINS_SMELLYRICH", {win, 30})
                            self:propEffectOver(true)
                            self:removeFromParent()
                        end)
                        local sq = cc.Sequence:create(action_list)
                        self.m_prop:runAction(sq)
                    end
                    
                end)
                
            end
        end)
        
    end)
    --挂载箱子东西的挂点为Node_dian，在第10帧播放HogHustler_map_yaoshi.csd的start时间线，同时在第20帧把层级调到最上
    self:waitWithDelay(10/60, function()
        if self.m_prop then
            -- self.m_prop:setVisible(true)
            -- self.m_prop:playAction("start")
        end
    end)
    self:waitWithDelay(20/60, function()
        local propNode = self:findChild("more")
        if propNode then
            propNode:setLocalZOrder(100)
        end
    end)

end

--宝箱钥匙
function HogHustlerPropItem:showBoxKeyEffect(win)
    if self.m_prop then
        self.m_prop:runCsbAction("fly")
        gLobalSoundManager:playSound(HogHustlerMusic.sound_HogHustler_monopoly_props_key_scale2big2fly)
        
        local wPos = self.m_prop:getParent():convertToWorldSpace(cc.p(self.m_prop:getPosition()))
        util_changeNodeParent(self:findChild("Node_1"), self.m_prop, 10)
        local nodePos = self:findChild("Node_1"):convertToNodeSpace(cc.p(wPos))
        self.m_prop:setPosition(cc.p(nodePos))
        -- local wPos = self.m_prop:getParent():convertToWorldSpace(cc.p(self.m_prop:getPosition()))
        -- util_changeNodeParent(self.m_map.m_pig, self.m_prop, 10)
        -- local nodePos = self.m_map.m_pig:convertToNodeSpace(cc.p(wPos))
        -- self.m_prop:setPosition(cc.p(nodePos))

        self:waitWithDelay(40/60, function()

            local endPos, keyNode = self.m_map:getBoxKeyWorldPos()

            endPos = self:findChild("Node_1"):convertToNodeSpace(endPos)

            endPos = cc.pSub(cc.p(endPos), cc.p(self.m_prop:findChild("Node_2"):getPosition()))
            local action_list = {}
            action_list[#action_list + 1] = cc.MoveTo:create(30/60, endPos)
            action_list[#action_list + 1] = cc.CallFunc:create(function()

                gLobalSoundManager:playSound(HogHustlerMusic.sound_HogHustler_monopoly_props_key_flyend)

                local wPos1 = self.m_prop:getParent():convertToWorldSpace(cc.p(self.m_prop:getPosition()))
                util_changeNodeParent(keyNode, self.m_prop, 10)
                local nodePos = keyNode:convertToNodeSpace(cc.p(wPos1))
                self.m_prop:setPosition(cc.p(nodePos))

                -- self.m_prop:runCsbAction("actionframe", false, function()
                    -- self:removeFromParent()
                -- end, 60)
                self.m_map:showPigEffect(win)
                self:waitWithDelay(40/60, function()
                    if self.m_prop and not tolua.isnull(self.m_prop) then
                        self.m_prop:removeFromParent()
                    end
                    self:removeFromParent()
                end)
            end)
            local sq = cc.Sequence:create(action_list)
            self.m_prop:runAction(sq)

            self:runCsbAction("over")
        end)
    end

end

--宝箱骰子
function HogHustlerPropItem:showBoxDiceEffect(win)
    if self.m_prop then
        -- gLobalSoundManager:playSound("HogHustlerSounds/sound_smellyRich_propDice_action.mp3")
        gLobalSoundManager:playSound(HogHustlerMusic.sound_HogHustler_monopoly_props_dice_scale2big)
        self.m_prop:runCsbAction("actionframe")
        self:waitWithDelay(1, function()
            self.m_prop:runCsbAction("fly")


            local wPos = self.m_prop:getParent():convertToWorldSpace(cc.p(self.m_prop:getPosition()))
            util_changeNodeParent(self:findChild("Node_1"), self.m_prop, 10)
            local nodePos = self:findChild("Node_1"):convertToNodeSpace(cc.p(wPos))
            self.m_prop:setPosition(cc.p(nodePos))


            -- gLobalSoundManager:playSound("HogHustlerSounds/sound_smellyRich_propDice_fly.mp3")
            gLobalSoundManager:playSound(HogHustlerMusic.sound_HogHustler_monopoly_props_dice_flyend)
            self.m_prop:findChild("Particle_1"):resetSystem()
            self.m_prop:findChild("Particle_1"):setPositionType(0)
            self.m_prop:findChild("Particle_1"):setDuration(-1)
            self.m_prop:findChild("Particle_2"):resetSystem()
            self.m_prop:findChild("Particle_2"):setPositionType(0)
            self.m_prop:findChild("Particle_2"):setDuration(-1)

            local endPos = self.m_map.m_mainMap:getDiceBttonWorldPos()
            endPos = self:findChild("dice"):convertToNodeSpace(endPos)
            -- local endPos = self.m_map:getDiceBttonPos()
            -- endPos = cc.pSub(cc.p(endPos), cc.p(self:findChild("Node_dian"):getPosition()))
            local action_list = {}
            action_list[#action_list + 1] = cc.MoveTo:create(0.25, endPos)
            action_list[#action_list + 1] = cc.CallFunc:create(function()
                self.m_prop:findChild("Particle_1"):stopSystem()
                self.m_prop:findChild("Particle_2"):stopSystem()
                gLobalNoticManager:postNotification("MAP_DICE_NUM_SMELLYRICH")
                -- gLobalSoundManager:playSound("HogHustlerSounds/sound_smellyRich_propDice_fankui.mp3")
                gLobalSoundManager:playSound(HogHustlerMusic.sound_HogHustler_monopoly_props_dice_flyend)

                self:setVisible(false)
                self:waitWithDelay(30/60, function()
                    self:propEffectOver()
                    
                    self:removeFromParent()
            
                end)

            end)
            --action_list[#action_list + 1] = cc.DelayTime:create(0.2)
            -- action_list[#action_list + 1] = cc.RemoveSelf:create()
            local sq = cc.Sequence:create(action_list)
            self.m_prop:runAction(sq)

            self:runCsbAction("over")
        end)
    end
end

--宝箱徽章
function HogHustlerPropItem:showBoxStarEffect(win)
    if self.m_prop then
        -- self.m_prop:runCsbAction("actionframe")
        self:waitWithDelay(1, function()
            -- gLobalSoundManager:playSound("HogHustlerSounds/sound_smellyRich_start_fly.mp3")
            gLobalSoundManager:playSound(HogHustlerMusic.sound_HogHustler_monopoly_props_box_bufffly)
            self.m_prop:runCsbAction("fly")

            local wPos = self.m_prop:getParent():convertToWorldSpace(cc.p(self.m_prop:getPosition()))
            util_changeNodeParent(self:findChild("Node_1"), self.m_prop, 10)
            local nodePos = self:findChild("Node_1"):convertToNodeSpace(cc.p(wPos))
            self.m_prop:setPosition(cc.p(nodePos))

            -- local endPos = self.m_map:getLevelStartPos()
            local endPos = self.m_map:getLevelStartWorldPos()
            endPos = self:findChild("more"):convertToNodeSpace(endPos)
            -- endPos = cc.pSub(cc.p(endPos), cc.p(self:findChild("Node_dian"):getPosition()))
            local action_list = {}
            -- local act1 = cc.MoveTo:create(1/3, endPos)
            -- local act2 = cc.ScaleTo:create(1/3, 2.2)
            -- action_list[#action_list + 1] = cc.Spawn:create(act1, act2)
            action_list[#action_list + 1] = cc.MoveTo:create(1/3, endPos)
            action_list[#action_list + 1] = cc.CallFunc:create(function()

                gLobalNoticManager:postNotification("MAP_BADGE_NUM_SMELLYRICH")
                self:propEffectOver()

                self:removeFromParent()
            end)
            --action_list[#action_list + 1] = cc.DelayTime:create(0.2)
            -- action_list[#action_list + 1] = cc.RemoveSelf:create()
            local sq = cc.Sequence:create(action_list)
            self.m_prop:runAction(sq)


            self:runCsbAction("over")
        end)
    end

end

function HogHustlerPropItem:propEffectOver(isChange)
    gLobalNoticManager:postNotification("MAP_OVER_SMELLYRICH", isChange)
end

--新手引导钥匙
function HogHustlerPropItem:showFirstKeyEffect(win)
    gLobalSoundManager:playSound(HogHustlerMusic.sound_HogHustler_monopoly_props_key_scale2big2fly)
    self:runCsbAction("fly2")
    local action_list1 = {}
    action_list1[#action_list1 + 1] = cc.MoveTo:create(40/60, cc.p(0, 0))
    local sq1 = cc.Sequence:create(action_list1)
    self:runAction(sq1)
    self:waitWithDelay(20/60, function()
        self.m_map:showMask()
    end)
    self:waitWithDelay(40/60, function()

        self.m_map:showGuide(1, win)

        self:removeFromParent()
    end)
end


--新手引导徽章
function HogHustlerPropItem:showFirstStartEffect(win)

    if self.m_prop then
        gLobalSoundManager:playSound(HogHustlerMusic.sound_HogHustler_monopoly_guide_buff_fly2center)
        self.m_prop:runCsbAction("fly2")
        self:runCsbAction("over", false, function()
        end)
        local action_list1 = {}
        
        local worldPos = self.m_map.m_mainMap:getDafuwengWorldPos()
        local endPos = self.m_prop:getParent():convertToNodeSpace(cc.p(worldPos))
        action_list1[#action_list1 + 1] = cc.MoveTo:create(40/60, endPos)
        local sq1 = cc.Sequence:create(action_list1)
        self.m_prop:runAction(sq1)
        self:waitWithDelay(20/60, function()
            self.m_map:showMask()
        end)
        self:waitWithDelay(40/60, function()

            self.m_map:showGuide(3, win)

            self.m_prop:removeFromParent()
            self:removeFromParent()
        end)
    end

    
end

--新手引导骰子
function HogHustlerPropItem:showFirstDiceEffect(win)
    self:runCsbAction("fly2")
    local action_list1 = {}
    action_list1[#action_list1 + 1] = cc.MoveTo:create(40/60, cc.p(0, 0))
    local sq1 = cc.Sequence:create(action_list1)
    self:runAction(sq1)
    self:waitWithDelay(20/60, function()
        self.m_map:showMask()
    end)
    self:waitWithDelay(40/60, function()

        self.m_map:showGuide(2, win)

        self:removeFromParent()

    end)
end

--延时
function HogHustlerPropItem:waitWithDelay(time, endFunc, parent)
    time = time or 0
    if time == 0 then
        if endFunc then
            endFunc()
        end
        return
    end
    local waitNode = cc.Node:create()
    if parent then
        parent:addChild(waitNode)
    else
        self:addChild(waitNode)
    end
    performWithDelay(waitNode, function(  )
        if endFunc then
            endFunc()
        end
        waitNode:removeFromParent()
    end, time)
end

return HogHustlerPropItem