#pragma once
#include "Graphics/RenderStage.h"

class Texture;

class RayMarchStage : public RenderStage
{
public:
	RayMarchStage();

	void Update(float deltaTime);
	void RecordStage(ComPtr<ID3D12GraphicsCommandList4> commandList) override;

private:
	void InitializeResources();
	void InitializePipeline();

private:
	float elapsedTime;

	Texture* backBuffer;
};