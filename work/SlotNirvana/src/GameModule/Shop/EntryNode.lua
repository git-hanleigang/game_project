-- Created by jfwang on 2019-05-21.
-- boostme关卡内 右下角入口
--
local EntryNode = class("EntryNode", util_require("base.BaseView"))

function EntryNode:initUI(data)
    self:createCsbNode("BoostMe/Node_4.csb")
    self:runCsbAction("idle",false)
    self:setScale(0.8)

    --防止按钮重复点击
    self.m_entryLayerState = 0
    self.m_btnclickAniEnd = true
    self.m_djsState = true

    self.m_closeTimeCount = 3 -- 子类可以修改关闭时间

    self.m_entryNode = self:findChild("entryNode")
    
    self.m_lockNode = self:findChild("lock")
    self.m_lockNode:setVisible(true)
    self.m_djsNode = self:findChild("daojish")
    self.m_djsNode:setVisible(false)

    self.m_djsLabelValue = self:findChild("BitmapFontLabel_1")
    self.m_entryInfoView = util_createView("GameModule.Shop.EntryInfoView")
    self.m_entryNode:addChild(self.m_entryInfoView)
    self.m_buffNode = self:findChild("node_buff_num")
    if self.m_buffNode then
        self.m_buffNode:setVisible(false)
    end
    
    --初始化界面数据
    self:initView()

    -- 轮盘恢复是否刷新界面
    self.m_isUpdateByResumeSlots = false

    --注册通知 spin之后通知
    gLobalNoticManager:addObserver(self,function(self,params)
        if globalData.slotRunData.gameRunPause == true then
            -- globalData.slotRunData.gameResumeFunc = function()
            --     if self.updateView then
            --         self:updateView()
            --     end
            -- end
            self.m_isUpdateByResumeSlots = true
        else
            if self.updateView ~= nil then
                self:updateView()
            end
        end
    end,ViewEventType.NOTIFY_GET_SPINRESULT)

    gLobalNoticManager:addObserver(
        self,
        function(Target, params)
            if self.m_isUpdateByResumeSlots then
                if self.updateView ~= nil then
                    self:updateView()
                end
                self.m_isUpdateByResumeSlots = false
            end
        end,
        ViewEventType.NOTIFY_RESUME_SLOTSMACHINE
    )
end

function EntryNode:initView( )

end

--刷新界面
function EntryNode:updateView()
    
end

--设置倒计时
function EntryNode:setTimerValue(strTime,isOver)
    self.m_djsState = isOver
    
    if self.m_djsState then
        self.m_lockNode:setVisible(true)
        self.m_djsNode:setVisible(false)
    else
        self.m_lockNode:setVisible(false)
        self.m_djsNode:setVisible(true)
        self.m_djsLabelValue:setString(strTime)
    end

end

--设置内容
function EntryNode:setEntryInfoView(tomorrow,current)
    if self.m_entryInfoView ~= nil then
        self.m_entryInfoView:setEntryInfoView(tomorrow,current)
    end
end

function EntryNode:onExit()
    gLobalNoticManager:removeAllObservers(self)
    self:removeDownTimer()

end

--倒计时收起
function EntryNode:showDownTimer()
    if self.m_schduleEntryID ~= nil then
        return
    end

    self.m_lostTime = self.m_closeTimeCount
    self.m_schduleEntryID = scheduler.scheduleGlobal(
        function( )
            if self.m_lostTime == 0 then
                self:removeDownTimer()
                self:closeEntryInfoView()
            else 
                self.m_lostTime = self.m_lostTime - 1
            end
        end
        ,1 
    )
end

function EntryNode:removeDownTimer()
    if self.m_schduleEntryID ~= nil then
        scheduler.unscheduleGlobal(self.m_schduleEntryID)
        self.m_schduleEntryID = nil
    end
end

--打开收起显示框
function EntryNode:showEntryInfoView()
    if self.m_entryLayerState == 0 then
        self.m_entryInfoView:showView(function(  )
            --3s后自动关闭
            self:showDownTimer()

            self.m_btnclickAniEnd = true
            self.m_entryLayerState = 1
        end)
        return
    end

    self:removeDownTimer()
    self.m_entryInfoView:hideView(function(  )
        self.m_btnclickAniEnd = true
        self.m_entryLayerState = 0
    end)
end

--关闭MegaInfoView
function EntryNode:closeEntryInfoView()
    if self.m_entryLayerState == 1 then
        self.m_btnclickAniEnd = false

        self.m_entryInfoView:hideView(function(  )
            self.m_btnclickAniEnd = true
            self.m_entryLayerState = 0
        end)
    end

end

-- self.m_djsState
function EntryNode:showEntryView()
    if self.m_djsState then
        if self.onLockClick then
            self:onLockClick()
        end
    else
        self.m_btnclickAniEnd = false
        self:showEntryInfoView()
    end
end

function EntryNode:clickFunc(sender)
    if not self.m_btnclickAniEnd then
        return
    end

    local name = sender:getName()
    local tag = sender:getTag()
    gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)

    --收起按钮
    if name == "btn_entry" then
        self:showEntryView()
    end
end

--倒计时结束，收起关闭
function EntryNode:closeUI()
    if self.isClose then
        return
    end
    self.isClose=true

    gLobalNoticManager:removeAllObservers(self)
    self:removeDownTimer()

    self:setVisible(false)
end

return EntryNode