--星星奖励界面进度节点
local QuestNewChapterStarPrizesProgressNode = class("QuestNewChapterStarPrizesProgressNode", util_require("base.BaseView"))

-- 1 三角箭头向上  2 三角箭头向下
function QuestNewChapterStarPrizesProgressNode:initDatas(data)
    self.m_type = data.type or 1
    self.m_starData = data.starData 
    self.m_chapterId = data.chapterId
end

function QuestNewChapterStarPrizesProgressNode:getCsbName()
    return QUESTNEW_RES_PATH.QuestNewChapterStarPrizesProgressNode 
end

function QuestNewChapterStarPrizesProgressNode:initCsbNodes()

    self.m_node_jiantoushang_shang = self:findChild("node_jiantoushang_shang") 
    self.m_lb_shuzi_1 = self:findChild("lb_shuzi_1") 

    self.m_node_jiantoushang_xia = self:findChild("node_jiantoushang_xia")
    self.m_lb_shuzi_2 = self:findChild("lb_shuzi_2") 
    self:initView()
end

function QuestNewChapterStarPrizesProgressNode:initView()
    self.m_lb_shuzi_1:setString(""..self.m_starData.p_stars)
    self.m_lb_shuzi_2:setString(""..self.m_starData.p_stars)
    self.m_node_jiantoushang_shang:setVisible(self.m_type == 1)
    self.m_node_jiantoushang_xia:setVisible(self.m_type == 2)
    if self.m_starData.p_collected then
        self:runCsbAction("wancheng",false)
    else
        self:runCsbAction("shuzi",false)
    end
end

function QuestNewChapterStarPrizesProgressNode:doCompleteAct(callBack)
    gLobalSoundManager:playSound(QUESTNEW_RES_PATH.QuestNew_Sound_StarMeterCollect)
    self:runCsbAction("dagou", false,function ()
        self:runCsbAction("wancheng",true)
        if callBack then
            callBack()
        end
    end)
end

return QuestNewChapterStarPrizesProgressNode
