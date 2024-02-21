--[[
    集卡系统  指定卡组中卡片显示面板 数据来源于指定或手动选择的赛季
    201903
--]]
local CardClanView201903 = util_require("GameModule.Card.season201903.CardClanView")
local CardClanView = class("CardClanView", CardClanView201903)
local TEST_GUIDE = false

function CardClanView:initDatas(index, enterFromAlbum)
    CardClanView.super.initDatas(self, index, enterFromAlbum)
    self:setLandscapeCsbName(string.format(CardResConfig.seasonRes.CardClanViewRes, "season302301"))
    self:setName("CardClanView" .. "season302301")
end

function CardClanView:getCellLua()
    return "GameModule.Card.season302301.CardClanCell"
end

function CardClanView:getTitleLua()
    return "GameModule.Card.season302301.CardClanTitle"
end

function CardClanView:getPageNum()
    return 5
end

function CardClanView:getClanData(index)
    local clansData = CardSysRuntimeMgr:getAlbumTalbeviewData()
    return clansData[index]    
end

function CardClanView:onShowedCallFunc()
    CardClanView.super.onShowedCallFunc(self)
    self:checkGuide()
end

-- 点击事件 --
function CardClanView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

    if not self:canClick() then
        return
    end

    if name == "Button_x" then
        gLobalSoundManager:playSound(CardResConfig.CARD_MUSIC.BtnBack)
        CardSysManager:closeCardClanView()
        CardSysManager:showCardAlbumView()
    elseif name == "Button_next1" or name == "layer_left" then
        if self.m_bScrolling == true then
            return
        end
        if self.m_curPageIndex <= 1 then
            return
        end
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        self:movePageDir(1)
    elseif name == "Button_next" or name == "layer_right" then
        if self.m_bScrolling == true then
            return
        end
        if self.m_curPageIndex >= self.m_pageNum then
            return
        end
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        self:movePageDir(-1)
    elseif name == "Mask_Guide" then
        self:removeGuideMask()
    end
end


function CardClanView:hasGuide()
    if TEST_GUIDE then
        return true
    end
    local firstGuideIndex = gLobalDataManager:getNumberByField("Card_Novice_First_Guide_" .. globalData.userRunData.uid, 0)
    if firstGuideIndex == 1 then
        return true
    end
    return false
end

function CardClanView:saveGuideIndex()
    if not TEST_GUIDE then
        gLobalDataManager:setNumberByField("Card_Novice_First_Guide_" .. globalData.userRunData.uid, 2)
    end
end

function CardClanView:getGuideLua()
    return "GameModule.Card.season302301.CardClanCellGuide"
end

function CardClanView:createGuideMask()
    local tLayout = ccui.Layout:create()
    self.m_csbNode:addChild(tLayout, 100)
    tLayout:setName("Mask_Guide")
    tLayout:setTouchEnabled(true)
    tLayout:setSwallowTouches(true)
    tLayout:setAnchorPoint(cc.p(0.5, 0.5))
    tLayout:setPosition(cc.p(display.width / 2, display.height / 2))
    tLayout:setContentSize(cc.size(display.width, display.height))
    tLayout:setClippingEnabled(false)
    tLayout:setBackGroundColorType(ccui.LayoutBackGroundColorType.solid)
    tLayout:setBackGroundColor(cc.c3b(0, 0, 0))
    tLayout:setBackGroundColorOpacity(190)
    tLayout:setScale(1)
    -- tLayout:addTouchEventListener(handler(self, self.clickRoundGuideMask))
    self:addClick(tLayout)
    return tLayout
end

function CardClanView:checkGuide()
    if not self:hasGuide() then 
        return
    end
    self:saveGuideIndex()

    self.m_isGuiding = true
    -- 创建黑色遮罩
    self.m_guideMask = self:createGuideMask()
    -- 提高层级
    local curPageCells = self.m_pageList[self.m_curPageIndex]:getChildren()
    if curPageCells and #curPageCells > 0 then
        local cell = curPageCells[1]
        local guideNode, guideIndex = cell:getGuideNode()
        if guideNode then
            self.m_guideParent = guideNode:getParent()
            self.m_oriScale = guideNode:getScale()
            local scale = self:getNodeGlobalScale(guideNode)
    
            local pos = util_convertToNodeSpace(guideNode, self.m_guideMask)
            util_changeNodeParent(self.m_guideMask, guideNode)
            guideNode:setPosition(pos)
            guideNode:setScale(scale)
            self.m_guideNode = guideNode
    
            -- 引导气泡
            local bubble = util_createView(self:getGuideLua())
            if bubble then
                self.m_guideMask:addChild(bubble)

                local isRight = self:isShowRight(guideIndex)
                local bubbleNode = self:findChild("ndoe_guide_left") 
                if isRight then
                    bubbleNode = self:findChild("ndoe_guide_right")
                end
                local bubblePos = util_convertToNodeSpace(bubbleNode, self.m_guideMask)
                bubble:setPosition(bubblePos)
                bubble:setScale(self:getUIScalePro())
                bubble:updateGuidePosition(isRight)
            end
        end
    end
end

function CardClanView:getNodeGlobalScale(_node)
    local scale = 1
    local _getScale
    _getScale = function(__node)
        if __node then
            scale = scale * __node:getScale()
            if __node:getParent() then
                _getScale(__node:getParent())
            end
        end
    end
    _getScale(_node)
    return scale
end

function CardClanView:isShowRight(_guideIndex)
    if _guideIndex == 1 or _guideIndex == 2 or _guideIndex == 6 or _guideIndex == 7 then
        return true
    end
    return false
end

function CardClanView:removeGuideMask()
    if not self.m_isGuiding then
        return
    end
    self.m_isGuiding = false
    if self.m_guideNode and self.m_guideParent then        
        -- 恢复层级
        local pos = util_convertToNodeSpace(self.m_guideNode, self.m_guideParent)
        util_changeNodeParent(self.m_guideParent, self.m_guideNode)
        self.m_guideNode:setPosition(pos)
        self.m_guideNode:setScale(self.m_oriScale)
        -- 移除遮罩
        if not tolua.isnull(self.m_guideMask) then
            self.m_guideMask:removeFromParent()
            self.m_guideMask = nil
        end
    end
end

return CardClanView
