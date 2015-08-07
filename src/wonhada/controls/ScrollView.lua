----------------------------------------
-- 이 주석은 삭제하지 마세요.
-- 35% 할인해 드립니다. 코로나 계정 유료 구매시 연락주세요. (Corona SDK, Enterprise, Cards)
-- @Author 아폴로케이션 원강민 대표
-- @Website http://WonHaDa.com, http://Apollocation.com, http://CoronaLabs.kr
-- @E-mail englekk@naver.com, englekk@apollocation.com
-- 'John 3:16, Psalm 23'
-- MIT License :: WonHada Library에 한정되며, 라이선스와 저작권 관련 명시만 지켜주면 되는 라이선스
-- 2015. 1. 15 (v1.0)
----------------------------------------

--[[
	-- @Example
	local ScrollView = require("wonhada.controls.ScrollView")
	local sv = ScrollView.create(320, 480)
	--sv:addEventListener("touchDown", function (e) print("touchDown") end)
	--sv:addEventListener("touchMove", function (e) print("touchMove") end)
	--sv:addEventListener("released", function (e) print("released") end)
	--sv:addEventListener("singleTap", function (e) print("singleTap") end)
	--sv:addEventListener("doubleTap", function (e) print("doubleTap") end)
	local content = display.newGroup()
	display.newImage(content, "baby.jpg", 0, 0)
	sv:setContent(content)
	-- @Description
	콘텐츠 내에서 드래그와 버튼을 함께 쓰려면 widget.newButton을 이용하세요.
	-- @Properties
	mouseEnabled: 드래그 및 확대/축소 여부
	outBounce: 끝 부분에서 바운딩 처리 여부
	horizontalScrollEnabled: 가로 이동 가능 여부
	verticalScrollEnabled: 세로 이동 가능 여부
	doubleClickZoomEnabled: 더블 클릭으로 줌 가능 여부
	multiTouchZoomEnabled: 멀티 터치로 줌 가능 여부
	forceMoveEnabled: 콘텐츠의 크기와 상관없이 움직일 수 있게 할지 여부
	content: 실제 움직이는 콘텐츠
	-- @Methods
	setContent(_content): 콘텐츠(DisplayObject) 설정
	removeContent(): 콘텐츠 삭제
	-- @Events
	touchDown
	touchMove
	released: touchDown 하고 잠깐 기다린 후 놓거나 touchMove 하다가 놓을 경우
	singleTap: 한번 탭
	doubleTap: 두번 탭
]]

local ScrollView = {}

ScrollView.create = function (_W, _H)
	-- 로컬 변수 정의
	local firstX, firstY, firstWidth, firstHeight, firstXScale, firstYScale, bg

	local minScale = nil -- 콘텐츠에 따라 0.6까지 줄어들게 바뀜
	local maxScale = 3.5

	-- 이미지를 감싸는 그룹 생성, 크기나 위치 변경 없음 (이벤트를 받아서 img 크기 조정)
	local group = display.newGroup( ) -- container
	group.anchorX, group.anchorY = 0, 0
	group.mouseEnabled = true
	group.outBounce = true
	group.horizontalScrollEnabled = true
	group.verticalScrollEnabled = true
	group.doubleClickZoomEnabled = true
	group.multiTouchZoomEnabled = true
	group.forceMoveEnabled = false
	group.content = nil -- 실제 콘텐츠

	---------------------------------------
	--
	-- Public Methods
	--
	---------------------------------------

	-- 콘텐츠(DisplayObject) 설정
	-- @param _content
	-- @param useAutoSizeAlignCenter 이미지 뷰어처럼 화면 사이즈에 맞게 가운데에 놓으려면 true
	-- @return
	function group:setContent(_content, useAutoSizeAlignCenter)
		if _content == nil then return end
		self:removeContent() -- 초기화

		_content.anchorX, _content.anchorY = 0, 0

		group.content = _content
		self:insert(group.content)

		if useAutoSizeAlignCenter == true then
			-- 콘텐츠의 가로가 더 긴가?
			local isWidthBigger = group.content.width > group.content.height

			local tw = isWidthBigger and _W or _H * group.content.width / group.content.height
			local th = isWidthBigger and _W * group.content.height / group.content.width or _H
			firstX = isWidthBigger and 0 or (bg.width * 0.5) - (tw * 0.5)
			firstY = isWidthBigger and (bg.height * 0.5) - (th * 0.5) or 0

			group.content.x, group.content.y, group.content.width, group.content.height = firstX, firstY, tw, th
		else
			firstX, firstY = 0, 0
			group.content.x, group.content.y = 0, 0
		end

		firstWidth, firstHeight = group.content.width, group.content.height
		firstXScale, firstYScale = group.content.xScale, group.content.yScale
		minScale = firstXScale * 0.6
	end

	-- 콘텐츠 삭제
	-- @return
	function group:removeContent()
		if group.content then group.content:removeSelf() end
		group.content = nil
	end

	---------------------------------------

	bg = display.newRect( group, 0, 0, _W, _H ) -- 터치를 위한 배경, 크기나 위치 변경 없음
	bg.anchorX, bg.anchorY = 0, 0
	bg:setFillColor(0, 0, 0, 0)

	---------------------------------------

	local function calculateDelta( previousTouches, event )
		local id,touch = next( previousTouches )
		if event.id == id then
			id,touch = next( previousTouches, id )
			assert( id ~= event.id )
		end

		local dx = touch.x - event.x
		local dy = touch.y - event.y
		return dx, dy
	end

	local function calculateCenter( previousTouches, event )
		local id,touch = next( previousTouches )
		if event.id == id then
			id,touch = next( previousTouches, id )
			assert( id ~= event.id )
		end

		local cx = math.floor( ( touch.x + event.x ) * 0.5 )
		local cy = math.floor( ( touch.y + event.y ) * 0.5 )
		return cx, cy
	end

	local cx, cy -- 핀치줌의 마지막 중간 위치

	---------------------------------------
	-- 그룹의 이벤트
	local function onTouch( event )
		if not group.mouseEnabled then return true end

		if group.content.previousDeltaX == nil then group.content.previousDeltaX = 0 end
		if group.content.previousDeltaY == nil then group.content.previousDeltaY = 0 end

		local phase = event.phase
		local eventTime = event.time
		local previousTouches = group.content.previousTouches

		if not group.content.xScaleStart then
			group.content.xScaleStart, group.content.yScaleStart = group.content.xScale, group.content.yScale
		end

		local numTotalTouches = 1
		if previousTouches then
			-- add in total from previousTouches, subtract one if event is already in the array
			numTotalTouches = numTotalTouches + group.content.numPreviousTouches
			if previousTouches[event.id] then
				numTotalTouches = numTotalTouches - 1
			end
		end

		local realWidth = group.content.width * group.content.xScale
		local realHeight = group.content.height * group.content.yScale

		if "began" == phase then
				group:dispatchEvent({name="touchDown", target=group.content})

				-- 콘텐츠의 크기가 전체화면보다 작으면 움직이지 않게 함
				if group.forceMoveEnabled == false then
					group.horizontalScrollEnabled = group.content.contentWidth > _W
					group.verticalScrollEnabled = group.content.contentHeight > _H
				end

				-- Very first "began" event
				if not group.content.isFocus then
						-- Subsequent touch events will target button even if they are outside the contentBounds of button
						display.getCurrentStage():setFocus( group.content )
						group.content.isFocus = true

						-- Store initial position
						group.content.x0 = event.x - group.content.x
						group.content.y0 = event.y - group.content.y

						previousTouches = {}
						group.content.previousTouches = previousTouches
						group.content.numPreviousTouches = 0
						group.content.firstTouch = event

				elseif group.multiTouchZoomEnabled == true and not group.content.distance then
					local dx,dy

					if previousTouches and numTotalTouches >= 2 then
						dx,dy = calculateDelta( previousTouches, event )
						cx,cy = calculateCenter( previousTouches, event )
					end

					-- initialize to distance between two touches
					if dx and dy then
						local d = math.sqrt( dx*dx + dy*dy )
						if d > 0 then
							group.content.distance = d
							group.content.xScaleOriginal = group.content.xScale
							group.content.yScaleOriginal = group.content.yScale

							group.content.x0 = cx - group.content.x
							group.content.y0 = cy - group.content.y
						end
					end

				end

				if not previousTouches[event.id] then
					group.content.numPreviousTouches = group.content.numPreviousTouches + 1
				end
				previousTouches[event.id] = event

		elseif group.content.isFocus then
			if "moved" == phase then
				if group.multiTouchZoomEnabled == true and group.content.distance then
					local dx,dy
					
					if previousTouches and numTotalTouches == 2 then
						dx,dy = calculateDelta( previousTouches, event )
						cx,cy = calculateCenter( previousTouches, event )
					end

					if dx and dy then
						local newDistance = math.sqrt( dx*dx + dy*dy )
						local scale = newDistance / group.content.distance

						if scale > 0 then
							local _scaleX = group.content.xScaleOriginal * scale

							if _scaleX > maxScale then
								_scaleX = maxScale
							elseif _scaleX < minScale then
								_scaleX = minScale
							end

							group.content.xScale = _scaleX
							group.content.yScale = _scaleX

							if _scaleX > minScale and _scaleX < maxScale then
								-- Make object move while scaling
								group.content.x = cx - ( group.content.x0 * scale )
								group.content.y = cy - ( group.content.y0 * scale )
							end
						end
					end
				else
					if event.id == group.content.firstTouch.id then
							-- don't move unless this is the first touch id.
							-- Make object move (we subtract img.x0, img.y0 so that moves are
							-- relative to initial grab point, rather than object "snapping").
							local _enableX = (realWidth > _W)
							local _enableY = (realHeight > _H)

							local tx = event.x - group.content.x0
							local ty = event.y - group.content.y0

							if not group.outBounce then -- 아웃바운스 안함
								if _enableX then
									if group.horizontalScrollEnabled then group.content.x = tx end
									if tx > 0 then
										_enableX = false
										if group.horizontalScrollEnabled then group.content.x = 0 end
									elseif tx + realWidth < _W then
										_enableX = false
										if group.horizontalScrollEnabled then group.content.x = _W - realWidth end
									end
								end
								if _enableY then
									if group.verticalScrollEnabled then group.content.y = ty end
									if ty > 0 then
										_enableY = false
										if group.verticalScrollEnabled then group.content.y = 0 end
									elseif ty + realHeight < _H then
										_enableY = false
										if group.verticalScrollEnabled then group.content.y = _H - realHeight end
									end
								end
							else -- 아웃바운스 함
								local dx = event.x - group.content.firstTouch.x
								local dy = event.y - group.content.firstTouch.y

								if tx > 0 or tx + realWidth < _W then dx = dx * 0.3 end
								if ty > 0 or ty + realHeight < _H then dy = dy * 0.3 end

								if group.horizontalScrollEnabled then group.content.x = group.content.x + dx end
								if group.verticalScrollEnabled then group.content.y = group.content.y + dy end
							end

							---------------------------------
							-- 이 부분은 여기에 둘 것
							group.content.previousDeltaX = event.x - group.content.firstTouch.x
							group.content.previousDeltaY = event.y - group.content.firstTouch.y
							group.content.previousEnableX = _enableX
							group.content.previousEnableY = _enableY
							---------------------------------
							group:dispatchEvent({name="touchMove", target=group.content, enableX=_enableX, enableY=_enableY, dx=group.content.previousDeltaX, dy=group.content.previousDeltaY})
					end
				end

				if event.id == group.content.firstTouch.id then
						group.content.firstTouch = event
				end

				if not previousTouches[event.id] then
						group.content.numPreviousTouches = group.content.numPreviousTouches + 1
				end
				previousTouches[event.id] = event

			elseif "ended" == phase or "cancelled" == phase then
				if group == nil or group.parent == nil then return end
				
				-- check for taps
				local dx = math.abs( event.xStart - event.x )
				local dy = math.abs( event.yStart - event.y )

				if eventTime - previousTouches[event.id].time < 150 and dx < 10 and dy < 10 then
					if not group.content.tapTime then
						-- single tap
						group.content.tapTime = eventTime
						group.content.tapDelay = timer.performWithDelay( 200, function()
							group.content.tapTime = nil

							group:dispatchEvent({name="singleTap", target=group.content})
							local _parent = group.parent
							while _parent do -- cancel이 안되는 bubbling
								_parent:dispatchEvent({name="singleTap", target=group.content})
								_parent = _parent.parent
							end
						end )
					elseif eventTime - group.content.tapTime < 200 then
						-- double tap
						group:dispatchEvent({name="doubleTap", target=group.content})
						if group.doubleClickZoomEnabled then
							timer.cancel( group.content.tapDelay )
							group.content.tapTime = nil
							if group.content.xScale == group.content.xScaleStart and group.content.yScale == group.content.yScaleStart then
								-- 커짐
								local tx = event.x - (group.content.x0 * maxScale)
								if event.x < group.content.x then -- 이미지 바깥 빈 영역 터치
									if realWidth * maxScale > _W then tx = 0
									else tx = (_W * 0.5) - (realWidth * maxScale * 0.5) end
								elseif event.x > group.content.x + group.content.width then
									if realWidth * maxScale > _W then tx = _W - (realWidth * maxScale)
									else tx = (_W * 0.5) - (realWidth * maxScale * 0.5) end
								end

								local ty = event.y - (group.content.y0 * maxScale)
								if event.y < group.content.y then -- 이미지 바깥 빈 영역 터치
									if realHeight * maxScale > _H then ty = 0
									else ty = (_H * 0.5) - (realHeight * maxScale * 0.5) end
								elseif event.y > group.content.y + group.content.height then
									if realHeight * maxScale > _H then ty = _H - (realHeight * maxScale)
									else ty = (_H * 0.5) - (realHeight * maxScale * 0.5) end
								end

								-- 이미지의 끝이 모서리보다 안쪽이면 모서리에 붙임
								if tx > 0 then tx = 0
								elseif tx < _W - (realWidth * maxScale) then tx = _W - (realWidth * maxScale) end

								if ty > 0 then ty = 0
								elseif ty < _H - (realHeight * maxScale) then ty = _H - (realHeight * maxScale) end

								transition.to( group.content, { time=300, transition=easing.outQuad, xScale=group.content.xScale*maxScale, yScale=group.content.yScale*maxScale, x=tx, y=ty } )
							else
								-- 원래대로 작아짐
								local tx = event.x - (group.content.x0 / maxScale)
								local ty = event.y - (group.content.y0 / maxScale)

								-- 이미지의 끝이 모서리보다 안쪽이면 모서리에 붙임
								if tx > 0 then tx = 0
								elseif tx < _W - (realWidth / maxScale) then tx = _W - (realWidth / maxScale) end

								if ty > 0 then ty = 0
								elseif ty < _H - (realHeight / maxScale) then ty = _H - (realHeight / maxScale) end

								transition.to( group.content, { time=300, transition=easing.outQuad, xScale=firstXScale, yScale=firstYScale, x=tx, y=ty } )
							end
						end
					end
				else
					-- Tap 하지 않고 드래그 하다가 놓았을 경우
					local tx = group.content.x + (group.content.previousDeltaX * 2)
					local ty = group.content.y + (group.content.previousDeltaY * 2)

					if tx > 0 then tx = 0
					elseif tx + realWidth < _W then tx = _W - realWidth end

					if ty > 0 then ty = 0
					elseif ty + realHeight < _H then ty = _H - realHeight end

					if group.content.x > 0 then
						tx = 0
					elseif group.content.x + realWidth < _W then
						tx = _W - realWidth
					end
					if realWidth < _W then tx = (_W * 0.5) - (realWidth * 0.5) end

					if group.content.y > 0 then
						ty = 0
					elseif group.content.y + realHeight < _H then
						ty = _H - realHeight
					end
					if realHeight < _H then ty = (_H * 0.5) - (realHeight * 0.5) end

					local tw, th = group.content.xScale, group.content.yScale
					if tw < firstXScale or th < firstYScale then -- 핀치줌 하다가 놓았는데 크기가 최소 크기보다 작으면
						-- TODO!! 여기가 잘 안되네요. 누가 수정하면 알려주세요~ :-)
						tw, th = firstXScale, firstYScale

						group.content.x0 = cx - group.content.x
						group.content.y0 = cy - group.content.y
						tx = cx - (group.content.x0 * firstXScale)
						ty = cy - (group.content.y0 * firstYScale)
						
						if group.content.x > 0 then tx = 0
						elseif group.content.x + realWidth < _W then
							tx = _W - firstWidth
						end

						if group.content.y > 0 then ty = 0
						elseif group.content.y + realHeight < _H then
							ty = _H - firstHeight
						end
					end

					transition.to( group.content, { time=200, transition=easing.outQuad, xScale = tw, yScale = th, x=tx, y=ty } )

					-- img.previousDeltaX, previousDeltaY, previousEnableX, previousEnableY
					group:dispatchEvent({name="released", target=group.content})
				end

				--
				if previousTouches[event.id] then
					group.content.numPreviousTouches = group.content.numPreviousTouches - 1
					previousTouches[event.id] = nil
				end

				if group.content.numPreviousTouches == 1 then
					-- must be at least 2 touches remaining to pinch/zoom
					group.content.distance = nil
					-- reset initial position
					local id,touch = next( previousTouches )
					group.content.x0 = touch.x - group.content.x
					group.content.y0 = touch.y - group.content.y
					group.content.firstTouch = touch

				elseif group.content.numPreviousTouches == 0 then
					-- previousTouches is empty so no more fingers are touching the screen
					-- Allow touch events to be sent normally to the objects they "hit"
					display.getCurrentStage():setFocus( nil )
					group.content.isFocus = false
					group.content.distance = nil
					group.content.xScaleOriginal = nil
					group.content.yScaleOriginal = nil

					-- reset array
					group.content.previousTouches = nil
					group.content.numPreviousTouches = nil
				end
			end
		end

		return true
	end

	group:addEventListener( "touch", onTouch )

	return group
end

return ScrollView