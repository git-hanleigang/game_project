--[[--
    集卡下UI
]]
local CardSeasonBottom = class("CardSeasonBottom", BaseView)

function CardSeasonBottom:initDatas()
    self.m_storeLuaPath = "GameModule.Card.season202203.CardSeasonBottomStore"
    self.m_miniGameLuaPath = "GameModule.Card.season202203.CardSeasonBottomMiniGame"
    self.m_nadoMachineLuaPath = "GameModule.Card.season202203.CardSeasonBottomNadoMachine"
end

function CardSeasonBottom:initCsbNodes()
    self.m_nodeStore = self:findChild("node_store")
    self.m_nodeMiniGame = self:findChild("node_miniGame")
    self.m_nodeNadoMachine = self:findChild("node_nadoMachine")
end

function CardSeasonBottom:getCsbName()
    return string.format(CardResConfig.seasonRes.CardBottomNodeRes, "season202203")
end

function CardSeasonBottom:initUI()
    CardSeasonBottom.super.initUI(self)
    local albumID = CardSysRuntimeMgr:getSelAlbumID()
    if not CardSysRuntimeMgr:isPastAlbum(albumID) then
        self:initStore()
        self:initMiniGame()
        self:initNadoMachine()
    end
    self:playStart()
end

function CardSeasonBottom:initStore()
    if not self.m_storeLuaPath then
        return
    end
    self.m_store = util_createView(self.m_storeLuaPath)
    self.m_nodeStore:addChild(self.m_store)
end

function CardSeasonBottom:initMiniGame()
    if not self.m_miniGameLuaPath then
        return
    end
    self.m_miniGame = util_createView(self.m_miniGameLuaPath)
    self.m_nodeMiniGame:addChild(self.m_miniGame)
end

function CardSeasonBottom:initNadoMachine()
    if not self.m_nadoMachineLuaPath then
        return
    end
    self.m_nadoMachine = util_createView(self.m_nadoMachineLuaPath)
    self.m_nodeNadoMachine:addChild(self.m_nadoMachine)
end

function CardSeasonBottom:playStart(_over)
    self:runCsbAction(
        "show",
        false,
        function()
            if _over then
                _over()
            end
            self:runCsbAction("idle", true, nil, 60)
        end,
        60
    )
end

function CardSeasonBottom:playOver(_over)
    self:runCsbAction("over", false, _over, 60)
end

return CardSeasonBottom
