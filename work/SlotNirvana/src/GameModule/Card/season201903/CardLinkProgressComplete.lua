--[[
    -- link卡集齐进度面板
]]
-- local BaseView = util_require("base.BaseView")
local BaseCardComplete = util_require("GameModule.Card.baseViews.BaseCardComplete")
local CardLinkProgressComplete = class("CardLinkProgressComplete", BaseCardComplete)

local TEST_DATA = {
    cards = {
        4,
        9,
        14,
        18,
        22
    },
    currentCards = 2,
    games = {
        6,
        10,
        20,
        35,
        55
    }
}

function CardLinkProgressComplete:initDatas(params)
    CardLinkProgressComplete.super.initDatas(self, params)
    self.m_data = self.m_params.data
    self.m_isShowIncrease = self.m_params.isDrop
    self.m_srcNum = self.m_params.srcNum
    self.m_tarNum = self.m_params.tarNum or CardSysRuntimeMgr:getNadoCollectCount()

    self:setLandscapeCsbName(string.format(CardResConfig.commonRes.linkProgress201903, "common" .. CardSysRuntimeMgr:getCurAlbumID()))

    self:addClickSound({"Button_collect"}, SOUND_ENUM.SOUND_HIDE_VIEW)
end

function CardLinkProgressComplete:getProgressMarkLua()
    return "GameModule.Card.season201903.CardLinkProgressMark"
end

function CardLinkProgressComplete:getProgressNodeLua()
    return "GameModule.Card.season201903.CardLinkProgressNode"
end

function CardLinkProgressComplete:initUI(data, isShowIncrease)
    CardLinkProgressComplete.super.initUI(self)

    if globalData.slotRunData.checkViewAutoClick then
        globalData.slotRunData:checkViewAutoClick(self, "Button_collect")
    end

    self.m_jindu = self:findChild("jindu")
    self.m_btnCollect = self:findChild("Button_collect")
    self.m_btnCollect:setTouchEnabled(false)

    self:initTotal()
    self:initProgressInfo()
    self:initMark()
end

function CardLinkProgressComplete:playShowAction()
    gLobalSoundManager:playSound("Sounds/soundOpenView.mp3")
    CardLinkProgressComplete.super.playShowAction(self, "show", false, 30)
end

function CardLinkProgressComplete:onShowedCallFunc()
    self:runCsbAction("idle", true)

    self:showIncrease()
end

function CardLinkProgressComplete:getTotal()
    local albumID = CardSysRuntimeMgr:getCurAlbumID()
    local info = CardSysRuntimeMgr:getSeasonData():getAlbumDataById(albumID)
    if info then
        return info.clans or 0
    else
        return 0
    end
end

function CardLinkProgressComplete:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()
    if name == "Button_collect" then
        if self.m_clickCollect then
            return
        end
        self.m_clickCollect = true
        self.m_btnCollect:setTouchEnabled(false)
        CardSysManager:closeCardCollectComplete()
    end
end

function CardLinkProgressComplete:closeUI()
    local _callback = function()
        if self.m_isShowIncrease then
            local rewardNum = 0
            for i = 1, #self.m_data.cards do
                -- if self.m_data.cards[i] == self.m_data.currentCards then
                if self.m_data.cards[i] > self.m_srcNum and self.m_data.cards[i] <= self.m_tarNum then
                    rewardNum = rewardNum + self.m_data.games[i]
                end
            end
            if rewardNum > 0 then
                CardSysManager:getLinkMgr():showCardLinkComplete(rewardNum)
            else
                if CardSysManager:getLinkMgr():isNeedEnterNado() then
                    -- 防止嵌套打开界面卡死
                    if not CardSysManager:getLinkMgr():hasNadoMachineUI() then
                        -- 要进入Nado机，展示Nado机
                        CardSysManager:showNadoMachine("drop")
                        CardSysManager:setNadoMachineOverCall(
                            function()
                                CardSysManager:getDropMgr():doNextDropView()
                            end
                        )
                        CardSysManager:getLinkMgr():setNeedEnterNado(false)
                    else
                        CardSysManager:getDropMgr():doNextDropView()
                    end                    
                else
                    CardSysManager:getDropMgr():doNextDropView()
                end
            end
        end
    end
    CardLinkProgressComplete.super.closeUI(self, _callback)
end

function CardLinkProgressComplete:initTotal()
    local totalLb = self:findChild("BitmapFontLabel_13")
    totalLb:setString(self:getTotal())
end

function CardLinkProgressComplete:initMark()
    -- dump(self.m_data, "--- CardLinkProgressComplete:initMark", 6)
    local data = self.m_data
    local length = self.m_proNode:getProcessSize().width
    local max = self:getTotal()
    local jinduOffsetX = self.m_proNode:getProcessOffsetX()
    local startX = self.m_jindu:getPositionX() + jinduOffsetX
    local markNodes = {}
    self.m_markNodes = markNodes
    for k, v in ipairs(data.cards) do
        local markNode = self:findChild("NadoSpin_" .. k)
        local view = util_createView(self:getProgressMarkLua(), k, v, data.games[k])
        markNode:addChild(view)
        markNode:setPositionX(startX + v / max * length)
        table.insert(markNodes, view)
        view:showMark(self.m_isShowIncrease and self.m_srcNum or self.m_tarNum)
    end
end

function CardLinkProgressComplete:initProgressInfo()
    self.m_proNode = util_createView(self:getProgressNodeLua())
    self.m_jindu:addChild(self.m_proNode)
    self.m_proNode:setProgressText(self.m_tarNum)
    self.m_proNode:setProgressInfo(self.m_isShowIncrease and self.m_srcNum or self.m_tarNum)
end

function CardLinkProgressComplete:showIncrease()
    -- 播放增长动画
    if self.m_isShowIncrease then        
        self.m_proNode:startIncrease(
            self.m_srcNum,
            self.m_tarNum,
            function(_cardNum)
                -- print("!!! _cardNum == ", _cardNum)
                for k, v in ipairs(self.m_markNodes) do
                    v:showMark(_cardNum, true)
                end
            end,
            function()
                self.m_btnCollect:setTouchEnabled(true)
            end
        )
    else
        self.m_btnCollect:setTouchEnabled(true)
    end
end

return CardLinkProgressComplete
