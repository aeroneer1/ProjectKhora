-- This is a minimal Stingray sample.
-- It might behave incorrectly with some built in engine plugins, but it's a good starting point if you want total control.

-- An alternative to the aliases below is to have the following in the top of this file:
-- function import(ns) for k, v in next, ns do _G[k] = v end end
-- import(stingray)

local Application = stingray.Application
local World = stingray.World
local Level = stingray.Level
local Unit = stingray.Unit
local ShadingEnvironment = stingray.ShadingEnvironment
local Keyboard = stingray.Keyboard

Game = Game or {}

-- Called once when the engine starts.
function init()

	if LEVEL_EDITOR_TEST and not LEVEL_EDITOR_TEST_READY then
		print("Waiting for test level initialization...")
		return
	end

	Game.world = Application.new_world()
	Game.viewport = Application.create_viewport(Game.world, "default")
	Game.shading_environment = World.create_shading_environment(Game.world, "core/stingray_renderer/environments/midday/midday")
	Game.camera_unit = World.spawn_unit(Game.world, "core/units/camera")

	-- LEVEL_EDITOR_TEST is a global set if testing the game from within the editor.
	if LEVEL_EDITOR_TEST then
		init_editor_testing()
	else
		World.spawn_unit(Game.world, "core/editor_slave/units/skydome/skydome")
	end
end

-- Called once every frame.
function update(dt)

	if LEVEL_EDITOR_TEST and not LEVEL_EDITOR_TEST_READY then return end

	if LEVEL_EDITOR_TEST and should_stop_editor_testing() then
		stop_editor_testing()
		return
	end

	Game.world:update(dt)
end

-- Called once every frame.
function render()

	if LEVEL_EDITOR_TEST and not LEVEL_EDITOR_TEST_READY then return end

	ShadingEnvironment.blend(Game.shading_environment, {"default", 1})
	ShadingEnvironment.apply(Game.shading_environment)
	local camera = Unit.camera(Game.camera_unit, "camera")
	Application.render_world(Game.world, camera, Game.viewport, Game.shading_environment)
end

-- Called once when the engine quits.
function shutdown()

	if LEVEL_EDITOR_TEST and not LEVEL_EDITOR_TEST_READY then return end

	Application.destroy_viewport(Game.world, Game.viewport)
	World.destroy_shading_environment(Game.world, Game.shading_environment)
	Application.release_world(Game.world)
end

-- Called inside init when if testing the game from within the editor.
function init_editor_testing()
	-- Load the level currently active in the editor.
	local test_level_name = "__level_editor_test"
	Application.autoload_resource_package(test_level_name)
	local level = World.load_level(Game.world, test_level_name)
	Level.spawn_background(level)
	Level.trigger_level_loaded(level)

	if Level.has_data(level, "shading_environment") then
		World.set_shading_environment(Game.world, Game.shading_environment, Level.get_data(level, "shading_environment"))
	end

	-- Make the camera position and rotation match the one of the editor.
	if Application.has_data("LevelEditor", "camera", "position") then
		Unit.set_local_position(Game.camera_unit, 1, Application.get_data("LevelEditor", "camera", "position"))
	end

	if Application.has_data("LevelEditor", "camera", "rotation") then
		Unit.set_local_rotation(Game.camera_unit, 1, Application.get_data("LevelEditor", "camera", "rotation"))
	end

	Application.quit = stop_testing
end

-- Checks if esc or f10 is pressed, used every frame when in testing mode to see if we should quit testing.
function should_stop_editor_testing()
	local f10_pressed = Keyboard.pressed(Keyboard.button_index('f10'))
	local esc_pressed = Keyboard.pressed(Keyboard.button_index('esc'))
	return f10_pressed or esc_pressed
end

-- Notifies the editor that the testing session has ended.
function stop_editor_testing()
	Application.console_send { type = 'stop_testing' }
end
