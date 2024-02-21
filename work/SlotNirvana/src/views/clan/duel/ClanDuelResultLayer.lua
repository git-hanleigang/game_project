--[[
    公会对决 - 对决结果界面（结束后第一次进入公会弹出，告知玩家公会对决胜利还是失败）
--]]
local ClanDuelResultLayer = class("ClanDuelResultLayer", BaseLayer)
local ClanManager = util_require("manager.System.ClanManager"):getInstance()

function ClanDuelResultLayer:ctor()
    ClanDuelResultLayer.super.ctor(self)
    self:setExtendData("ClanDuelResultLayer")
    self:setLandscapeCsbName("Club/csd/Duel/Duel_jiesuan.csb")
end

function ClanDuelResultLayer:initDatas(_status)
    self.m_status = _status or false
    local clanData = ClanManager:getClanData()
    self.m_clanInfo = clanData:getClanSimpleInfo()
end

function ClanDuelResultLayer:initCsbNodes()
    -- logo
    self.m_spTeamLogoBG = self:findChild("sp_clubIconBg")
    self.m_spTeamLogo = self:findChild("sp_clubIcon")
    -- clanName
    self.m_lb_team = self:findChild("lb_team")
    -- duel status
    self.m_vs_up = self:findChild("vs_lan") -- 胜利
    self.m_vs_down = self:findChild("vs_hong") -- 失败
    -- duel describe
    self.m_txt_desc = self:findChild("txt_desc")
    -- spine 
    self.m_node_spine = self:findChild("node_spine")
    -- btn label
    self.m_btn_start = self:findChild("btn_start")
    -- box
    self.m_node_box = self:findChild("node_box")
end

function ClanDuelResultLayer:initView()
    -- 公会Logo
    self:initClanLogo()
    -- 公会名字
    self:initClanName()
    -- 对决状态
    self:initDuelStatusUI()
    -- 对决描述（胜利 or 失败）
    self:initDuelDiscribe()
    -- spine
    -- self:initNpcSpine()
    -- btn label
    self:initBtnLabel()
end

function ClanDuelResultLayer:playShowAction()
    gLobalSoundManager:playSound("Sounds/soundOpenView.mp3")
    local userDefAction = function(callFunc)
        if self.m_spineNode then
            util_spinePlay(self.m_spineNode, "start", false)
            util_spineEndCallFunc(self.m_spineNode, "start", function()
                util_spinePlay(self.m_spineNode, "idle", true)
            end)
        end
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
    ClanDuelResultLayer.super.playShowAction(self, userDefAction)
end

function ClanDuelResultLayer:onShowedCallFunc()
    self:runCsbAction("idle", true)
end

-- 公会 徽章logo
function ClanDuelResultLayer:initClanLogo()
    local clanLogo = self.m_clanInfo:getTeamLogo()
    local imgBgPath = ClanManager:getClanLogoBgImgPath(clanLogo)
    local imgPath = ClanManager:getClanLogoImgPath(clanLogo)
    util_changeTexture(self.m_spTeamLogoBG, imgBgPath)
    util_changeTexture(self.m_spTeamLogo, imgPath)
end

-- 公会 名字
function ClanDuelResultLayer:initClanName()
    local clanName = self.m_clanInfo:getTeamName()
    self.m_lb_team:setString(clanName)
end

-- 对决状态 UI
function ClanDuelResultLayer:initDuelStatusUI()
    local isLead = self.m_status -- true（胜利） or false（失败）
    self.m_vs_up:setVisible(isLead)
    self.m_vs_down:setVisible(not isLead)
end

-- 对决描述（胜利 or 失败）
function ClanDuelResultLayer:initDuelDiscribe()
    local discribe = self.m_status and "CONGRATS! YOUR TEAM WON THE DUEL!" or "SORRY! YOUR TEAM LOST THE DUEL."
    self.m_txt_desc:setString(discribe)
end

-- spine
-- function ClanDuelResultLayer:initNpcSpine()
function ClanDuelResultLayer:initSpineUI()
    ClanDuelResultLayer.super.initSpineUI(self)
    
    self.m_node_box:setVisible(self.m_status)
    if self.m_status then
        local spineNode = util_spineCreate("Club/spine/hlnpc", true, true, 1)
        if spineNode then
            spineNode:addTo(self.m_node_spine)
            self.m_spineNode = spineNode
        end
    end
end

-- btn label
function ClanDuelResultLayer:initBtnLabel()
    self:setButtonLabelContent("btn_start", "GO AHEAD")
end

function ClanDuelResultLayer:clickFunc(sender) 
    local name = sender:getName()
    if name == "btn_close" then
        self:closeUI()
    elseif name == "btn_start" then
        self:closeUI()
    end
end

return ClanDuelResultLayer