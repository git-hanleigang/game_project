---
-- GameLayer 代理类， 主要用来处理关卡创建
--
-- island create on 2018-07-04 15:54:24

-- 定义game layer 中的层级关系

local GameLayerDelegate = class("GameLayerDelegate")

function GameLayerDelegate:getMachineLayer(machineEnterData)
    -- local machineEnterData = globalData.slotRunData.machineData

    if machineEnterData == nil or machineEnterData.p_levelName == nil then
        return nil -- 保证必须要有值
    end

    if machineEnterData.p_freeOpen ~= nil then
        -- gLobalViewManager:gotoSceneByType(SceneTypeEnum.SCENE_GAME)
    else
        local moduleName = machineEnterData.p_levelName
        if moduleName == "" then
            return
        end
        local fullFilePath = nil
        if CC_IS_READ_DOWNLOAD_PATH == true then -- 是否从远程地址下载关卡
            fullFilePath = cc.FileUtils:getInstance():fullPathForFilename(string.format("%s/%s", device.writablePath, moduleName .. "_Code")) -- 去搜索路径找是否有这个文件夹
        else
            --abTest 方便mac下查找abtest路径
            local data = globalData.GameConfig:checkABTestData(moduleName)
            if data then
                local newPath = string.format("ABTest/%s/%s", data.groupKey, moduleName .. "_Code")
                fullFilePath = cc.FileUtils:getInstance():fullPathForFilename(newPath)
            else
                fullFilePath = cc.FileUtils:getInstance():fullPathForFilename(moduleName)
            end
        end

        local hasMachine = cc.FileUtils:getInstance():isFileExist(fullFilePath)

        if hasMachine == true or (hasMachine == false and CC_IS_READ_DOWNLOAD_PATH == false) then
            -- gLobalViewManager:gotoSceneByType(SceneTypeEnum.SCENE_GAME)
        else
            return nil
        end
    end

    -- 设置显示的横竖屏
    globalData.slotRunData:setFramePortrait(machineEnterData.p_portraitFlag)

    -- 获取main class name
    local machineClassName = self:getMachineClassNameAndAddSearchPath(machineEnterData)

    return machineClassName
end

function GameLayerDelegate:isInSearchPath(path)
    local searchPaths = cc.FileUtils:getInstance():getSearchPaths()
    if searchPaths ~= nil then
        for k, v in ipairs(searchPaths) do
            if v == path then
                return true
            end
        end
    end
    return false
end

--修复老包迁移关卡代码时，搜索路径先搜索src下的bug
function GameLayerDelegate:fixSearchPath()
    local searchPaths = cc.FileUtils:getInstance():getSearchPaths()
    if searchPaths ~= nil then
        local writablePath = device.writablePath
        local defaultPath = cc.FileUtils:getInstance():getDefaultResourceRootPath()
        local removeSearchPathList = {}
        local index = 1
        while index <= #searchPaths do
            local searchPath = searchPaths[index]
            if
                (searchPath == writablePath or searchPath == writablePath .. "src/" or searchPath == writablePath .. "res/" or searchPath == defaultPath or searchPath == defaultPath .. "src/" or
                    searchPath == defaultPath .. "res/")
             then
                table.remove(searchPaths, index)
                table.insert(removeSearchPathList, searchPath)
            else
                index = index + 1
            end
        end
        for k, v in ipairs(removeSearchPathList) do
            table.insert(searchPaths, v)
        end
        cc.FileUtils:getInstance():setSearchPaths(searchPaths)
    end
end

---
-- 获取class lua 和 添加搜索路径
--
function GameLayerDelegate:getMachineClassNameAndAddSearchPath(machineEnterData)
    -- local machineEnterData = globalData.slotRunData.machineData
    local machineClassName = nil
    if machineEnterData ~= nil then
        local moduleName = machineEnterData.p_levelName
        local modulePath = moduleName
        local CodeName = moduleName
        if CC_LEVEL_SRC_CODE_ENABLE then
            modulePath = "GameLevelCode/" .. moduleName
            CodeName = "Code" .. moduleName
            if device.platform == "mac" then
                local rootPath = cc.FileUtils:getInstance():getDefaultResourceRootPath()
                if not self:isInSearchPath(rootPath .. "GameLevelCode/") then
                    cc.FileUtils:getInstance():addSearchPath("GameLevelCode")
                end
                if not self:isInSearchPath(rootPath .. modulePath) then
                    cc.FileUtils:getInstance():addSearchPath(modulePath)
                end
            else
                -- 沙盒路径
                if not self:isInSearchPath(device.writablePath .. "GameLevelCode/") then
                    cc.FileUtils:getInstance():addSearchPath(device.writablePath .. "GameLevelCode/")
                end
                cc.FileUtils:getInstance():addSearchPath(device.writablePath .. modulePath)
                -- 整包路径
                cc.FileUtils:getInstance():addSearchPath("GameLevelCode/")
                cc.FileUtils:getInstance():addSearchPath(modulePath)
            end
            -- if not self:isInSearchPath(device.writablePath .. "src/GameLevelCode/") then
            --     cc.FileUtils:getInstance():addSearchPath(device.writablePath .. "src/GameLevelCode")
            -- end
            -- cc.FileUtils:getInstance():addSearchPath(device.writablePath .. "src/" .. modulePath)

            -- if not self:isInSearchPath(cc.FileUtils:getInstance():getDefaultResourceRootPath() .. "src/GameLevelCode/") then
            --     cc.FileUtils:getInstance():addSearchPath("src/GameLevelCode")
            -- end
            -- cc.FileUtils:getInstance():addSearchPath("src/" .. modulePath)
        end
        local hasWritePath = cc.FileUtils:getInstance():isDirectoryExist(device.writablePath .. moduleName)
        if machineEnterData.p_freeOpen and hasWritePath == false then
            cc.FileUtils:getInstance():addSearchPath(moduleName)
            machineClassName = string.format("%sMachine", CodeName)
            printInfo("主类文件 %s", machineClassName)
        else
            if CC_IS_READ_DOWNLOAD_PATH == false then
                --abTest 方便mac下查找abtest路径
                local data = globalData.GameConfig:checkABTestData(moduleName)
                if data then
                    cc.FileUtils:getInstance():addSearchPath("ABTest/" .. data.groupKey .. "/" .. moduleName)
                    cc.FileUtils:getInstance():addSearchPath("ABTest/" .. data.groupKey .. "/" .. modulePath)
                    machineClassName = string.format("ABTest.%s.%s.%sMachine", data.groupKey, moduleName, moduleName)
                else
                    cc.FileUtils:getInstance():addSearchPath(moduleName)
                    cc.FileUtils:getInstance():addSearchPath(modulePath)
                    machineClassName = string.format("%sMachine", CodeName)
                end
                printInfo("主类文件 %s", machineClassName)
            else
                cc.FileUtils:getInstance():addSearchPath(device.writablePath .. moduleName) -- 正式跑下载目录时走这个下载
                machineClassName = string.format("%sMachine", CodeName)
            end
        end
        self:fixSearchPath()
    end

    return machineClassName
end

return GameLayerDelegate
