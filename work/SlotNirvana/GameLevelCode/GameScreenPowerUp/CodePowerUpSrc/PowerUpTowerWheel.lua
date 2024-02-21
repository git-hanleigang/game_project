---
--xcyy
--2018年5月23日
--PowerUpTowerWheel.lua

local PowerUpTowerWheel = class("PowerUpTowerWheel",util_require("base.BaseView"))

PowerUpTowerWheel.m_levelItemIndex = nil
PowerUpTowerWheel.m_maxLevel = nil
PowerUpTowerWheel.levelHeight = nil
PowerUpTowerWheel.topHeight = nil
PowerUpTowerWheel.m_wheelList = {}
PowerUpTowerWheel.m_isInit = nil
PowerUpTowerWheel.m_machine = nil
PowerUpTowerWheel.m_wheelD = nil

function PowerUpTowerWheel:initUI(data)
    self.m_machine = data
    self:createCsbNode("PowerUp_bonus.csb")
    self.m_nodeLevel = self:findChild("Node_level")
    self.m_top = self:findChild("top")

    self.scoreAnima = util_createAnimation("PowerUp_bonus_xuanzhong.csb")
    self.m_nodeLevel:addChild(self.scoreAnima,100)
    self.scoreAnima:setVisible(false)

    self.topHeight = self.m_top:getContentSize().height*0.5
    self.m_wheelList = {}
end

function PowerUpTowerWheel:updateViewData(data,isReConnect)
    self.m_data = data
    self.m_isReConnect = isReConnect
    self.m_selfMakeData = data.p_selfMakeData
    if self.m_isInit == nil then--打开界面
        self.m_isInit = true
        self:initData()
    else  -- 请求数据之后 更新界面
        self:beginTowerReel(self.m_selfMakeData.index+1)
    end
end

--获取进行到哪个阶段
function PowerUpTowerWheel:checkTowerLevel()
    local index = 1
    for i=1,#self.m_selfMakeData.bonusWheel do
        if #self.m_selfMakeData.bonusWheel[i] ~= 4 then--4是包含结果的项目
            index = i
            break
        end
    end
    return index
end

function PowerUpTowerWheel:initData()
    self.m_nodeLevel:setScale(0.9)
    self.m_curPlayLevel = self:checkTowerLevel()

    self.m_maxLevel = #self.m_selfMakeData.bonusWheel--data
    self.m_wheelD  = self.m_selfMakeData.bonusWheel

    self.m_top:setPosition(0,4000+self.topHeight)

    local spaceTime = self:addLevel()
    local time1 = (self.m_maxLevel - 2)*spaceTime
    performWithDelay(self,function()
        local act = cc.MoveTo:create(time1, cc.p(0,(self.m_maxLevel-2)*self.levelHeight*(-1)))
        self.m_nodeLevel:runAction(act)
    end,spaceTime*2)

end

function PowerUpTowerWheel:addLevel()
    if self.m_levelItemIndex == nil then
        self.m_levelItemIndex = 1
    end
    local isLast = self.m_levelItemIndex == #self.m_wheelD
    local item =  util_createView("CodePowerUpSrc.PowerUpTowerLevel",{level = self.m_levelItemIndex,wheelData = self.m_wheelD[self.m_levelItemIndex],isLast = isLast,curLevel = self.m_curPlayLevel})
    if self.levelHeight == nil then
        self.levelHeight = item:getBGHeight()
    end
    local heightNum = self.levelHeight/2+(self.m_levelItemIndex-1)*self.levelHeight
    self.m_nodeLevel:addChild(item)
    self.m_wheelList[#self.m_wheelList+1] = item

    local spaceTime = 0.1
    local itemDropItem = 0.7

    if self.m_levelItemIndex == 1 then -- 第一个不走动画
        item:setPosition(0,heightNum)
        self:createLevelAni(heightNum+self.levelHeight/2,self.m_levelItemIndex+1,(spaceTime+itemDropItem)*2)
        performWithDelay(self,function()
            self.m_levelItemIndex = self.m_levelItemIndex+1
            self:addLevel()
        end,spaceTime+itemDropItem)
    else
        item:setPosition(0,2000+heightNum)



        util_playMoveToAction(item,itemDropItem,cc.p(0,heightNum - 15),function()
            globalMachineController:playBgmAndResume("PowerUpSounds/music_PowerUp_towerLevelDown"..self.m_levelItemIndex..".mp3",1,0.4,1)

            if self.m_levelItemIndex == self.m_maxLevel then

            else
                self:createLevelAni(heightNum+self.levelHeight/2,self.m_levelItemIndex+1,spaceTime+itemDropItem)
            end
            self:playItemAni(item,self.m_levelItemIndex,heightNum,spaceTime)
            self.m_levelItemIndex = self.m_levelItemIndex+1
        end)
        if self.m_levelItemIndex >= self.m_maxLevel then--顶部
            self.m_top:setPosition(0,2000+heightNum+self.topHeight)
            local topHeight = self.levelHeight*self.m_maxLevel+self.topHeight
            util_playMoveToAction(self.m_top,itemDropItem,cc.p(0,topHeight - 15),function()
                util_playMoveToAction(self.m_top,spaceTime,cc.p(0,topHeight))
            end)
        end
    end
    return spaceTime+itemDropItem
end

function PowerUpTowerWheel:playItemAni(nodeItem,index,posY,spaceTime)
    util_playMoveToAction(nodeItem,spaceTime,cc.p(0,posY),function()
        if index < self.m_maxLevel then
            self:addLevel()
        else --end
            performWithDelay(self,function()
                -- performWithDelay(self,function()
                    -- self:runCsbAction("scale",false,function()


                    -- end)
                -- end,1)
                self:runCsbAction("level4",false)
                util_playScaleToAction(self.m_nodeLevel,1,1.1)
                self:moveRoot(true)
            end,2.8)
        end
    end)
end
function PowerUpTowerWheel:createLevelAni(posY,aniIndex,delay)
    performWithDelay(self,function()
        local lvNode = util_createAnimation("PowerUp_bonus_levels.csb")
        self.m_nodeLevel:addChild(lvNode,100)
        lvNode:setPosition(0,posY)
        lvNode:playAction("level"..aniIndex,false,function()
            lvNode:removeFromParent()
        end)
    end,delay)
end
--[[
    @desc:
    author:{author}
    time:2019-07-12 15:39:47
    --@isInit:
    @return: 每个阶段完成后 塔轮移动到下一个位置
]]
function PowerUpTowerWheel:moveRoot(isInit)
    if isInit == false then
        self.scoreAnima:playAction("hide",false)

        -- self.scoreAnima:setVisible(false)
    end
        gLobalSoundManager:playSound("PowerUpSounds/music_PowerUp_towerAddLevel.mp3",false)
        util_playMoveToAction(self.m_nodeLevel,1,cc.p(0,(self.m_curPlayLevel-1)*self.levelHeight*(-1)),function()
            performWithDelay(self,function()
                for i=1,#self.m_wheelList do
                    if self.m_curPlayLevel == i then
                        self.m_wheelList[i]:changeState(true)
                    else
                        self.m_wheelList[i]:changeState(false)
                    end
                end
                gLobalSoundManager:playSound("PowerUpSounds/powerup_towerSelectLVItem.mp3",false)
                self.scoreAnima:setPosition(0,(self.m_curPlayLevel-1/2)*self.levelHeight)
                self.scoreAnima:setVisible(true)
                self.scoreAnima:playAction("show",false,function()
                    self.scoreAnima:playAction("idle",true)
                end)

                if self.m_curPlayLevel <= self.m_maxLevel then
                    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_POWERUP_SHOW_TAP_SPIN,{isinit=isInit})
                end
                if self.m_reelScheduleID == nil then
                    self:startReelSchedule()
                end

            end,0.5)


        end)
end

--[[
    @desc:
    author:{author}
    time:2019-07-12 15:39:27
    --@resultIndex:  开始滚动
    @return:
]]
function PowerUpTowerWheel:beginTowerReel(resultIndex)
    self.m_wheelList[self.m_curPlayLevel]:beginReel(resultIndex,function()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_POWERUP_ROLL_OVER)

        self.scoreAnima:playAction("actionframe",true)

        performWithDelay(self,function()
            if self.m_curPlayLevel < self.m_maxLevel then
                self.m_curPlayLevel = self.m_curPlayLevel+1
                self:moveRoot(false)
            elseif self.m_curPlayLevel == self.m_maxLevel then--respin
                self.m_machine:showFeatureResult(self.m_machine.RESULT_TOWER,true,function()

                end)
                -- if tonumber(self.m_selfMakeData.select) < 0 then--负数向上
                --     self.m_machine:showFeatureResult(self.m_machine.RESULT_TOWER,false,function()
                --         self.m_machine:changeGameState(self.m_machine.STATE_WHEEL_GAME,{nextViewState = 1,isDirect = true,isRespin = true})
                --     end)
                -- else--tower 结束
                --     self.m_machine:showFeatureResult(self.m_machine.RESULT_TOWER,true,function()

                --     end)
                -- end
            end
            -- if tonumber(self.m_selfMakeData.select) < 0 then--负数向上
            --     if self.m_curPlayLevel < self.m_maxLevel then
            --         self.m_curPlayLevel = self.m_curPlayLevel+1

            --         self:moveRoot(false)
            --     elseif self.m_curPlayLevel == self.m_maxLevel then--respin
            --         self.m_machine:showFeatureResult(self.m_machine.RESULT_TOWER,false,function()
            --             self.m_machine:changeGameState(self.m_machine.STATE_WHEEL_GAME,{nextViewState = 1,isDirect = true,isRespin = true})
            --         end)
            --     end
            -- else--tower 结束
            --     self.m_machine:showFeatureResult(self.m_machine.RESULT_TOWER,true,function()

            --     end)
            -- end
        end,4)
    end)
end

function PowerUpTowerWheel:resetView()
    self.m_levelItemIndex = nil
    self.m_maxLevel = nil
    self.levelHeight = nil
    self.m_curPlayLevel = nil
    if self.m_wheelList then
        for i=1,#self.m_wheelList do
            self.m_wheelList[i]:removeFromParent()
        end
    end
    self.m_wheelList = {}
    self.m_isInit = nil
    self.m_nodeLevel:setPosition(0,0)
    self.m_top:setPosition(0,5000)
    self.scoreAnima:setVisible(false)
    self.m_nodeLevel:setScale(0.9)
    self.scoreAnima:playAction("hide",false)

    -- self:runCsbAction("level4",false)
    self:clearReelSchedule()
end

function PowerUpTowerWheel:startReelSchedule()
    if self.m_reelScheduleID == nil then
        self.m_reelScheduleID =
            scheduler.scheduleUpdateGlobal(
            function(delayTime)
                if self.reelSchedulerHanlder then
                    self:reelSchedulerHanlder(delayTime)
                end
            end
        )
    end
end

function PowerUpTowerWheel:reelSchedulerHanlder(dt)
    for i=1,#self.m_wheelList do
        if self.m_wheelList[i] then
            self.m_wheelList[i]:updateReel(dt)
        end
    end
end

function PowerUpTowerWheel:clearReelSchedule()
    if self.m_reelScheduleID ~= nil then
        scheduler.unscheduleGlobal(self.m_reelScheduleID)
        self.m_reelScheduleID = nil
    end
end

function PowerUpTowerWheel:onExit()
    self:clearReelSchedule()
end

--默认按钮监听回调
function PowerUpTowerWheel:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

end


return PowerUpTowerWheel