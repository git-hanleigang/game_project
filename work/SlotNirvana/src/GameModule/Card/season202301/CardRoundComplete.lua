--[[
    轮次完成后展示下一轮开启的界面
]]
local CardRoundComplete = class("CardRoundComplete", BaseLayer)

function CardRoundComplete:initDatas(_nextRound, _callFunc)
    self:setLandscapeCsbName("CardRes/common" .. CardSysRuntimeMgr:getCurAlbumID() .. "/CardComplete202301_round.csb")
    self.m_nextRound = _nextRound
    self.m_callFunc = _callFunc
end

function CardRoundComplete:initCsbNodes()
    self.m_spTitle2 = self:findChild("sp_title_round2")
    self.m_spTitle3 = self:findChild("sp_title_round3")
    self.m_spRound2 = self:findChild("sp_round_2")
    self.m_spRound3 = self:findChild("sp_round_3")
    self.m_lbNum = self:findChild("lb_num")
end

function CardRoundComplete:initView()
    self:initTitle()
    self:initIcon()
    self:initBonus()
    self:initBtn()
end

function CardRoundComplete:initTitle()
    self.m_spTitle2:setVisible(self.m_nextRound == 2)
    self.m_spTitle3:setVisible(self.m_nextRound == 3)
end

function CardRoundComplete:initIcon()
    self.m_spRound2:setVisible(self.m_nextRound == 2)
    self.m_spRound3:setVisible(self.m_nextRound == 3)
end

-- {300%, 600%}
function CardRoundComplete:initBonus()
    local mul = nil
    if self.m_nextRound == 2 then
        mul = "300%"
    elseif self.m_nextRound == 3 then
        mul = "600%"
    end
    if mul then
        self.m_lbNum:setString(mul)
    end
end

function CardRoundComplete:initBtn()
    local str = gLobalLanguageChangeManager:getStringByKey("CardRoundComplete:btn_go")
    local preStr = nil
    if self.m_nextRound == 2 then
        preStr = "2ND"
    elseif self.m_nextRound == 3 then
        preStr = "3RD"
    end
    self:setButtonLabelContent("btn_go", string.format(str, preStr))
end

function CardRoundComplete:clickFunc(sender)
    local name = sender:getName()
    if name == "btn_go" then
        self:closeUI()
    -- if CardSysRuntimeMgr:isInCard() then
    --     self:closeUI()
    -- else
    --     self:closeUI(
    --         function()
    --             -- 打开集卡系统
    --             if CardSysManager:isDownLoadCardRes() then
    --                 CardSysRuntimeMgr:setIgnoreWild(true)
    --                 CardSysManager:enterCardCollectionSys()
    --             end
    --         end
    --     )
    -- end
    end
end

function CardRoundComplete:playShowAction(userDefAction, isLoop, fps)
    gLobalSoundManager:playSound("CardRes/music/card_round_open.mp3")
    CardRoundComplete.super.playShowAction(self, "start")
end

function CardRoundComplete:playHideAction(userDefAction, isLoop, fps)
    gLobalSoundManager:playSound("Sounds/soundHideView.mp3")
    CardRoundComplete.super.playHideAction(self, "over")
end

function CardRoundComplete:onShowedCallFunc()
    self:runCsbAction("idle", true, nil, 60)
end

function CardRoundComplete:closeUI(_over)
    CardRoundComplete.super.closeUI(
        self,
        function()
            if _over then
                _over()
            end
            if self.m_callFunc then
                self.m_callFunc()
            end
        end
    )
end

function CardRoundComplete:onEnter()
    CardRoundComplete.super.onEnter(self)
end

return CardRoundComplete
