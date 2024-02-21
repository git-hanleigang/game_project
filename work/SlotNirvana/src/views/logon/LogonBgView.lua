---
-- Loading 界面，检测是否需要热更
--
-- ios fix
local LogonBgView = class("LogonBgView", BaseLayer)
local loginThemes = {
    normal = "Logon/LogonLayer.csb",
    casino = "Logon/LogonLayer_casino.csb",
    car = "Logon/LogonLayer_car.csb",
    fuliman = "Logon/LogonLayer_fuliman.csb"
}

function LogonBgView:initDatas(params)
    params = params or {}
    self.m_isRestartGame = params.isRestartGame or false
    self:setShowActionEnabled(false)
    self:setHideActionEnabled(false)

    local newInstallApp = false
    -- 这个值是默认登录过之后就会获取的并且存盘的,如果获取不到的情况的情况会默认返回 "" 字符串,这里需要获取另外一个默认值
    -- 只有新版本才生效
    local bVersion = true
    -- if device.platform == "ios" then
    --     if util_isSupportVersion("1.6.5") then
    --         bVersion = true
    --     end
    -- elseif device.platform == "android" then
    --     if util_isSupportVersion("1.5.8") then
    --         bVersion = true
    --     end
    -- end
    -- =================
    -- 处理之前存错的玩家
    local oldid = gLobalDataManager:getStringByField("adjust_id", "")
    if oldid == "nosave" then
        gLobalDataManager:setStringByField("adjust_id", "")
    end
    -- =================
    local idid = gLobalDataManager:getStringByField("adjust_id", "nosave")
    -- release_print("----csc LogonBgView idid = "..tostring(idid))
    if bVersion and idid == "nosave" then
        -- 当前是重新装包的用户
        if gLobalDataManager:getBoolByField("newAppOpenShowDefaultLogonLayer", false) == false then
            -- release_print("----csc LogonBgView newInstallApp = true")
            newInstallApp = true
            gLobalDataManager:setBoolByField("newAppOpenShowDefaultLogonLayer", true)
        end
    end

    local logonLayerCsbPath = globalData.GameConfig:getLoginThemeCsb(loginThemes, newInstallApp)
    self:setLandscapeCsbName(logonLayerCsbPath)
end

-- function LogonBgView:initUI(data)
--     -- setDefaultTextureType("RGBA8888", nil)

--     LogonBgView.super.initUI(self, data)

--     self:playEnterGame()

--     release_print("LogonBgView:initUI")

--     -- setDefaultTextureType("RGBA4444", nil)
-- end

function LogonBgView:playEnterGame()
    self:runCsbAction("enter_game", true)
end

function LogonBgView:playButton()
    self:runCsbAction("button", true)
end

-- function LogonBgView:initSpineUI()
--     self.m_nodeSpine = self:findChild("node_spine")
--     if self.m_nodeSpine then
--         -- 圣诞23
--         self.m_spine = util_spineCreate("Logon/Other/spine/LogonLayer_Christmas2023/LogonLayer_Christmas2023", true, true, 1)
--         self.m_nodeSpine:addChild(self.m_spine)
--     end
-- end

function LogonBgView:onEnter()
    LogonBgView.super.onEnter(self)

    -- setDefaultTextureType("RGBA4444", nil)
    self:playEnterGame()
    
    if self.m_spine then
        util_spinePlay(self.m_spine, "idle", true)
    end
end

return LogonBgView
