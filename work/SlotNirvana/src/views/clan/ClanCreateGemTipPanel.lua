-- 花费钻石 创建公会弹板

local ClanManager = util_require("manager.System.ClanManager"):getInstance()
local ClanCreateGemTipPanel = class("ClanCreateGemTipPanel", BaseLayer)

function ClanCreateGemTipPanel:ctor()
    ClanCreateGemTipPanel.super.ctor(self)
    self:setLandscapeCsbName("Club/csd/Tanban/ClubCreateWarning.csb")
    self:setKeyBackEnabled(true) 
end

function ClanCreateGemTipPanel:initUI()
    ClanCreateGemTipPanel.super.initUI(self)
    
    -- 钻石数值
    -- local lb_gem = self:findChild("lb_gem")
    local clanData = ClanManager:getClanData()
    local gem_cost = clanData:getGemCost()
    -- if lb_gem and gem_cost > 0 then
    --     lb_gem:setString( gem_cost )
    -- end
    local LanguageKey = "ClanCreateGemTipPanel:btn_gems"
    local refStr = gLobalLanguageChangeManager:getStringByKey(LanguageKey) or "%d"
    local str = string.format(refStr, gem_cost)
    self:setButtonLabelContent("btn_gems", str)
end

function ClanCreateGemTipPanel:clickFunc(sender)
    local name = sender:getName()
    -- gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)

    if name == "btn_close" then
        -- 关闭按钮
        self:closeUI()
    elseif name == "btn_gems" then
        local clanData = ClanManager:getClanData()
        local gem_cost = clanData:getGemCost()
        local userGemsNum = globalData.userRunData.gemNum or 0 -- 当前玩家的宝石数
        if gem_cost <= userGemsNum then
            ClanManager:sendClanGemCreate()
            self:closeUI()
        else
            -- 去商城
            local params = {shopPageIndex = 2 , dotKeyType = "btn_buy", dotUrlType = DotUrlType.UrlName , dotIsPrep = false}
            local view = G_GetMgr(G_REF.Shop):showMainLayer(params)
            view.buyShop = true
        end
    end
end

return ClanCreateGemTipPanel