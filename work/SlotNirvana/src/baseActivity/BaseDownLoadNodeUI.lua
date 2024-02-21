local BaseDownLoadNodeUI = class("BaseDownLoadNodeUI", util_require("base.BaseView"))

function BaseDownLoadNodeUI:initUI(...)
    self:createCsbNode(self:getCsbName())
end

function BaseDownLoadNodeUI:onEnter()
    BaseDownLoadNodeUI.super.onEnter(self)
    self:registerListener()
end

function BaseDownLoadNodeUI:registerListener()
    local downLoadLockBg, downLoadProcess = nil, nil
    local downLoadKey = self:getDownLoadRelevancyKey()
    if downLoadKey then
        -- if globalDynamicDLControl:getKeyOpenStatus(downLoadKey) then
        if globalDynamicDLControl:checkDownloading(downLoadKey) then
            -- print("--- 当前需要下载的资源在开启列表中 --- key == "..self:getDownLoadRelevancyKey())
            downLoadLockBg, downLoadProcess = util_addDownLoadingNodeNew(self:getDownLoadingNode(), downLoadKey, self:getProgressPath())
        else
            -- print("--- 当前需要下载的资源不在开启列表中 --- key == "..self:getDownLoadRelevancyKey())
        end
    end

    self.downLoadLockBg, self.downLoadProcess = downLoadLockBg, downLoadProcess
    if downLoadLockBg ~= nil and downLoadProcess ~= nil then
        local offsetX, offsetY = self:getProcessBgOffset()
        if offsetX ~= nil then
            downLoadLockBg:setPositionX(downLoadLockBg:getPositionX() + offsetX)
            downLoadProcess:setPositionX(downLoadProcess:getPositionX() + offsetX)
        end
        if offsetY ~= nil then
            downLoadLockBg:setPositionY(downLoadLockBg:getPositionY() + offsetY)
            downLoadProcess:setPositionY(downLoadProcess:getPositionY() + offsetY)
        end
        self:initProcessFunc()
        gLobalNoticManager:addObserver(
            self,
            function(target, percent)
                if percent > 0 and percent < 1 then
                    if self.downLoadProcess ~= nil then
                        self.downLoadProcess:setPercentage(math.min(95, 100 - math.ceil(percent * 100))) --新版x 镜像100 减一下 (不要全黑留5%让玩家以为下载)
                    end
                elseif percent < 0 then
                    if self.downLoadProcess ~= nil then
                        self.downLoadProcess:setPercentage(95) --新版x 镜像100 减一下  (不要全黑留5%让玩家以为下载)
                    end
                end
            end,
            "DL_Percent" .. tostring(downLoadKey)
        )

        gLobalNoticManager:addObserver(
            self,
            function(target, percent)
                self:removeDownLoadProcess()
                self:endProcessFunc()
            end,
            "DL_Complete" .. tostring(downLoadKey)
        )
    end
end

function BaseDownLoadNodeUI:removeDownLoadProcess()
    if not tolua.isnull(self.downLoadLockBg) then
        if self.downLoadLockBg.playShowSourceAct then
            self.downLoadLockBg:playShowSourceAct()
        else
            self.downLoadLockBg:removeSelf()
        end
    end
    if not tolua.isnull(self.downLoadProcess) then
        self.downLoadProcess:removeSelf()
    end
    self.downLoadLockBg = nil
    self.downLoadProcess = nil
end

------------------------------------------子类重写---------------------------------------
--开始下载回调
function BaseDownLoadNodeUI:initProcessFunc()
end

--下载结束回调
function BaseDownLoadNodeUI:endProcessFunc()
end

--关联代码
function BaseDownLoadNodeUI:getDownLoadRelevancyKey()
    local themeName = self:getDownLoadKey()
    if not self.m_downLoadRelevancyKeyName then
        if globalDynamicDLControl.getDownloadingRelevancyName and globalDynamicDLControl:getDownloadingRelevancyName(themeName) ~= nil then
            self.m_downLoadRelevancyKeyName = globalDynamicDLControl:getDownloadingRelevancyName(themeName)
        end
    end
    --关联名字解决没有资源只有代码下载情况
    if self.m_downLoadRelevancyKeyName then
        themeName = self.m_downLoadRelevancyKeyName
    end
    if themeName then
    -- release_print("RelevancyKey name = "..themeName)
    end
    return themeName
end
--下载的key值，用来标识是否下载完成
function BaseDownLoadNodeUI:getDownLoadKey()
    return nil
end

--获得下载进度图片路径
function BaseDownLoadNodeUI:getProgressPath()
    return nil
end

--获得下载进度图片偏移
function BaseDownLoadNodeUI:getProcessBgOffset()
    return nil, nil
end

function BaseDownLoadNodeUI:getDownLoadingNode()
    return self
end
------------------------------------------子类重写---------------------------------------
return BaseDownLoadNodeUI
