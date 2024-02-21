---
--xcyy
--2018年5月23日
--BuffaloWildCollectView.lua

local BuffaloWildCollectView = class("BuffaloWildCollectView",util_require("base.BaseView"))

BuffaloWildCollectView.PROGRESS_WIDTH = 549

function BuffaloWildCollectView:initUI(parent)
    self.m_parent = parent
    self:createCsbNode("BuffaloWild_jindutiao.csb")

    -- self:runCsbAction("actionframe") -- 播放时间线
    -- self:findChild("xxxx") -- 获得子节点
    -- self:addClick("xxx") -- 非按钮节点得手动绑定监听


    -- performWithDelay(节点（必须传入）, function ()
	    -- 延时函数
	    -- xxx 对应延时时间
    -- end, xxx)

    -- schedule(view,function ()
        -- 定时器
    	-- xxx 对应定时器调用时间间隔
    -- end,xxxx)
    self.m_lbs_collectNum =  self:findChild("lbs_collectNum")
    self.m_lbs_spinNum =  self:findChild("lbs_spinNum")
    self.m_loadingBar =  self:findChild("LoadingBar_1")

    self.m_fullEff = self:findChild("Particle_2")
    self.m_fullEff:stopSystem()

    local smallWheel = util_createAnimation("BuffaloWild_jindutiaowheel.csb")
    self:findChild("nodeWheel"):addChild(smallWheel)
    smallWheel:playAction("normal",true)

    self.m_headNode = self:findChild("headNode")
    self:addClick(self:findChild("btn"))
end
function BuffaloWildCollectView:initData(data)
    if  self.m_percentAction then
        self:stopAction(self.m_percentAction)
        self.m_percentAction = nil
    end
    self.m_percent = math.floor( (data.current/data.target)*100 )
    self:progressEffect(self.m_percent)
    self:resetView(data)
end


function BuffaloWildCollectView:updateData(data,callback)

    if self.m_percentAction then
        self:stopAction(self.m_percentAction)
        self.m_percentAction = nil
        if self.m_percent then
            self.m_loadingBar:setPercent(self.m_percent)
        end
    end

    self.m_percent = math.floor( (data.current / data.target) * 100 )

    local oldPercent = self.m_loadingBar:getPercent()
    if oldPercent > self.m_percent then -- 处理异常情况
        self.m_loadingBar:setPercent(0)
    end

    self:runCsbAction("collect",false,function()
    end)
    performWithDelay(self,function()
        self:updatePercent(self.m_percent,callback)
    end,1/3)
    self:resetView(data)
end

function BuffaloWildCollectView:updatePercent(aimPercent,callback)

    local oldPercent = self.m_loadingBar:getPercent()
    self.m_percentAction = schedule(self, function()
        oldPercent = oldPercent + 1
        if oldPercent >= aimPercent then
            if aimPercent >= 100 then
                self.m_fullEff:resetSystem()
                -- gLobalSoundManager:setBackgroundMusicVolume(0.2)
                gLobalSoundManager:playSound("BuffaloWildSounds/buffaloWild_collect_full1.mp3",false)
                self:runCsbAction("jiman",false,function()
                end)
            else
                self:runCsbAction("shouji",false,function()
                end)
            end
            if callback then
                callback()
            end
            self:stopAction(self.m_percentAction)
            self.m_percentAction = nil
            oldPercent = aimPercent
        end
        self:progressEffect(oldPercent)
    end, 0.03)
        -- end, 0.5)
    -- end


    -- self:runCsbAction("actionframe2", false, function()
    --     if percent >= 100 then
    --         -- gLobalSoundManager:playSound("CharmsSounds/sound_Charms_tramcar_enter.mp3")
    --         -- performWithDelay(self, function()
    --         --     self:completed()
    --         -- end, 2)
    --         gLobalSoundManager:playSound("GoldExpressSounds/sound_GoldExpress_collect_completed.mp3")
    --         self:runCsbAction("reel_shouji")
    --     else
    --         self:idle()
    --     end
    -- end)
end
function BuffaloWildCollectView:progressEffect(percent)
    self.m_loadingBar:setPercent(percent)
    self.m_headNode:setPositionX(self.PROGRESS_WIDTH * percent * 0.01)
end

function BuffaloWildCollectView:resetView(data)

    self.m_lbs_spinNum:setString(data.resetSpinTimes - data.spinTimes)
    self.m_lbs_collectNum:setString(data.target - data.current)


    self:findChild("awayImg"):setVisible(false)
    self:findChild("bar"):setVisible(true)
    self:findChild("collectedImg"):setVisible(false)
    self:findChild("collect"):setVisible(true)

    if data.current >= data.target then--显示完成
        self:findChild("collectedImg"):setVisible(true)
        self:findChild("collect"):setVisible(false)
    else
        if data.resetSpinTimes - data.spinTimes <= 0 then--显示失败
            self:findChild("awayImg"):setVisible(true)
            self:findChild("bar"):setVisible(false)
        end
    end

    for i=1,5 do
        if (i-1) == data.signal then
            self:findChild("headImage"..(i-1)):setVisible(true)
        else
            self:findChild("headImage"..(i-1)):setVisible(false)
        end
    end
    if self.m_lock then
        self:findChild("bar"):setVisible(false)
        self:findChild("awayImg"):setVisible(false)
    end
end

function BuffaloWildCollectView:getCollectPos()
    local pos = self:findChild("touxiang"):getParent():convertToWorldSpace(cc.p(self:findChild("touxiang"):getPosition()))
    return pos
end



function BuffaloWildCollectView:onEnter()


end

function BuffaloWildCollectView:showLock()
    self.m_lock = true
    self:runCsbAction("lock") -- 播放时间线

end


function BuffaloWildCollectView:showUnLock()
    if self.m_lock then
        self.m_lock = false
        
        globalMachineController:playBgmAndResume("BuffaloWildSounds/buffaloWild_collect_unlock.mp3",1,0.2,1)

        self:runCsbAction("unlock",false,function()
            if not self.m_lock then
                self:runCsbAction("normal") -- 播放时间线
            end
        end) -- 播放时间线
    end
end

function BuffaloWildCollectView:onExit()

end

--默认按钮监听回调
function BuffaloWildCollectView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()
    if self.m_parent.m_iBetLevel == 0 then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        self.m_parent:unlockHigherBet()
    end
end


return BuffaloWildCollectView