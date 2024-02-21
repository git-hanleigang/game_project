--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{hl}
    time:2022-04-28 11:35:56
    describe:粉丝团推广
]]
local FBFansViewNew = class("FBFansViewNew", util_require("base.BaseLayer"))

function FBFansViewNew:ctor()
    FBFansViewNew.super.ctor(self)

    self.m_isKeyBackEnabled = true
    self:setLandscapeCsbName("FbFans/FbFans.csb")
end

function FBFansViewNew:initDatas(callback)
    FBFansViewNew.super.initDatas(self)
    self.m_callback = callback
end

function FBFansViewNew:initView()
    --spine
    local node_middle = self:findChild("node_npc")
     self.m_spineNpc = util_spineCreate("FbFans/spine/FBFans_npc", false, true, 1)
     node_middle:addChild(self.m_spineNpc)
     util_spinePlay(self.m_spineNpc, "idle", true)
end

function FBFansViewNew:onShowedCallFunc()
    self:runCsbAction("idle", true)
end

function FBFansViewNew:onKeyBack()
    self:closeUI()
end

function FBFansViewNew:clickFunc(sender)
    local name = sender:getName()
    -- 尝试重新连接 network
    if name == "btn_close" then
        self:closeUI()
    elseif name == "btn_fb" then
        --FBFANS_URL
        -- if globalData.constantData.FBFANS_URL then
            -- cc.Application:getInstance():openURL(globalData.constantData.FBFANS_URL)
            globalPlatformManager:openFB(globalData.constantData:getFbFansUrl())
        -- end
        if globalFireBaseManager.sendFireBaseLogDirect then
            globalFireBaseManager:sendFireBaseLogDirect("FBFansViewNew" .. "_PopupClick", false)
        end
        self:closeUI()
    end
end

function FBFansViewNew:closeUI()
    local callback = function()
        if not tolua.isnull(self) then
            if self.m_callback then
                self.m_callback()
            end
        end
    end
    FBFansViewNew.super.closeUI(self, callback)
end

return FBFansViewNew
