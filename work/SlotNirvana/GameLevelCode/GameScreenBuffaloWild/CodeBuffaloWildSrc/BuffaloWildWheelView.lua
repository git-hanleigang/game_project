---
--xcyy
--2018年5月23日
--BuffaloWildWheelView.lua

local BuffaloWildWheelView = class("BuffaloWildWheelView",util_require("base.BaseView"))

BuffaloWildWheelView.m_wheel = nil
function BuffaloWildWheelView:initUI(data,callback)

    self:createCsbNode("BuffaloWild/BuffaloWild_wheel1.csb")
    self.m_data = data

    for i=1,#data.taskWheels do
        local temp = data.taskWheels[i]
        local node = self:findChild("wheelNode_"..i)
        local item = util_createView("CodeBuffaloWildSrc.BuffaloWildWheelItem",i,temp)
        node:addChild(item)
    end

    local lbs_bet = self:findChild("BitmapFontLabel_1")
    local bets = util_formatCoins(data.task.taskBetCoins, 9)
    lbs_bet:setString(bets)
    self:updateLabelSize({label=lbs_bet,sx=1,sy=1},660)

    self.m_wheel = require("CodeBuffaloWildSrc.BuffaloWildWheelAction"):create(self:findChild("wheel"),6,function()
        -- 滚动结束调用
        -- self:bigWheelOver()
        -- gLobalSoundManager:setBackgroundMusicVolume(0.2)
        gLobalSoundManager:playSound("BuffaloWildSounds/buffaloWild_collect_wheelResult.mp3",false)
        self:runCsbAction("zhongjaing",true,nil,20)
        performWithDelay(self,function()
            if callback then
                callback()
            end
        end,2)
     end,function(distance,targetStep,isBack)
         -- 滚动实时调用
     end)
     self:addChild(self.m_wheel)
     self:setWheelRotModel()

     gLobalSoundManager:playSound("BuffaloWildSounds/buffaloWild_collect_wheelAppear.mp3",false)
    -- performWithDelay(self,function()
    -- end,1)
     self:runCsbAction("show",false,function()
        self.m_isInit = true
        self:runCsbAction("idle",true)
    end,20)
end


function BuffaloWildWheelView:beginBigWheelAction( endindex )
    local wheelData = {}
    -- wheelData.m_startA = 180 --加速度
    -- wheelData.m_runV = 720--匀
    -- wheelData.m_runTime = 2--匀速时间
    -- wheelData.m_slowA = 45 --动态减速度
-- wheelData.m_slowQ = 5 --减速圈数
    -- wheelData.m_stopV = 45 --停止时速度
    -- wheelData.m_backTime = 0 --回弹前停顿时间
    -- wheelData.m_stopNum = 0 --停止圈数
    -- wheelData.m_randomDistance = 0

    -- wheelData.m_startA = 30 --加速度
    -- wheelData.m_runV = 360--匀速
    -- wheelData.m_runTime = 2 --匀速时间
    -- wheelData.m_slowA = 80 --动态减速度
    -- wheelData.m_slowQ = 1 --减速圈数
    -- wheelData.m_stopV = 30 --停止时速度
    -- wheelData.m_backTime = 0 --回弹前停顿时间
    -- wheelData.m_stopNum = 0 --停止圈数
    -- wheelData.m_randomDistance = 0
    wheelData.m_startA = 300 --加速度
    wheelData.m_runV = 500--匀速
    wheelData.m_runTime = 2 --匀速时间
    wheelData.m_slowA = 150 --动态减速度
    wheelData.m_slowQ = 1 --减速圈数
    wheelData.m_stopV = 110 --停止时速度
    wheelData.m_backTime = 0 --回弹前停顿时间
    wheelData.m_stopNum = 0 --停止圈数
    wheelData.m_randomDistance = 0
    self.m_wheel:changeWheelRunData(wheelData)
    self.m_wheel:recvData(endindex)
    self.m_wheel:beginWheel()
    -- gLobalSoundManager:setBackgroundMusicVolume(0.2)
    gLobalSoundManager:playSound("BuffaloWildSounds/buffaloWild_collect_wheelTurn2.mp3",false)
    self:runCsbAction("actionframe")
end

function BuffaloWildWheelView:setWheelRotModel( )

    self.m_wheel:setWheelRotFunc( function(distance,targetStep,isBack)
        -- self:setRotionOne(distance,targetStep,isBack)
    end)
end

function BuffaloWildWheelView:onEnter()
    self.m_isInit = false
    self.m_bgSoundId = gLobalSoundManager:playBgMusic("BuffaloWildSounds/buffaloWild_collect_wheelBg.mp3")

end

function BuffaloWildWheelView:showLock()

end
function BuffaloWildWheelView:showOver(callback)
    self:runCsbAction("over",false,function()
        self:removeFromParent()
        if callback then
            callback()
        end
    end,20)
end

function BuffaloWildWheelView:showUnLock()

end

function BuffaloWildWheelView:onExit()

end

--默认按钮监听回调
function BuffaloWildWheelView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()
    if not self.m_isInit then
        return
    end
    if self.m_click then
        return
    else
        self.m_click = true
    end
    self:findChild("Button_1"):setVisible(false)
    self:beginBigWheelAction(self.m_data.taskWheelIndex+1)
    gLobalSoundManager:stopBgMusic()

end


return BuffaloWildWheelView