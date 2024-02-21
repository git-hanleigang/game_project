--[[
    大厅资源信息
    author:{author}
    time:2022-12-05 17:15:38
]]
local SlotsLobbyEntryInfo = class("SlotsLobbyEntryInfo")

function SlotsLobbyEntryInfo:ctor()
    self.m_levelName = ""
    self.m_iconPath = ""
    self.m_spinPath = ""
    self.m_spineTexture = ""
    self.m_longSpinPath = ""
    self.m_longSpineTexture = ""
end

function SlotsLobbyEntryInfo:updateInfo(levelName)
    self.m_levelName = levelName

    local isExist, spinepath, spineTexture = self:getSpinFileInfo(levelName, "small")
    if isExist then
        self.m_spinPath = spinepath
        self.m_spineTexture = spineTexture
    else
        self.m_spinPath = ""
        self.m_spineTexture = ""
    end

    local isExist, spinepath, spineTexture = self:getSpinFileInfo(levelName, "long")
    if isExist then
        self.m_longSpinPath = spinepath
        self.m_longSpineTexture = spineTexture
    else
        self.m_longSpinPath = ""
        self.m_longSpineTexture = ""
    end
end

function SlotsLobbyEntryInfo:getSpineInfo()
    return (self.m_spinPath ~= ""), self.m_spinPath, self.m_spineTexture
end

function SlotsLobbyEntryInfo:getLongSpineInfo()
    return (self.m_longSpinPath ~= ""), self.m_longSpinPath, self.m_longSpineTexture
end

-- 获得Spin资源信息
function SlotsLobbyEntryInfo:getSpinFileInfo(levelName, prefixName)
    local spineName = self:getSpineFileName(levelName, prefixName)
    local spinepath = "LevelNodeSpine/" .. spineName
    local spinePngName = self:getSpineFileName(levelName, "common")
    local spinePngPath = "LevelNodeSpine/" .. spinePngName
    local spineTexture = spinePngPath .. ".png"

    local pngFullPath = cc.FileUtils:getInstance():fullPathForFilename(spineTexture)
    local isPngExist = cc.FileUtils:getInstance():isFileExist(pngFullPath)
    if not isPngExist then
        spineTexture = spinepath .. ".png"
    end

    local fileNamePath = cc.FileUtils:getInstance():fullPathForFilename(spinepath .. ".skel")
    local isExist = cc.FileUtils:getInstance():isFileExist(fileNamePath)
    if not isExist then
        return false, "", ""
    else
        return true, spinepath, spineTexture
    end
end

-- 获得Spine资源名称
function SlotsLobbyEntryInfo:getSpineFileName(levelName, prefixName)
    prefixName = prefixName or ""
    local fileName = prefixName .. "_level_spine_" .. levelName
    if globalData.GameConfig:checkLevelGroupA(levelName) then
        -- 是AB Test的 A 组
        fileName = fileName .. "_abtest"
    end
    return fileName
end

return SlotsLobbyEntryInfo
