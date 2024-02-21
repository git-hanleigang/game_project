-- Created by jfwang on 2019-05-21.
-- QuestCell
--
local QuestCell = class("QuestCell", util_require("base.BaseView"))
function QuestCell:getCsbNodePath()
    return QUEST_RES_PATH.QuestCellDL
end
function QuestCell:initUI(info,successCallFun,failedCallFun)
    self.m_info = info
    self.m_successCallFun = successCallFun
    self.m_failedCallFun = failedCallFun
    self:createCsbNode(self:getCsbNodePath())
    self:initView()
end
function QuestCell:initView()
    self.m_lb_progress = self:findChild("m_lb_progress")
    self.m_sp_content = self:findChild("sp_content")
    self:initProgress(self.m_sp_content)
    self.m_sp_content:setVisible(false)
end
function QuestCell:initProgress(content)
    -- 创建进度条
    local img = util_createSprite("QuestOther/QuestLink_jinduyuanm.png")
    if not img then
        release_print("initProgress = QuestOther/QuestLink_jinduyuanm.png")
        return 
    end

    self.m_loadingProgress = cc.ProgressTimer:create(img)
    self.m_loadingProgress:setType(cc.PROGRESS_TIMER_TYPE_RADIAL)
    self.m_loadingProgress:setPercentage(0)
    self.m_loadingProgress:setPosition(0, 0)
    self:addChild(self.m_loadingProgress)
end

--刷新开始下载状态
function QuestCell:updateStartDl(percent)
    if percent then
        self:updatePercent(percent)
    else
        self:updatePercent(0.01)
    end
    
end
--刷新下载状态
function QuestCell:updatePercent(percent)
    self.m_percent = percent
    --下载失败
    if percent == -1 then
        -- 提示弹框
        gLobalViewManager:showDialog("Dialog/DowanLoadLevelFailed.csb",function()
        end, nil, nil, nil)
        if self.m_failedCallFun then
            self.m_failedCallFun()
        end
    elseif percent == 2 then
        if self.m_successCallFun then
            self.m_successCallFun()
        end
    else
        if self.m_loadingProgress then
            self.m_loadingProgress:setPercentage(math.ceil(percent * 100))
            self.m_lb_progress:setString(math.ceil(percent * 100).."%")
        end
    end
end


function QuestCell:onEnter( )
    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            self:updatePercent(params)
        end,
        "LevelPercent_" .. self.m_info.p_levelName
    )
end

return QuestCell