--金币滚动节点
local QuestNewChapterChossCellNode = class("QuestNewChapterChossCellNode", util_require("base.BaseView"))

QuestNewChapterChossCellNode.NoneRank = 360

local res_suffix = {"minor.csd","major.csd","grand.csd"}

function QuestNewChapterChossCellNode:getCsbName()
    return QUESTNEW_RES_PATH.QuestNewChapterChossCellNode 
end

function QuestNewChapterChossCellNode:initCsbNodes()
    self.m_btn_contiue = self:findChild("btn_contiue") 
    self.m_btn_play = self:findChild("btn_play") 
    self.m_lb_jindu = self:findChild("lb_jindu") 
    self.m_bar_star = self:findChild("bar_star") 
    self.m_node_photo = self:findChild("node_photo") 
    self.m_node_play = self:findChild("node_play")
    self.m_Panel_play = self:findChild("Panel_play")
    self.m_Panel_play:setSwallowTouches(false)
    self:addClick(self.m_Panel_play)

    self.m_node_reset = self:findChild("node_reset") 
    self.m_sp_diban_light = self:findChild("diban_1")
    
end

function QuestNewChapterChossCellNode:updateCell(index,cell_data)
    self.m_index = index
    self.m_cell_data = cell_data
    
    local photoIndex = index
    if self.m_cell_data:isResetChapter() then
        photoIndex = 1
    end
    local chapterPhoto = util_createSprite(QUESTNEW_RES_PATH.QuestNewChapterPhotoPath .. photoIndex ..".png")
    if not tolua.isnull(chapterPhoto) then
        chapterPhoto:addTo(self.m_node_photo)
    end
    if self.m_cell_data:isResetChapter()  then
        self:runCsbAction("play", true)
        self.m_node_play:setVisible(false)
        self.m_node_reset:setVisible(true)
        return
    end
    
    if not self.m_cell_data:isUnlock() or self.m_cell_data:isWillDoUnlock() then
        self:runCsbAction("locked", false)
    else
        if self.m_cell_data:isCompleted() and not self.m_cell_data:isWillDoCompleted() then
            self.m_node_play:setVisible(false)
            util_csbPauseForIndex(self.m_csbAct,200)
        else
            self.m_sp_diban_light:setVisible(cell_data:isCurrentChapter())
            self:runCsbAction("play", true)
        end
    end
    self.m_lb_jindu:setString("".. cell_data.p_pickStars .. "/" ..cell_data.p_maxStars)
    local rate = cell_data.p_pickStars / cell_data.p_maxStars*100
    self.m_bar_star:setPercent(rate)
    if cell_data.p_pickStars == 0 or cell_data:isCurrentChapter() then
        self.m_btn_play:setVisible(true)
        self.m_btn_contiue:setVisible(false)
    else
        self.m_btn_play:setVisible(false)
        self.m_btn_contiue:setVisible(true)
    end
    self.m_node_reset:setVisible(false)

end

function QuestNewChapterChossCellNode:clickFunc(sender)
    local name = sender:getName()
    if G_GetMgr(ACTIVITY_REF.QuestNew):isQuestNextRound() then
        return 
    end
    if self.m_doingAct then
        return 
    end
    if name == "btn_play" or name == "btn_contiue" or name == "Panel_play" then
        if self.m_cell_data:isCompleted() then
            return
        end
        if not self.m_cell_data:isUnlock() or self.m_cell_data:isWillDoUnlock() then
            self:runCsbAction("suo", false)
            return
        end
        gLobalSoundManager:playSound(QUESTNEW_RES_PATH.QuestNew_Sound_MapClick)
        G_GetMgr(ACTIVITY_REF.QuestNew):showQuestMainMapView(self.m_index)
    elseif name == "btn_reset" then
        G_GetMgr(ACTIVITY_REF.QuestNew):showTipView({type = 2})
    end
end

function QuestNewChapterChossCellNode:doUnlockAct(callBack)
    if self.m_cell_data:isWillDoUnlock() then
        self.m_doingAct = true
        self.m_cell_data:clearWillDoUnlock()
        gLobalSoundManager:playSound(QUESTNEW_RES_PATH.QuestNew_Sound_ChapterUnlock)
        self:runCsbAction("jiesuo", false,function ()
            self.m_sp_diban_light:setVisible(self.m_cell_data:isCurrentChapter())
            self.m_doingAct = false
            if callBack then
                callBack()
            end
        end)
    end
end

function QuestNewChapterChossCellNode:doCompleteAct(callBack)
    if self.m_cell_data:isWillDoCompleted() then
        self.m_doingAct = true
        self.m_cell_data:clearWillDoCompleted()
        self:runCsbAction("completed", false,function ()
            self.m_doingAct = false
            self.m_node_play:setVisible(false)
            if callBack then
                callBack()
            end
        end)
        return true
    end
    return false
end

function QuestNewChapterChossCellNode:getContentSize()
    return cc.size(480,600)
end

function QuestNewChapterChossCellNode:showResetBtn()
    self.m_node_reset:setVisible(true)
end

return QuestNewChapterChossCellNode
