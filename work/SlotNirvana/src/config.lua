-- 0 - disable debug info, 1 - less debug info, 2 - verbose debug info -- FIX IOS 139
DEBUG = 2             --正式改成 0  测试服改为2

if DEBUG == 2 then
    --测试服常用配置
    --是否可以直接购买
    CC_IS_TEST_BUY = true
    --服务器是否使用正式服配置
    CC_IS_RELEASE_NETWORK = false
    --adjustfirebase打点日志是否发送标签
    CC_IS_PLATFORM_SENDLOG = false
    -- 大厅关卡图标上显示关卡名字
    CC_SHOW_LEVELNAME_IN_LOBBY = true 
else
    --正式服常用配置
    --是否可以直接购买
    CC_IS_TEST_BUY = false          --正式改成 false
    --服务器是否使用正式服配置
    CC_IS_RELEASE_NETWORK = true    --正式改成 true
    --adjustfirebase打点日志是否发送标签
    CC_IS_PLATFORM_SENDLOG = true
    -- 大厅关卡图标上显示关卡名字
    CC_SHOW_LEVELNAME_IN_LOBBY = false  
end
--下载方案:0.最老的下载版本 1.cocos2dx版本 2.最老的下载版本-修改解压部分 3.多线程版本
CC_DOWNLOAD_TYPE = 1                --默认值使用兼容所有版本的 3多线程版本 
--不常用配置
-- use framework, will disable all deprecated API, false - use legacy API
CC_USE_FRAMEWORK = true             --正式改成 true
-- show FPS on screen
CC_SHOW_FPS = false                 --正式改成 false
-- disable create unexpected global variable
CC_DISABLE_GLOBAL = false           --正式改成 false
-- is read machine from download path
CC_IS_READ_DOWNLOAD_PATH = true     --正式改成 true
-- quest read path  , true is download path ， false 用在开发环境
CC_IS_READ_WRITEPATH_QUEST = true   --正式改成 true
-- 正式购买流程，绕过sdk(需要跟后端沟通，配置特定账号，与CC_IS_TEST_BUY开关互斥，上线配置为false
CC_IS_OUT_SDK_BUY = false           --正式改成 false
-- 集卡功能开关控制
CC_CAN_ENTER_CARD_COLLECTION = true --正式改成 true


-- 自动下载，是否开启
CC_DYNAMIC_DOWNLOAD = true          --正式改成 true
-- 全局配置，是否开启
CC_GAMEGLOBAL_CONFIG = true         --正式改成 true
--是否跳过新手引导
CC_SKIP_NOVICEGUIDE = false         --正式改成 false
--是否使用abtest
CC_ABTEST_ENABLE = true             --正式改成 true
--关卡是否使用SRC下的CODE
CC_LEVEL_SRC_CODE_ENABLE = true     --正式改成 true
-- Ratio
CC_RESOLUTION_RATIO = 1
--新手期打印
CC_NEWS_PERIOD_SHOW = false         --正式改成 false
-- 跳过热跟新， 直接进入游
CC_NETWORK_TEST = false             --正式改成 false
--mac横竖屏切换  
CC_IS_PORTRAIT_MODE = false         --正式改成 false


CC_SHOW_BINGO_GUIDE = true         --正式改成 true
-- 邮箱中的facebook是否用测试数据
CC_INBOX_FB_TEST = false            --正式改成 false

-- ATT开启控制
CC_ATTRACKING_FLAG  = true          --默认14.5之后默认开启
CC_ATTRACKING_LIMIT_VERSION = 145   --开启att的系统版本号 14.5

-- for module display
CC_DESIGN_RESOLUTION = {
    width = 1370,
    height = 768,
    autoscale = "FIXED_HEIGHT",
    callback = function(framesize)
        local ratio = framesize.width / framesize.height
        if ratio <= 1.34 then
            CC_RESOLUTION_RATIO = 2
            -- iPad 768*1024(1536*2048) is 4:3 screen
            -- return {autoscale = "FIXED_WIDTH"}
        elseif ratio>=1.78 then
            CC_RESOLUTION_RATIO = 3
            -- return {autoscale = "SHOW_ALL"}
        end
    end
}

if CC_IS_PORTRAIT_MODE then
    CC_DESIGN_RESOLUTION = {
        width = 768,
        height = 1370,
        autoscale = "FIXED_WIDTH",
        callback = function(framesize)
            local ratio = framesize.width / framesize.height
            if ratio <= 1.34 then
                CC_RESOLUTION_RATIO = 2
                -- iPad 768*1024(1536*2048) is 4:3 screen
                -- return {autoscale = "FIXED_WIDTH"}
            elseif ratio>=1.78 then
                CC_RESOLUTION_RATIO = 3
                -- return {autoscale = "SHOW_ALL"}
            end
        end
    }
end
