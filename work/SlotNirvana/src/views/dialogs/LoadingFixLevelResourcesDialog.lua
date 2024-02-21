--[[
Author: cxc
Date: 2021-12-17 15:46:00
LastEditTime: 2021-12-17 15:47:06
LastEditors: your name
Description: 清除关卡下载 资源
FilePath: /SlotNirvana/src/views/dialogs/LoadingFixLevelResourcesDialog.lua
--]]
local LoadingControl = require("views.loading.LoadingControl")
local LoadingFixLevelResourcesDialog = class("LoadingFixLevelResourcesDialog", BaseLayer)

function LoadingFixLevelResourcesDialog:ctor(_callback)
    LoadingFixLevelResourcesDialog.super.ctor(self)

    self.m_callback = _callback

    self:setKeyBackEnabled(true)
    self:setLandscapeCsbName("res/Dialog/LoadingFailed_game.csb")
    self:setExtendData("LoadingFixLevelResourcesDialog")
    self:setName("LoadingFixLevelResourcesDialog")
    LoadingControl:getInstance():setPauseLoading(true)
end

function LoadingFixLevelResourcesDialog:onExit()
    LoadingFixLevelResourcesDialog.super.onExit(self)

    LoadingControl:getInstance():setPauseLoading(false)
end

function LoadingFixLevelResourcesDialog:initView()
    LoadingFixLevelResourcesDialog.super.initView(self)
end

function LoadingFixLevelResourcesDialog:clickFunc(sender)
    local name = sender:getName()
    if name == "btn_yes" then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)

        self:clearLevelResources()
        if self.m_callback then
            self.m_callback()
        end
        self:closeUI()
    elseif name == "btn_no" then
        self:closeUI()
    end
end

function LoadingFixLevelResourcesDialog:clearLevelResources()
    local machineData = LoadingControl:getInstance():getMachineData()
    local bGameToLobby = LoadingControl:getInstance():isCurSceneType(SceneType.Scene_Game) and LoadingControl:getInstance():isNextSceneType(SceneType.Scene_Lobby)
    if bGameToLobby then
        machineData = LoadingControl:getInstance():getLastMachineData()
    end

    if not machineData then
        return
    end

    local levelName = machineData.p_levelName
    if not levelName or levelName == "" then
        return
    end

    -- 移除文件
    local machineDirResPath = device.writablePath .. levelName .. "/"
    local machineDirCodePath = device.writablePath .. "GameLevelCode/" .. levelName
    local isRemoved = false
    if cc.FileUtils:getInstance():isDirectoryExist(machineDirResPath) then
        cc.FileUtils:getInstance():removeDirectory(machineDirResPath)
        isRemoved = true
    end
    if cc.FileUtils:getInstance():isDirectoryExist(machineDirCodePath) then
        cc.FileUtils:getInstance():removeDirectory(machineDirCodePath)
        isRemoved = true
    end
    cc.FileUtils:getInstance():purgeCachedEntries()

    -- 清除MD5
    gLobaLevelDLControl:setVersion(levelName, "")
    gLobaLevelDLControl:setVersion(levelName .. "_Code", "")

    -- 清除下载 native to lua通知
    local urlRes = gLobaLevelDLControl:getLevelDownloadUrl(levelName)
    local urlCode = gLobaLevelDLControl:getLevelDownloadUrl(levelName, true)
    if urlRes and util_stopAllDownloadThreadByURL then
        util_stopAllDownloadThreadByURL(urlRes)
    end
    if urlCode and util_stopAllDownloadThreadByURL then
        util_stopAllDownloadThreadByURL(urlCode)
    end

    -- 清除客户端保存的下载列表信息
    gLobaLevelDLControl:removeDownloadInfoByUrl(urlCode)
    gLobaLevelDLControl:removeDownloadInfoByUrl(urlRes)
end

return LoadingFixLevelResourcesDialog
