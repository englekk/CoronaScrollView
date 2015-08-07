--##############################  Main Code Begin  ##############################--
local composer = require( "composer" )

local scene = composer.newScene()

-- "scene:create()"
function scene:create( event )
	local sceneGroup = self.view

	-- 여기서부터 시작
	system.activate("multitouch")

	local ScrollView = require("wonhada.controls.ScrollView")
	local sv = ScrollView.create(__appContentWidth__, __appContentHeight__)
	sv:addEventListener("touchDown", function (e) print("touchDown") end)
	sv:addEventListener("touchMove", function (e) print("touchMove") end)
	sv:addEventListener("released", function (e) print("released") end)
	sv:addEventListener("singleTap", function (e) print("singleTap") end)
	sv:addEventListener("doubleTap", function (e) print("doubleTap") end)
	local content = display.newGroup()
	display.newImage(content, "hbd.jpg", 0, 0)
	sv:setContent(content)
end

-- -------------------------------------------------------------------------------

-- Listener setup
scene:addEventListener( "create", scene )

-- -------------------------------------------------------------------------------

return scene
--##############################  Main Code End  ##############################--