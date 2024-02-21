----
local QuestNewAllTipLayer = class("QuestNewAllTipLayer", BaseLayer)


function QuestNewAllTipLayer:getCsbName()
    return QUESTNEW_RES_PATH.QuestNewAllTipLayer
end

function QuestNewAllTipLayer:initDatas(data)
    self.m_type = data.type 
    self.m_chapterId = data.chapterId 
    self.m_pointId = data.pointId
    self.m_callBack = data.callBack
end
-- 弹窗动画
function QuestNewAllTipLayer:playShowAction()
    local userDefAction = function(callFunc)
        gLobalSoundManager:playSound("Sounds/soundOpenView.mp3")
        self:runCsbAction(
            "start",
            false,
            function()
                if callFunc then
                    callFunc()
                end
            end,
            60
        )
    end
    QuestNewAllTipLayer.super.playShowAction(self, userDefAction)
end

function QuestNewAllTipLayer:onShowedCallFunc()
    self:runCsbAction("idle", true, nil, 60)
end

function QuestNewAllTipLayer:initCsbNodes()
    self.m_node_wheel_tanban = self:findChild("node_wheel_tanban")
    self.m_lb_star = self:findChild("lb_star")
    self.m_bar_jindu = self:findChild("bar_jindu")
    self.m_sp_minor = self:findChild("sp_minor")
    self.m_sp_major = self:findChild("sp_major")
    self.m_sp_grand = self:findChild("sp_grand")

    self.m_node_tanban1 = self:findChild("node_tanban1")
    self.m_node_tanban2 = self:findChild("node_tanban2")
end


function QuestNewAllTipLayer:initView()
    self.m_node_wheel_tanban:setVisible(self.m_type == 1)
    self.m_node_tanban1:setVisible(self.m_type == 2)
    self.m_node_tanban2:setVisible(self.m_type == 3)
    if self.m_type == 1 then
        local wheelData = G_GetMgr(ACTIVITY_REF.QuestNew):getChapterWheelDataByChapterId(self.m_chapterId)
        local needCount ,maxCount,nextLevel = wheelData:getWheelNextLevelUnlockStars()
        local rata =(maxCount-needCount)/maxCount *100
        self.m_bar_jindu:setPercent(rata)
        self.m_lb_star:setString(""..needCount)
        self.m_sp_minor:setVisible(nextLevel == 1)
        self.m_sp_major:setVisible(nextLevel == 2)
        self.m_sp_grand:setVisible(nextLevel == 3)
    else
        
    end
end


function QuestNewAllTipLayer:clickFunc(_sender)
    local name = _sender:getName()

    if name == "btn_close" or name == "btn_later_1" or name == "btn_later_2" or name == "btn_later_3" then
        if self.m_bTouch then
            return
        end
        self.m_bTouch = true
        self:closeUI()
    elseif name == "btn_start_1" then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        local callback = self.m_callBack
        self:closeUI(function ()
            if callback then
                callback()
            end
        end)
    elseif  name == "btn_start_2" then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        self:closeUI(
            function ()
                util_nextFrameFunc(function ()
                    G_GetMgr(ACTIVITY_REF.QuestNew):showTipView({type = 3})
                end)
            end
        )
    elseif name == "btn_start_3"   then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        self:closeUI(
            G_GetMgr(ACTIVITY_REF.QuestNew):doQuestNextRound()
        )
    end
end

function QuestNewAllTipLayer:goToChapterView()
    if self.isOnKeepGoing then
        return
    end
    self.isOnKeepGoing = true
    local questConfig = G_GetMgr(ACTIVITY_REF.QuestNew):getRunningData()
    if questConfig ~= nil then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_RESUME_MACHINE_POPUPVIEW)
        gLobalViewManager:gotoSceneByType(SceneType.Scene_Lobby,function()
            local enterChapter,enterPoint = G_GetMgr(ACTIVITY_REF.QuestNew):getEnterGameChapterIdAndPointId()
            G_GetMgr(ACTIVITY_REF.QuestNew):showQuestMainMapView(enterChapter)
        end)
        -- if questConfig:getStageIdx() == 6 then
        --     --宝箱返回大厅通过重连打开防止提前变化地图
        --     gLobalViewManager:gotoSceneByType(SceneType.Scene_Lobby,function()
        --         G_GetMgr(ACTIVITY_REF.QuestNew):showMainLayer()
        --     end)
        --     return
        -- else
            
        -- end
    end
end

return QuestNewAllTipLayer
