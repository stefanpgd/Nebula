#pragma once

#define WIN32_LEAN_AND_MEAN 
#include <Windows.h>

#include <string>

// TODO: Consider adding "Time" to the framework
// a class that has a way to retrieve deltaTime AND program run time. This way we don't need
// to pass deltaTime to everything

class Renderer;
class Editor;

class Application
{
public:
	Application();

	void Run();

private:
	void RegisterWindowClass();

	void Start();
	void Update(float deltaTime);
	void Render();

	static LRESULT CALLBACK WindowsCallback(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam);

private:
	std::wstring applicationName = L"Nebula";
	bool runApplication = true;

	unsigned int windowWidth = 1080;
	unsigned int windowHeight = 720;

	// Systems //
	Renderer* renderer;
	Editor* editor;
};