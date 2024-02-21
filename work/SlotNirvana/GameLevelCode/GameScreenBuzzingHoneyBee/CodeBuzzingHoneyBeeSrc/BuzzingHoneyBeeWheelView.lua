--fixios0223
local BuzzingHoneyBeeWheelView = class("BuzzingHoneyBeeWheelView",util_require("base.BaseView"))
local WheelType = {
    NumType = 1,
    PicType = 2
}
BuzzingHoneyBeeWheelView.NUMWHEELDATA = {
    4,2,6,3,8,4,2,10,3,8,4,7,5,3,10,6
}
BuzzingHoneyBeeWheelView.SUPERNUMWHEELDATA = {
    5,3,6,4,8,5,2,6,5,4,8,7,6,5,10,6
}
function BuzzingHoneyBeeWheelView:initUI(machine)
    self:createCsbNode("BuzzingHoneyBee_wheel.csb")
    -- 添加向日葵花边
    local bg_flowerFrame = util_spineCreate("Socre_BuzzingHoneyBee_BGhuaban",true,true)
    self:findChild("huaban"):addChild(bg_flowerFrame)
    util_spinePlay(bg_flowerFrame,"actionframe",true)

    self.m_machine = machine
    self.distance_now = 0
    self.distance_pre = 0
    self.m_wheel = require("CodeBuzzingHoneyBeeSrc.BuzzingHoneyBeeWheelAction"):create(self:findChild("wheelNode"),16,function()
        self.distance_now = 0
        self.distance_pre = 0
        -- 滚动结束调用
        self:wheelOver()
    end,function(distance,targetStep,isBack)
        -- 滚动实时调用
        self:setRotionWheel(distance,targetStep)
    end)
    self:addChild(self.m_wheel)
    --添加标题
    self.m_titleNode = util_createAnimation("BuzzingHoneyBee_wheel_fg.csb")
    self:findChild("wheel_fg"):addChild(self.m_titleNode)
    --添加数字
    self.m_wheelNumLabelTab = {}
    for i,num in ipairs(self.NUMWHEELDATA) do
        local wheelNumLabel = util_createAnimation("BuzzingHoneyBee_wheel_zi.csb")
        self:findChild("wheel_zi_"..i):addChild(wheelNumLabel)
        table.insert(self.m_wheelNumLabelTab,wheelNumLabel)
    end
end
function BuzzingHoneyBeeWheelView:setRotionWheel(distance,targetStep)
    self.distance_now = distance / targetStep

    if self.distance_now < self.distance_pre then
        self.distance_pre = self.distance_now
    end
    local floor = math.floor(self.distance_now - self.distance_pre)
    if floor > 0 then
        self.distance_pre = self.distance_now
        gLobalSoundManager:playSound("BuzzingHoneyBeeSounds/music_BuzzingHoneyBee_wheelRoll.mp3")
    end
end
function BuzzingHoneyBeeWheelView:reset()
    for i,numLabelNode in ipairs(self.m_wheelNumLabelTab) do
        numLabelNode:playAction("idleframe")
    end
    self:findChild("wheelNode"):setRotation(0)
    self.m_wheel:initWheelRunData()
    self.m_wheelShowView = nil
end

--设置标题  1为普通freespin，2为superfreespin
function BuzzingHoneyBeeWheelView:setTitle(titleType)
    if titleType == 1 then
        self.m_titleNode:findChild("texi"):setVisible(true)
        self.m_titleNode:findChild("texi_0"):setVisible(false)
        for i,wheelNumLabel in ipairs(self.m_wheelNumLabelTab) do
            wheelNumLabel:findChild("m_lb_num"):setString(self.NUMWHEELDATA[i])
        end
    else
        self.m_titleNode:findChild("texi"):setVisible(false)
        self.m_titleNode:findChild("texi_0"):setVisible(true)
        for i,wheelNumLabel in ipairs(self.m_wheelNumLabelTab) do
            wheelNumLabel:findChild("m_lb_num"):setString(self.SUPERNUMWHEELDATA[i])
        end
    end
end
--设置轮盘显示的类型   1为数字盘，2为图案盘
function BuzzingHoneyBeeWheelView:setWheelType(wheelType,isPlayAction)
    if self.m_wheelShowView == wheelType then
        return
    end
    self.m_wheelShowView = wheelType
    if self.m_wheelShowView == WheelType.NumType then
        if isPlayAction then
            self:runCsbAction("actionframe2")
            gLobalNoticManager:postNotification("CodeGameScreenBuzzingHoneyBeeMachine_playWheelRewardFrameAction",{"actionframe2",false})
        else
            self:runCsbAction("idleframe")
            gLobalNoticManager:postNotification("CodeGameScreenBuzzingHoneyBeeMachine_playWheelRewardFrameAction",{"idleframe",false})
        end
    else
        if isPlayAction then
            self:runCsbAction("actionframe1")
            gLobalNoticManager:postNotification("CodeGameScreenBuzzingHoneyBeeMachine_playWheelRewardFrameAction",{"actionframe1",false})
        else
            self:runCsbAction("idleframe2")
            gLobalNoticManager:postNotification("CodeGameScreenBuzzingHoneyBeeMachine_playWheelRewardFrameAction",{"idleframe2",false})
        end
    end
end
function BuzzingHoneyBeeWheelView:onEnter()
    BuzzingHoneyBeeWheelView.super.onEnter(self)
    gLobalNoticManager:addObserver(self,function(params)
        self:changeFreeSpinByCount(params)
    end,ViewEventType.SHOW_FREE_SPIN_NUM)

    gLobalNoticManager:addObserver(self,function(params)
        self:reelStopSetWheel()
    end,"BuzzingHoneyBeeWheelView_reelStopSetWheel")

    gLobalNoticManager:addObserver(self,function(params)
        self:quicklyStop()
    end,"BuzzingHoneyBeeWheelView_quicklyStop")
end
---
-- 更新freespin 剩余次数
--
function BuzzingHoneyBeeWheelView:changeFreeSpinByCount()
    local leftFsCount = globalData.slotRunData.freeSpinCount
    local totalFsCount = globalData.slotRunData.totalFreeSpinCount
    self:updateFreespinCount(leftFsCount,totalFsCount)
end

-- 更新并显示FreeSpin剩余次数
function BuzzingHoneyBeeWheelView:updateFreespinCount( leftimes,totaltimes )
    self.m_titleNode:findChild("m_lb_num_1"):setString(totaltimes - leftimes)
    self.m_titleNode:findChild("m_lb_num_2"):setString(totaltimes)

    self.m_titleNode:findChild("m_lb_num_3"):setString(totaltimes - leftimes)
    self.m_titleNode:findChild("m_lb_num_4"):setString(totaltimes)
end
function BuzzingHoneyBeeWheelView:onExit()
    BuzzingHoneyBeeWheelView.super.onExit(self)
    gLobalNoticManager:removeAllObservers(self)
end
--开始转动
function BuzzingHoneyBeeWheelView:wheelStart()
    if self.m_wheelShowView == WheelType.NumType then
        for i,numLabelNode in ipairs(self.m_wheelNumLabelTab) do
            numLabelNode:playAction("idleframe")
        end
        self:reelStopSetWheel()
        self.m_wheel.m_isWheelData = false
        self.m_wheel:beginWheel()
    else
        self:reelStopSetWheel()
        self.m_wheel.m_isWheelData = false
        self.m_wheel:beginWheel()
    end
end
--设置转动结果
function BuzzingHoneyBeeWheelView:setWheelResult(endidx)
    self.m_wheel:recvData(endidx + 1)
end
--转动结束
function BuzzingHoneyBeeWheelView:wheelOver()
    self.m_soundWheelOverId = gLobalSoundManager:playSound("BuzzingHoneyBeeSounds/music_BuzzingHoneyBee_wheelOver.mp3")
    if self.m_wheelShowView == WheelType.NumType then
        self:runCsbAction("win"..self.m_wheelShowView,true)
        gLobalNoticManager:postNotification("CodeGameScreenBuzzingHoneyBeeMachine_playWheelRewardFrameAction",{"win"..self.m_wheelShowView,true})
        gLobalNoticManager:postNotification("CodeGameScreenBuzzingHoneyBeeMachine_wheelNumOver")
    
        -- for i,numLabelNode in ipairs(self.m_wheelNumLabelTab) do
        --     if i == self.m_wheel.overIndex then
        --         numLabelNode:playAction("idleframe")
        --     else
        --         numLabelNode:playAction("idleframe2")
        --     end
        -- end
        
    else
        self:runCsbAction("win"..self.m_wheelShowView,true)
        gLobalNoticManager:postNotification("CodeGameScreenBuzzingHoneyBeeMachine_playWheelRewardFrameAction",{"win"..self.m_wheelShowView,true})
        performWithDelay(self,function ()
            gLobalNoticManager:postNotification("CodeGameScreenBuzzingHoneyBeeMachine_wheelPicOver")
        end,1.0)
    end
end
--轮盘块停的时候 转盘也快停调用
function BuzzingHoneyBeeWheelView:quicklyStop()
    self.m_wheel:quicklyStop()
end
--轮盘停止后 转盘的一些处理
function BuzzingHoneyBeeWheelView:reelStopSetWheel()
    if self.m_wheelShowView == WheelType.NumType then
        self:runCsbAction("idleframe")
        gLobalNoticManager:postNotification("CodeGameScreenBuzzingHoneyBeeMachine_playWheelRewardFrameAction",{"idleframe",false})
    else
        self:runCsbAction("idleframe2")
        gLobalNoticManager:postNotification("CodeGameScreenBuzzingHoneyBeeMachine_playWheelRewardFrameAction",{"idleframe2",false})
    end
    
    if self.m_soundWheelOverId then
        gLobalSoundManager:stopAudio(self.m_soundWheelOverId)
        self.m_soundWheelOverId = nil
    end
end
return BuzzingHoneyBeeWheelView