--[[
    开始界面
]]
local CSStartLayer = class("CSStartLayer", BaseLayer)

function CSStartLayer:initDatas()
    self:setLandscapeCsbName(CardSeekerCfg.csbPath .. "Seeker_StartLayer.csb")
    self:setPauseSlotsEnabled(true)
end

function CSStartLayer:initCsbNodes()
    self.m_nodeCoin = self:findChild("Node_coin")
    self.m_spCoin = self:findChild("sp_coin")
    self.m_lbCoin = self:findChild("lb_coin")
    self.m_btnClose = self:findChild("btn_close")
    self.m_btnGo = self:findChild("btn_go")
    -- self.m_nodenpc = self:findChild("Node_npc")
end

function CSStartLayer:initUI()
    CSStartLayer.super.initUI(self)
    self:initView()
end

function CSStartLayer:initView()
    self:initBtnGo()
    self:initCloseBtn()
    -- self.m_npc = util_spineCreate(CardSeekerCfg.otherPath .. "spine/season202304_npc", true, true)
    -- self.m_nodenpc:addChild(self.m_npc)
    -- util_spinePlay(self.m_npc, "idle", true)
end

function CSStartLayer:initBtnGo()
    if self:isPlaying() then
        local content = gLobalLanguageChangeManager:getStringByKey("CSStartLayer:btn_continue")
        self:setButtonLabelContent("btn_go", content)
    end
end

function CSStartLayer:initCloseBtn()
    self.m_btnClose:setVisible(not self:isPlaying())
end

function CSStartLayer:playShowAction()
    gLobalSoundManager:playSound("Sounds/soundOpenView.mp3")
    CSStartLayer.super.playShowAction(self, "start")
end

function CSStartLayer:onShowedCallFunc()
    self:runCsbAction("idle", true, nil, 60)
end

function CSStartLayer:clickFunc(sender)
    local name = sender:getName()
    if name == "btn_i" then
        G_GetMgr(G_REF.CardSeeker):showRuleLayer()
    elseif name == "btn_close" then
        self:closeUI(
            function()
                G_GetMgr(G_REF.CardSeeker):exitGame()
            end
        )
    elseif name == "btn_go" then
        -- G_GetMgr(G_REF.CardSeeker):showCGLayer()
        self:closeUI(
            function()
                G_GetMgr(G_REF.CardSeeker):showMainLayer()
            end
        )
    end
end

function CSStartLayer:getTSGameData()
    return G_GetMgr(G_REF.CardSeeker):getData()
end

function CSStartLayer:isPlaying()
    local GameData = self:getTSGameData()
    if GameData and GameData:isPlaying() then
        return true
    end
    return false
end

return CSStartLayer
