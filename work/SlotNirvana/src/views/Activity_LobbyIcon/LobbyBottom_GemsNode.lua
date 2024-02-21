local baseView = util_require("baseActivity.BaseLobbyNodeUI")
local LobbyBottom_GemsNode = class("LobbyBottom_BattlePassNode", baseView)

function LobbyBottom_GemsNode:initUI(data)
    self:createCsbNode("Activity_LobbyIconRes/LobbyBottomGemStore.csb")
    self:initView()
    self:updateView()
end

function LobbyBottom_GemsNode:initView()
    self.btnFunc = self:findChild("Button_1")
    self.m_sp_new = self:findChild("sp_new")
    self.m_lockIocn = self:findChild("lockIcon")
end

function LobbyBottom_GemsNode:updateView()
    self.m_lockIocn:setVisible(false)
    self.m_sp_new:setVisible(false)
end

-- 节点处理逻辑 --
function LobbyBottom_GemsNode:clickFunc()
    G_GetMgr(G_REF.Shop):showMainLayer({shopPageIndex = 2})
    self:openLayerSuccess()
end
return LobbyBottom_GemsNode
