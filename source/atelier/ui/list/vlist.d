/**
    Vertical list

    Copyright: (c) Enalye 2017
    License: Zlib
    Authors: Enalye
*/

module atelier.ui.list.vlist;

import std.conv: to;

import atelier.core;
import atelier.render;
import atelier.common;

import atelier.ui;

private class ListContainer: GuiElementCanvas {
	public {
		VContainer container;
	}

	this(Vec2f newSize) {
		isLocked = true;
		container = new VContainer;
		size(newSize);
		addChildGui(container);
	}
}

/// Vertical list of elements with a slider.
class VList: GuiElement {
	protected {
		ListContainer _container;
		Slider _slider;
		Vec2f _lastMousePos = Vec2f.zero;
		float _layoutLength = 25f;
		int _nbElements;
		int _idElementSelected;
	}

	@property {
		int selected() const { return _idElementSelected; }
		int selected(int id) {
			if(id >= _nbElements)
				id = _nbElements - 1;
            if(id < 0)
                id = 0;
			_idElementSelected = id;

            //Update children
            auto widgets = _container.container.children;
            foreach(GuiElement gui; _container.container.children)
                gui.isSelected = false;
            if(_idElementSelected < widgets.length)
                widgets[_idElementSelected].isSelected = true;
			return _idElementSelected;
		}

		float layoutLength() const { return _layoutLength; }
		float layoutLength(float length) {
			_layoutLength = length;
			_container.container.size = Vec2f(_container.size.x, _layoutLength * _nbElements);
			return _layoutLength;
		}
	}

	this(Vec2f newSize) {
		isLocked = true;
		_slider = new VScrollbar;
        _slider.setAlign(GuiAlignX.left, GuiAlignY.center);
		_container = new ListContainer(newSize);
        _container.setAlign(GuiAlignX.right, GuiAlignY.top);
        _container.container.setAlign(GuiAlignX.right, GuiAlignY.top);

		super.addChildGui(_slider);
		super.addChildGui(_container);

		size(newSize);
		position(Vec2f.zero);

        setEventHook(true);
        
		_container.container.size = Vec2f(_container.size.x, 0f);
	}

    override void onCallback(string id) {
        if(id != "list")
            return;
        auto widgets = _container.container.children;
        foreach(size_t elementId, ref GuiElement gui; _container.container.children) {
            gui.isSelected = false;
            if(gui.isHovered)
                _idElementSelected = cast(uint)elementId;
        }
        if(_idElementSelected < widgets.length)
            widgets[_idElementSelected].isSelected = true;
    }

    override void onEvent(Event event) {
        if(event.type == EventType.mouseWheel)
            _slider.onEvent(event);
    }
    
    override void onSize() {
        _slider.size = Vec2f(10f, _size.y);
        _container.container.size = Vec2f(_container.size.x, _layoutLength * _nbElements);
        _container.size = Vec2f(size.x - _slider.size.x, size.y);
        _container.canvas.renderSize = _container.size.to!Vec2u;
    }

	override void update(float deltaTime) {
		super.update(deltaTime);
		float min = 0f;
		float max = _container.container.size.y - _container.size.y;
		float exceedingHeight = _container.container.size.y - _container.canvas.size.y;

		if(exceedingHeight < 0f) {
			_slider.max = 0;
			_slider.step = 0;
		}
		else {
			_slider.max = exceedingHeight / _layoutLength;
			_slider.step = to!uint(_slider.max);
		}
		_container.canvas.position = _container.canvas.size / 2f + Vec2f(0f, lerp(min, max, _slider.offset));
	}

	override void addChildGui(GuiElement gui) {
        gui.position = Vec2f.zero;
        gui.setAlign(GuiAlignX.right, GuiAlignY.top);
		gui.isSelected = (_nbElements == 0u);
        gui.setCallback(this, "list");

		_nbElements ++;
		_container.container.size = Vec2f(_container.size.x, _layoutLength * _nbElements);
		_container.container.position = Vec2f.zero;
		_container.container.addChildGui(gui);
	}

	override void removeChildrenGuis() {
		_nbElements = 0u;
		_idElementSelected = 0u;
		_container.container.size = Vec2f(_container.size.x, 0f);
		_container.container.position = Vec2f.zero;
		_container.container.removeChildrenGuis();
	}

	override void removeChildGui(uint id) {
		_container.container.removeChildGui(id);
		_nbElements = _container.container.getChildrenGuisCount();
		_idElementSelected = 0u;
		_container.container.size = Vec2f(_container.size.x, _layoutLength * _nbElements);
		_container.container.position = Vec2f(0f, _container.container.size.y / 2f);
	}

	override int getChildrenGuisCount() {
		return _container.container.getChildrenGuisCount();	
	}

	GuiElement[] getList() {
		return _container.container.children;
	}
}