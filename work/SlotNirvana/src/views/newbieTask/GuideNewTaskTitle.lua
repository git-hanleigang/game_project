--新手任务详细信息
local GuideNewTaskTitle = class("GuideNewTaskTitle", util_require("base.BaseView"))
function GuideNewTaskTitle:initUI()
    self:createCsbNode("GuideNewUser/NewTaskTitle.csb")
    self.m_status = 0

    self.m_nodeTask         = self:findChild("node_task")    -- 任务节点
    self.m_nodeTaskHalf     = self:findChild("node_half") -- 任务过半节点
    self.m_spCoin           = self:findChild("sp_coins")
    local Panel_2           =  self:findChild("Panel_2")
    Panel_2:setSwallowTouches(false)
end

function GuideNewTaskTitle:updateTitle(msg,rewards)
    local m_lb_title = self:findChild("m_lb_title")
    if m_lb_title then
        m_lb_title:setString(msg)
        util_scaleCoinLabGameLayerFromBgWidth(m_lb_title, 200, 1)
    end

    local m_b_coins = self:findChild("lb_shuzi")
    if m_b_coins then
        if rewards then
            m_b_coins:setString(util_formatMoneyStr(rewards))
        end
    end

    self.m_nodeTask:setVisible(true)
    self.m_nodeTaskHalf:setVisible(false)
end

function GuideNewTaskTitle:autoPop(isAuto)
    if self.m_status == 0 then
        self:show(isAuto)
    elseif self.m_status == 2 then
        self:hide()
    end
end
function GuideNewTaskTitle:show(isAuto)
    if self.m_status~=0 then
        return
    end
    self.m_playShowing = true
    self.m_status = 1
    gLobalSoundManager:playSound("Sounds/guide_move_pop.mp3")
    self:runCsbAction("show",false,function()
        self.m_status = 2
        if isAuto then
            if not self.m_autoHideAction then
                self.m_autoHideAction =  performWithDelay(self,handler(self,self.hide),3)
            end
        end
        -- csc 新手期 5.0 添加tips 优化
        self.m_playShowing = false
        if self.m_waitShowingPlayFunc then
            self.m_waitShowingPlayFunc()
            self.m_waitShowingPlayFunc = nil
        end
    end,60)
end
function GuideNewTaskTitle:hide()
    if self.m_autoHideAction then
        self:stopAction(self.m_autoHideAction)
        self.m_autoHideAction = nil
    end
    if self.m_status ~=2 then
        return
    end
    self.m_playHiding = true
    self.m_status = 1
    gLobalSoundManager:playSound("Sounds/guide_move_pop.mp3")
    self:runCsbAction("hide",false,function()
        self.m_status = 0
        -- 还原状态
        self.m_nodeTask:setVisible(true)
        self.m_nodeTaskHalf:setVisible(false)
        self.m_playHiding = false
        if self.m_waitHidingPlayFunc then
            self.m_waitHidingPlayFunc()
            self.m_waitHidingPlayFunc = nil
        end
    end)
end

--任务过半需要展示
function GuideNewTaskTitle:showTaskHalfAction()
    self.m_nodeTask:setVisible(false)
    self.m_nodeTaskHalf:setVisible(true)
    self:show(true)
end

-- 任务完成展示飞金币
function GuideNewTaskTitle:showTaskCompletedFlyCoins(_rewardCoins)
    local flyCoins = function (  )
        local wordPos = self.m_spCoin:getParent():convertToWorldSpace(cc.p(self.m_spCoin:getPosition()))
        local endPos = globalData.flyCoinsEndPos 
        local baseCoins = globalData.topUICoinCount 
        local rewardCoins = _rewardCoins
        gLobalViewManager:pubPlayFlyCoin(wordPos,endPos,baseCoins,rewardCoins,function()
        end,false,nil,nil,nil,nil,true)
    end
    -- 先播放动画
    if self.m_status == 1 then
        -- 当前正在播放滑动动画过程中,需要再检测当前处于什么状态
        if self.m_playShowing then
            -- 当前处于正在展开的状态，需要等待展开完毕后调用飞金币
            self.m_waitShowingPlayFunc = function ()
                flyCoins()
            end
        elseif self.m_playHiding then
            --当前处于正在隐藏的状态，需要等待隐藏完毕后再次调用show动画展开
            self.m_waitHidingPlayFunc = function()
                self:show(true)
                self.m_waitShowingPlayFunc = function ()
                    flyCoins()
                end
            end
        end
    else
        -- 如果当前没有在播放动画过程中，或者动画刚好已经播放完毕
        if self.m_status == 2 then
            -- 当前已经展开了还没收回 ， 可以直接播放飞金币
            flyCoins()
        elseif self.m_status == 0 then
            -- 当前处于收回的状态，播放展示并且设置回调
            self:show(true)
            self.m_waitShowingPlayFunc = function ()
                flyCoins()
            end
        end
    end
end
return GuideNewTaskTitle