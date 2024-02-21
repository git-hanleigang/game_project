---
--xcyy
--2018年5月23日
--CharmsBonusMap.lua

local CharmsBonusMap = class("CharmsBonusMap",util_require("base.BaseView"))

CharmsBonusMap.m_leftOldMan = {1, 2, 8, 9, 10, 11, 12, 13, 18, 19, 20, 21}

CharmsBonusMap.m_bTouchFlag = nil
function CharmsBonusMap:initUI(data)

    self:createCsbNode("Charms/BonusGame.csb")

    self.m_bTouchFlag = false
    self.m_bIsLeft = false
    if display.height < 1370 then
        self:findChild("root"):setScale(display.height / 1370)
    end

    if self:findChild("Image_1") then
        self:findChild("Image_1"):setTouchEnabled(true)
    end
    
end

function CharmsBonusMap:initMapUI(data)
    self.m_bonusPath = data.bonusPath
    self.m_nodePos = data.nodePos

    self.m_golds = {}
    local index = 1
    while true do
        local node = self:findChild("Node_gold" .. index )
        if node ~= nil then
            local gold = nil
            if index == 2 then
                gold = util_createView("CodeCharmsSrc.CharmsBonusMapIcon", "Charms_bonus_lamp.csb")
                node:setLocalZOrder(index)
            elseif index == 7 then
                gold = util_createView("CodeCharmsSrc.CharmsBonusMapIcon", "Charms_bonus_bomb.csb")
                node:setLocalZOrder(index)
            elseif index == 13 then
                gold = util_createView("CodeCharmsSrc.CharmsBonusMapIcon", "Charms_bonus_donky.csb")
                node:setLocalZOrder(index)
            else
                gold = util_createView("CodeCharmsSrc.CharmsBonusMapGold")
            end
            if index <= self.m_nodePos then
                gold:runAnimation("completed")
            end
            
            self.m_golds[index] = gold
            node:addChild(gold)
            
        else
            break
        end
        index = index + 1
    end

    self.m_oldManPos = {}
    local index = 1
    while true do
        local node = self:findChild("Node_oldman" .. index )
        if node ~= nil then
            self.m_oldManPos[index] = node
        else
            break
        end
        index = index + 1
    end
    local spineName = "Socre_Charms_SmallOldMan_Right"
    self.m_index = self.m_nodePos + 1
    for i = 1, #self.m_leftOldMan, 1 do
        if self.m_index == self.m_leftOldMan[i] then
            spineName = "Socre_Charms_SmallOldMan_Left"
            self.m_bIsLeft = true
            break
        end
    end

    self.m_oldMan = util_spineCreate(spineName, false, true)
    util_spinePlay(self.m_oldMan, "idleframe", true)
    self.m_oldMan:setPosition(cc.p(self.m_oldManPos[self.m_index]:getPositionX(), self.m_oldManPos[self.m_index]:getPositionY() - 50))
    self.m_oldManPos[self.m_index]:getParent():addChild(self.m_oldMan)

    self:setVisible(false)
end

function CharmsBonusMap:updateOldManPos()
    local spineName = "Socre_Charms_SmallOldMan_Right"
    self.m_index = self.m_nodePos + 1
    for i = 1, #self.m_leftOldMan, 1 do
        if self.m_index == self.m_leftOldMan[i] then
            spineName = "Socre_Charms_SmallOldMan_Left"
            self.m_bIsLeft = true
            break
        end
    end
    if spineName == "Socre_Charms_SmallOldMan_Right" then
        self.m_bIsLeft = false
    end

    self.m_oldMan:removeFromParent(true)
    self.m_oldMan = util_spineCreate(spineName, false, true)
    util_spinePlay(self.m_oldMan, "idleframe", true)
    self.m_oldMan:setPosition(cc.p(self.m_oldManPos[self.m_index]:getPositionX(), self.m_oldManPos[self.m_index]:getPositionY() - 50))
    self.m_oldManPos[self.m_index]:getParent():addChild(self.m_oldMan)
end

function CharmsBonusMap:resetMapUI()
    self.m_oldMan:removeFromParent(true)
    self.m_oldMan = util_spineCreate("Socre_Charms_SmallOldMan_Left", false, true)
    util_spinePlay(self.m_oldMan, "idleframe", true)
    self.m_oldMan:setPosition(cc.p(self.m_oldManPos[1]:getPositionX(), self.m_oldManPos[1]:getPositionY() - 50))
    self.m_oldManPos[1]:getParent():addChild(self.m_oldMan)

    for i = 1, #self.m_golds, 1 do
        local gold = self.m_golds[i]
        if i == 2 or i == 7 or i == 13 then
            gold:runAnimation("actionframe", true)
        else
            gold:runAnimation("idleframe", true)
        end
        
    end
end

function CharmsBonusMap:onEnter()
    CharmsBonusMap.super.onEnter(self)
    
end

function CharmsBonusMap:appear(func, nodePos)
    if self:isVisible() == false then
        self:setVisible(true)
    end

    

    gLobalSoundManager:playSound("CharmsSounds/sound_Charms_map_appear.mp3")
    if func ~= nil then

        self:findChild("backBtn"):setVisible(false)
        self:findChild("Charms_suolian_1"):setVisible(false)
        self:findChild("Charms_suolian_1_0"):setVisible(false)
    else
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_PAUSE_SLOTSMACHINE)
        self:findChild("backBtn"):setVisible(true)
        self:findChild("suolian_1"):setVisible(true)
        self:findChild("suolian_2"):setVisible(true)
        self:findChild("Charms_suolian_1"):setVisible(true)
        self:findChild("Charms_suolian_1_0"):setVisible(true)
    end

    self:setVisible(true)

    self:runCsbAction("start", false, function()
        self:runCsbAction("idle", true)
        self.m_bTouchFlag = true
        if func ~= nil then
            self.m_bTouchFlag = false
            -- performWithDelay(self, function()
            --     self:tramcarMove(func, nodePos)
            -- end, 1)
            self:tramcarMove(func, nodePos)
        end
    end)
end

function CharmsBonusMap:tramcarMove(func, nodePos)
    self.m_nodePos = nodePos
    self.m_index = self.m_nodePos + 1
    local pos = cc.p(self.m_oldManPos[self.m_index]:getPositionX(), self.m_oldManPos[self.m_index]:getPositionY() - 50)
    local moveTime = 1
    if self.m_index == 3 or self.m_index == 8 or self.m_index == 14 then
        pos = cc.p(self.m_oldManPos[self.m_index - 1]:getPositionX(), self.m_oldManPos[self.m_index - 1]:getPositionY() - 50)
        moveTime = 0
    end
    local moveTo = cc.MoveTo:create(moveTime, pos)
    if moveTime ~= 0 then
        performWithDelay(self, function()
            gLobalSoundManager:playSound("CharmsSounds/sound_Charms_tramcar_move.mp3")
        end, 0.5)
    end
    

    local callback = cc.CallFunc:create(function()
        
        performWithDelay(self, function()
            if self.m_golds[self.m_nodePos] ~= nil then
                if moveTime ~= 0 then
                    gLobalSoundManager:playSound("CharmsSounds/sound_Charms_open_small_level.mp3")
                else
                    gLobalSoundManager:playSound("CharmsSounds/sound_Charms_open_big_level.mp3")
                end
                self.m_golds[self.m_nodePos]:runAnimation("animation0", false, function()
                    if func ~= nil then
                        performWithDelay(self, function()
                            gLobalSoundManager:playSound("CharmsSounds/sound_Charms_map_disappear.mp3")
                            self:runCsbAction("over", false, function()
                                self:setVisible(false)
                                if self.m_index == 3 or self.m_index == 8 or self.m_index == 14 or self.m_index == 18 then
                                    self:updateOldManPos()
                                end
                                performWithDelay(self,function()
                                    func()
                                end, 1)
                            end)
                        end, 1)
                    end
                end)
            else
                if func ~= nil then
                    performWithDelay(self, function()
                        gLobalSoundManager:playSound("CharmsSounds/sound_Charms_map_disappear.mp3")
                        self:runCsbAction("over", false, function()
                            self:setVisible(false)
                            performWithDelay(self,function()
                                func()
                            end, 1)
                        end)
                    end, 2)
                    
                end
            end
        end, 0.2)
    end)
    self.m_oldMan:runAction(cc.Sequence:create(cc.DelayTime:create(0.5), moveTo, callback))
    if self.m_golds[self.m_nodePos] == nil then
        performWithDelay(self, function()
            gLobalSoundManager:playSound("CharmsSounds/sound_Charms_open_final_level.mp3")
            util_spinePlay(self.m_oldMan, "disappear", false)
            self:runCsbAction("actionframe")
        end, 0.8)
    end
end

function CharmsBonusMap:onExit()
    
end

--默认按钮监听回调
function CharmsBonusMap:clickFunc(sender)
    self:closeUI()
end

function CharmsBonusMap:closeUI()
    if self.m_bTouchFlag == false then
        return
    end
    gLobalSoundManager:playSound("CharmsSounds/sound_Charms_map_disappear.mp3")
    self.m_bTouchFlag = false
    self:runCsbAction("over", false, function()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_RESUME_SLOTSMACHINE)
        self:setVisible(false)
    end)
end

return CharmsBonusMap