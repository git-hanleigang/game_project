--[[
    magic卡四个章节的主界面
    新增
]]
local CardSpecialAlbumUI = class("CardSpecialAlbumUI", BaseLayer)

function CardSpecialAlbumUI:initDatas(_isOpenCardLobby)
    self.m_isOpenCardLobby = _isOpenCardLobby
    local themeName = G_GetMgr(G_REF.CardSpecialClan):getThemeName()

    self.m_coinLuaPath = "views.Card." .. themeName .. ".mainUI.CardSpecialAlbumCoins"

    self:setLandscapeCsbName("CardRes/" .. themeName .. "/csb/main/MagicAlbumMainLayer.csb")
end

function CardSpecialAlbumUI:initCsbNodes()
    self.m_loadingbars = {}
    self.m_lbPros = {}
    self.m_efPros = {}
    self.m_spCompletes = {} -- 对号
    self.m_nodeStageEfs = {} -- 完成时的台子特效节点
    self.m_nodeContactEfs = {} -- 完成时的链接特效节点
    for i=1,CardSpecialClanCfg.QuestMagicClanNum do
        local loadingBar = self:findChild("LoadingBar_".. i)
        local lbPro = self:findChild("lb_pro_".. i)
        local efPro = self:findChild("ef_jdt_".. i)
        local spComplete = self:findChild("sp_complete_".. i)
        local efStage = self:findChild("ef_stage_".. i)
        local efContact = self:findChild("ef_contact_".. i)
        table.insert(self.m_loadingbars, loadingBar)
        table.insert(self.m_lbPros, lbPro)
        table.insert(self.m_efPros, efPro)
        table.insert(self.m_spCompletes, spComplete)
        table.insert(self.m_nodeStageEfs, efStage)
        table.insert(self.m_nodeContactEfs, efContact)
    end
    self.m_nodeCoin = self:findChild("node_coin")
    self.m_nodeBigStageEf = self:findChild("ef_stage_big")
end

function CardSpecialAlbumUI:initView()
    self:initClans()
    self:initBigStage()
    self:initAlbumCoin()
end

function CardSpecialAlbumUI:initClans()
    local data = G_GetMgr(G_REF.CardSpecialClan):getData()
    if not data then
        return
    end
    for i = 1, CardSpecialClanCfg.QuestMagicClanNum do
        local clanData = data:getSpecialClanByIndex(i)
        local cur = clanData:getHaveCardNum()
        local max = clanData:getCardNum()
        local percent = cur/max*100
        local isClanComplete = percent == 100
        local bar = self.m_loadingbars[i]
        local barSize = nil
        if bar then
            barSize = bar:getContentSize()
            bar:setPercent(percent)
        end
        -- 章节完成标签
        local spComplete = self.m_spCompletes[i]
        if spComplete then
            spComplete:setVisible(isClanComplete)
        end   
        -- 进度数字
        local lbPro = self.m_lbPros[i]
        if lbPro then
            if isClanComplete then
                lbPro:setVisible(false)
            else
                lbPro:setVisible(true)
                lbPro:setString(cur .. "/" .. max)
            end
        end
        -- 进度条特效
        local efPro = self.m_efPros[i]
        if efPro then
            if percent == 0 or isClanComplete then
                efPro:setVisible(false)
            else
                efPro:setVisible(true)
                local len = (percent/100)*barSize.width
                efPro:setPositionX(len)
            end
        end
        -- 章节完成效果
        if isClanComplete then
            -- 台子的光效
            local nodeStageEf = self.m_nodeStageEfs[i]
            if nodeStageEf then
                local stageEf = self:createClanStageLight(i)
                if stageEf then
                    nodeStageEf:addChild(stageEf)
                end
            end
            -- 连接的光效
            local nodeContactEf = self.m_nodeContactEfs[i]
            if nodeContactEf then
                local contactEf = self:createClanContactLight(i)
                if contactEf then
                    nodeContactEf:addChild(contactEf)
                end
            end     
        end
    end
end

function CardSpecialAlbumUI:initBigStage()
    local data = G_GetMgr(G_REF.CardSpecialClan):getData()
    if not data then
        return
    end
    if data:isAlbumCompleted() then
        local ef = self:createAlbumLight()
        self.m_nodeBigStageEf:addChild(ef)
    end
end

function CardSpecialAlbumUI:createAlbumLight()
    local themeName = G_GetMgr(G_REF.CardSpecialClan):getThemeName()
    local ef = util_createAnimation("CardRes/" .. themeName .. "/csb/main/MagicAlbumEffect_up_center.csb")
    ef:playAction("idle", true, nil, 60)
    return ef
end

function CardSpecialAlbumUI:createClanStageLight(_clanIndex)
    local themeName = G_GetMgr(G_REF.CardSpecialClan):getThemeName()
    local ef = util_createAnimation("CardRes/" .. themeName .. "/csb/main/MagicAlbumEffect_up.csb")
    ef:playAction("idle", true, nil, 60)
    return ef
end

function CardSpecialAlbumUI:createClanContactLight(_clanIndex)
    local themeName = G_GetMgr(G_REF.CardSpecialClan):getThemeName()
    local ef = util_createAnimation("CardRes/" .. themeName .. "/csb/main/MagicAlbumEffect_di_" .. _clanIndex .. ".csb")
    ef:playAction("idle", true, nil, 60)
    return ef
end

function CardSpecialAlbumUI:initAlbumCoin()
    self.m_coins = util_createView(self.m_coinLuaPath)
    self.m_nodeCoin:addChild(self.m_coins)
end

function CardSpecialAlbumUI:clickFunc(sender)
    local name = sender:getName()
    if name == "btn_close" then
        CardSysManager:showCardAlbumView()
        self:closeUI()
    elseif name == "btn_info" then
        G_GetMgr(G_REF.CardSpecialClan):showInfoLayer()
    elseif name == "btn_clan_1" then
        G_GetMgr(G_REF.CardSpecialClan):showClanLayer(1, self.m_isOpenCardLobby)
    elseif name == "btn_clan_2" then
        G_GetMgr(G_REF.CardSpecialClan):showClanLayer(2, self.m_isOpenCardLobby)
    elseif name == "btn_clan_3" then
        G_GetMgr(G_REF.CardSpecialClan):showClanLayer(3, self.m_isOpenCardLobby)
    elseif name == "btn_clan_4" then
        G_GetMgr(G_REF.CardSpecialClan):showClanLayer(4, self.m_isOpenCardLobby)
    end
end

function CardSpecialAlbumUI:onEnter()
    CardSpecialAlbumUI.super.onEnter(self)
end

function CardSpecialAlbumUI:onShowedCallFunc()
    self:runCsbAction("idle", true, nil, 60)
end

function CardSpecialAlbumUI:onExit()
    CardSpecialAlbumUI.super.onExit(self)
end

return CardSpecialAlbumUI