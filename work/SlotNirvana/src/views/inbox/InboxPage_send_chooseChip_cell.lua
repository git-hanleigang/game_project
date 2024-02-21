--[[--

]]
local BaseView = util_require("base.BaseView")
local InboxPage_send_chooseChip_cell = class("InboxPage_send_chooseChip_cell", BaseView)

function InboxPage_send_chooseChip_cell:initUI(mainClass)
    self.m_mainClass = mainClass
    self:createCsbNode("InBox/FBCard/InboxPage_Send_SelCardPop_cell.csb")

    self.m_isChoosed = false

    self.m_chipNode = self:findChild("Node_chip")
    self.m_numNode = self:findChild("Node_num")
    self.m_numMask = self:findChild("num_mask")

    local touch = self:findChild("touch")
    self:addClick(touch)
    self:addNodeClicked(touch)
    touch:setSwallowTouches(false)
end

function InboxPage_send_chooseChip_cell:updateUI(cardData)
    self.m_cardData = cardData
    self.m_clanId = cardData.clanId
    self.m_cardId = cardData.cardId
    self:updateChip()
    -- self:updateTagNum()
    self:updateState()
end

function InboxPage_send_chooseChip_cell:updateChip()
    if not self.m_cardSprite then
        self.m_cardSprite = util_createView("GameModule.Card.season201903.MiniChipUnit")
        self.m_cardSprite:playIdle()
        self.m_chipNode:addChild(self.m_cardSprite)
    end
    self.m_cardSprite:reloadUI(self.m_cardData)
end

-- function InboxPage_send_chooseChip_cell:updateTagNum()
--     local isShow, num = self:isShowTag()
--     if isShow then
--         self.m_numNode:setVisible(true)
--         if not self.m_tagNumUI then
--             self.m_tagNumUI = util_createView("GameModule.Card.season201903.CardTagNum")
--             self.m_numNode:addChild(self.m_tagNumUI)
--         end
--         self.m_tagNumUI:updateNum(num)
--     else
--         self.m_numNode:setVisible(false)
--     end
-- end

function InboxPage_send_chooseChip_cell:getCount()
    local num = self.m_cardData.count
    if self.m_isChoosed then
        num = num - 1
    end
    return num
end

function InboxPage_send_chooseChip_cell:isShowTag()
    local num = self:getCount()
    if num and num >= 1 then
        return true, num
    end
    return false
end

--------------------------------------------------------------------------------
function InboxPage_send_chooseChip_cell:updateState()
    if self.m_isChoosed then
        self.m_cardSprite:updateStarOpacity("#646464", 255)
        self.m_cardSprite:updateBgOpacity("#646464", 255)
        self.m_cardSprite:updateIconOpacity("#646464", 255)
        -- local isShow = self:isShowTag()
        -- if isShow then
        --     self.m_numMask:setVisible(true)        
        -- end
    else
        self.m_cardSprite:updateStarOpacity("#FFFFFF", 255)
        self.m_cardSprite:updateBgOpacity("#FFFFFF", 255)
        self.m_cardSprite:updateIconOpacity("#FFFFFF", 255)
        self.m_numMask:setVisible(false)
    end
end

function InboxPage_send_chooseChip_cell:getState()
    return self.m_isChoosed
end

function InboxPage_send_chooseChip_cell:changeState(state)
    self.m_isChoosed = state
    self.m_mainClass:setChoosed(self.m_clanId, self.m_cardId, state)
end
--------------------------------------------------------------------------------
function InboxPage_send_chooseChip_cell:canClick()
    local choosedList = self.m_mainClass:getChoosed()
    local isChoosed = false
    for i,v in ipairs(choosedList) do
        if self.m_cardId == v.cardId then 
            isChoosed = true
            break
        end    
    end

    if #choosedList >= 5 and not isChoosed then
        return false
    end
    return true
end

function InboxPage_send_chooseChip_cell:clickFunc(sender)
    local name = sender:getName()
    if name == "touch" then
        if not self:canClick() then
            return
        end
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_INBOX_SEND_CHOOSECARD_CELL_UPDATE_STATE, self.m_cardId)
    end
end

function InboxPage_send_chooseChip_cell:onEnter()
    gLobalNoticManager:addObserver(self,function(self,index)
        if tolua.isnull(self) then
            return  
        end
        if self.m_cardId == index then
            local state = self:getState()
            self:changeState(not state)
            -- self:updateTagNum()
            self:updateState()
        end       
    end,ViewEventType.NOTIFY_INBOX_SEND_CHOOSECARD_CELL_UPDATE_STATE)
end

function InboxPage_send_chooseChip_cell:onExit()
    gLobalNoticManager:removeAllObservers(self)
end

function InboxPage_send_chooseChip_cell:addNodeClicked(node)
    if not node then
        return
    end
    node:addTouchEventListener(handler(self, self.nodeClickedEvent))
end
function InboxPage_send_chooseChip_cell:nodeClickedEvent(sender, eventType)
    if eventType == ccui.TouchEventType.began then
        self:clickStartFunc(sender)
    elseif eventType == ccui.TouchEventType.moved then
        self:clickMoveFunc(sender)
    elseif eventType == ccui.TouchEventType.ended then
        self:clickEndFunc(sender)
        local beginPos = sender:getTouchBeganPosition()
        local endPos = sender:getTouchEndPosition()
        local offy = math.abs(endPos.y - beginPos.y)
        if offy < 50 then
            self:clickFunc(sender)
        end
    elseif eventType == ccui.TouchEventType.canceled then
        -- print("Touch Cancelled")
        self:clickEndFunc(sender)
    end
end

return InboxPage_send_chooseChip_cell
